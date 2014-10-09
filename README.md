# capistrano-runit-puma

Capistrano3 tasks for manage puma via runit supervisor.

## Installation

Add this line to your application's Gemfile:

    gem 'capistrano-runit-puma'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capistrano-runit-puma

## Usage

Add this line in `Capfile`:
```
require 'capistrano/runit/puma'
```

## Tasks

* `runit:puma:setup` -- setup puma runit service.
* `runit:puma:enable` -- enable and autostart service.
* `runit:puma:disable` -- stop and disable service.
* `runit:puma:start` -- start service.
* `runit:puma:stop` -- stop service.
* `runit:puma:restart` -- restart service.
* `runit:puma:phased_restart` -- run phased restart.
* `runit:puma:force_restart` -- run forced restart.

## Variables

* `runit_puma_role` -- what host roles uses runit to run puma. Default value: `:app`
* `runit_puma_default_hooks` -- run default hooks for runit puma or not. Default value: `true`.
* `runit_puma_run_template` -- path to ERB template of `run` file. Default value: `nil`.
* `runit_puma_workers` -- number of puma workers. Default value: 1.
* `runit_puma_threads_min` -- minimal threads to use. Default value: 0.
* `runit_puma_threads_max` -- maximal threads to use. Default value: 16.
* `runit_puma_bind` -- bind URI. Examples: tcp://127.0.0.1:8080, unix:///tmp/puma.sock. Default value: nil.
* `runit_puma_rackup` -- Path to application's rackup file. Default value: `File.join(current_path, 'config.ru')`
* `runit_puma_state`  -- Path to puma's state file. Default value: `File.join(shared_path, 'tmp', 'pids', 'puma.state')`
* `runit_puma_pid` -- Path to pid file. Default value: `File.join(shared_path, 'tmp', 'pids', 'puma.pid')`
* `runit_puma_conf` -- Path to puma's config file. Default value: `File.join(shared_path, 'puma.rb')`
* `runit_puma_log` -- path to puma's log (stdout/stderr combined). Default value: `File.join(shared_path, 'log', 'puma.log')`
* `runit_puma_init_active_record` -- Enable or not establish ActiveRecord connection. Default value: `false`
* `runit_puma_preload_app` -- Preload application. Default value: `true`
* `runit_puma_restart_method` -- One of following methods: :restart (default), :force_restart, :phased_restart.

## Contributing

1. Fork it ( https://github.com/capistrano-runit/capistrano-runit-puma/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
