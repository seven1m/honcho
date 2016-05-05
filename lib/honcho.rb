#!/usr/bin/env ruby

require 'redis'
require 'sys/proctable'
require 'time'
require 'stringio'
require 'yaml'
require_relative './honcho/adapters'

Thread.abort_on_exception = true

class Honcho
  COLORS = {
    red:            31,
    green:          32,
    yellow:         33,
    blue:           34,
    magenta:        35,
    cyan:           36,
    bright_black:   30,
    bright_red:     31,
    bright_green:   32,
    bright_yellow:  33,
    bright_blue:    34,
    bright_magenta: 35,
    bright_cyan:    36,
    bright_white:   37
  }.freeze

  def initialize
    @running = {}
    @stopping = {}
    @redis = Redis.new
    @adapters = build_adapters
    @colors = assign_colors
  end

  attr_reader :adapters, :running, :stopping, :redis, :colors

  def run
    trap(:INT)  { term_all && exit }
    trap(:TERM) { term_all && exit }
    loop do
      check_for_work
      sleep(interval)
    end
  end

  private

  def apps
    config['apps']
  end

  def command_template
    config['command_template'] || '%s'
  end

  def stop_delay
    config['stop_delay'] || 30
  end

  def interval
    config['interval'] || 2
  end

  def config
    @config ||= YAML.load_file('honcho.yml')
  end

  def check_for_work
    adapters.each do |adapter|
      if adapter.run?
        start(adapter)
      else
        stop(adapter)
      end
    end
  end

  def start(adapter)
    stopping.delete(adapter)
    return if running[adapter]
    log(adapter.config['name'], "STARTING\n")
    running[adapter] = start_command(adapter)
  end

  def start_command(adapter)
    command = adapter.config['command']
    Array(command).map do |cmd|
      rout, wout = IO.pipe
      pid = spawn(adapter.config['path'], cmd, wout)
      Thread.new do
        log(adapter.config['name'], rout.gets) until rout.eof?
      end
      [pid, wout]
    end
  end

  def spawn(path, cmd, out)
    Process.spawn(
      "cd '#{path}' && " + command_template % cmd,
      pgroup: true,
      err: out,
      out: out
    )
  end

  def stop(adapter)
    return unless running[adapter]
    if should_stop?(adapter)
      really_stop(adapter)
    else
      stopping[adapter] ||= stop_delay
      stopping[adapter] -= interval
    end
  end

  def should_stop?(adapter)
    stopping[adapter] && stopping[adapter] <= 0
  end

  def really_stop(adapter)
    log(adapter.config['name'], "STOPPING\n")
    stopping.delete(adapter)
    return unless running[adapter]
    running[adapter].each do |(pid, wout)|
      Process.kill('-TERM', pid)
      wout.close
    end
    running.delete(adapter)
  end

  def term_all
    running.values.flatten.each do |(pid)|
      Process.kill('-TERM', pid)
    end
  end

  def log(name, message)
    color = colors[name]
    $stdout.write("\e[#{color}m#{name.rjust(label_width)}:\e[0m #{message}")
  end

  def label_width
    @label_width ||= apps.keys.map(&:size).max
  end

  def assign_colors
    color_values = COLORS.values
    apps.keys.each_with_object({}) do |app, hash|
      hash[app] = color_values.shift
    end
  end

  def build_adapters
    apps.flat_map do |app, config|
      config.map do |type, worker_config|
        adapter = adapter_from_type(type)
        next if adapter.nil?
        adapter.new(
          config: worker_config.merge('name' => app, 'path' => config['path']),
          redis: redis
        )
      end
    end.compact
  end

  def adapter_from_type(type)
    case type
    when 'sidekiq'
      Adapters::Sidekiq
    when 'resque'
      Adapters::Resque
    when 'path'
      nil
    else
      fail "Unknown type #{type}"
    end
  end
end
