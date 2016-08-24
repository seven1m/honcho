require 'redis'
require 'time'
require 'stringio'
require 'yaml'
require_relative './adapters'
require_relative './colors'

Thread.abort_on_exception = true

module Honcho
  class Runner
    include Colors

    def initialize(options)
      @config_file_path = options[:config]
      @root_path = File.expand_path('..', @config_file_path)
      @running = {}
      @stopping = {}
      @redis = Redis.new
      @adapters_by_app = build_adapters
      @adapters = @adapters_by_app.values.flatten
      @colors = assign_colors_for_ansi
    end

    attr_reader :config_file_path, :root_path, :adapters_by_app, :adapters, :running, :stopping, :redis, :colors

    def run
      trap(:INT)  { term_all && exit }
      trap(:TERM) { term_all && exit }
      loop do
        check_for_work
        sleep(interval)
      end
    end

    def log(name, message)
      color = colors[name]
      $stdout.write("\e[#{color}m#{name.rjust(label_width)}:\e[0m #{message}")
    end

    def spawn(path, cmd, out)
      Process.spawn(
        "cd '#{root_path}/#{path}' && " + command_template % cmd,
        pgroup: true,
        err: out,
        out: out
      )
    end

    def interval
      config['interval'] || 2
    end

    def stop_delay
      config['stop_delay'] || 30
    end

    private

    def apps
      config['apps']
    end

    def command_template
      config['command_template'] || '%s'
    end

    def config
      @config ||= YAML.load_file(config_file_path)
    end

    def check_for_work
      adapters.each(&:check_for_work)
    end

    def term_all
      adapters.each(&:really_stop)
    end

    def label_width
      @label_width ||= apps.keys.map(&:size).max
    end

    def build_adapters
      apps.each_with_object({}) do |(app, config), hash|
        hash[app] = config.map do |type, worker_config|
          build_adapter(app, config, type, worker_config)
        end.compact
      end
    end

    def build_adapter(app, config, type, worker_config)
      adapter = Adapters.from_type(type)
      return if adapter.nil?
      adapter.new(
        config: worker_config.merge('name' => app, 'path' => config['path']),
        redis: redis,
        runner: self
      )
    end
  end
end
