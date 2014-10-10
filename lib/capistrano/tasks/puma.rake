require 'capistrano/runit'
include ::Capistrano::Runit

namespace :load do
  task :defaults do
    set :runit_puma_role, -> { :app }
    set :runit_puma_default_hooks, -> { true }
    set :runit_puma_workers, 0
    set :runit_puma_threads_min, 0
    set :runit_puma_threads_max, 16
    set :runit_puma_rackup, -> { File.join(current_path, 'config.ru') }
    set :runit_puma_state, -> { File.join(shared_path, 'tmp', 'pids', 'puma.state') }
    set :runit_puma_pid, -> { File.join(shared_path, 'tmp', 'pids', 'puma.pid') }
    set :runit_puma_bind, -> { File.join('unix://', shared_path, 'tmp', 'sockets', 'puma.sock') }
    set :runit_puma_conf, -> { File.join(shared_path, 'puma.rb') }
    set :runit_puma_conf_in_repo, -> { false }
    set :runit_puma_log, -> { File.join(shared_path, 'log', 'puma.log') }
    set :runit_puma_init_active_record, false
    set :runit_puma_preload_app, false
    set :runit_puma_restart_method, :restart
    set :runit_puma_on_worker_boot, nil
    # Rbenv and RVM integration
    set :rbenv_map_bins, fetch(:rbenv_map_bins).to_a.concat(%w(puma))
    set :rvm_map_bins, fetch(:rvm_map_bins).to_a.concat(%w(puma))
  end
end

namespace :deploy do
  before :starting, :runit_check_puma_hooks do
    invoke 'runit:puma:add_default_hooks' if fetch(:runit_puma_default_hooks)
  end
end

namespace :runit do
  namespace :puma do

    def puma_enabled_service_dir
      enabled_service_dir_for('puma')
    end

    def puma_service_dir
      service_dir_for('puma')
    end

    def collect_puma_run_command
      array = []
      array << env_variables
      array << "exec #{SSHKit.config.command_map[:bundle]} exec puma"
      puma_conf_path = if fetch(:runit_puma_conf_in_repo)
                         "#{release_path}/config/puma.rb"
                       else
                         fetch(:runit_puma_conf)
                       end
      array << "-C #{puma_conf_path}"
      array.compact.join(' ')
    end

    def create_puma_default_conf(host)
      info 'Create or overwrite puma.rb'
      # requirements
      if host.fetch(:runit_puma_bind).nil? && fetch(:runit_puma_bind).nil?
        $stderr.puts "You should set 'runit_puma_bind' variable globally or for host #{host.hostname}."
        exit 1
      end
      path = File.expand_path('../../templates/puma.rb.erb', __FILE__)
      if File.file?(path)
        template = ERB.new(File.read(path))
        stream   = StringIO.new(template.result(binding))
        upload! stream, "#{fetch(:runit_puma_conf)}"
        info 'puma.rb generated'
      end
    end

    task :add_default_hooks do
      after 'deploy:check', 'runit:puma:check'
      case fetch(:runit_puma_restart_method)
      when :restart
        after 'deploy:published', 'runit:puma:restart'
      when :force_restart
        after 'deploy:published', 'runit:puma:force_restart'
      when :phased_restart
        after 'deploy:published', 'runit:puma:phased_restart'
      else
        $stderr.puts 'Unknown restart method in runit_puma_restart_method variable. Allowed methods: :restart, :force_restart, :phased_restart.'
        exit 1
      end
    end

    task :check do
      check_service('puma')
      on roles fetch(:runit_puma_role) do |host|
        if test "[ -d #{puma_enabled_service_dir} ]"
          # Create puma.rb for new deployments if not in repo
          if !fetch(:runit_puma_conf_in_repo)
            create_puma_default_conf(host)
          end
        else
          error "Puma runit service isn't enabled."
        end
      end
    end

    desc 'Setup puma runit service'
    task :setup do
      setup_service('puma', collect_puma_run_command)
    end

    desc 'Enable puma runit service'
    task :enable do
      enable_service('puma')
    end

    desc 'Disable puma runit service'
    task :disable do
      disable_service('puma')
    end

    desc 'Start puma runit service'
    task :start do
      start_service('puma')
    end

    desc 'Stop puma runit service'
    task :stop do
      stop_service('puma')
    end

    desc 'Restart puma runit service'
    task :restart do
      on roles fetch(:runit_puma_role) do
        if test "[ -d #{puma_enabled_service_dir} ]"
          if test("[ -f #{fetch(:runit_puma_pid)} ]") && test("kill -0 $( cat #{fetch(:runit_puma_pid)} )")
            runit_execute_command('puma', '2')
          else
            info 'Puma is not running'
            if test("[ -f #{fetch(:runit_puma_pid)} ]")
              info 'Removing broken pid file'
              execute :rm, '-f', fetch(:runit_puma_pid)
            end
            runit_execute_command('puma', 'start')
          end
        else
          error "Puma runit service isn't enabled."
        end
      end
    end

    desc 'Force restart puma runit service'
    task :force_restart do
      restart_service('puma')
    end

    desc 'Run phased restart puma runit service'
    task :phased_restart do
      kill_hup_service('puma')
    end
  end
end
