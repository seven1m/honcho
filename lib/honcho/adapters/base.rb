module Honcho
  module Adapters
    class Base
      def initialize(config:, redis:, runner:)
        @config = config
        @redis = redis
        @runner = runner
        @running = false
        @stopping = false
      end

      attr_reader :config, :redis, :runner, :running, :stopping

      def type
        self.class.name.split(':').last.downcase
      end

      def check_for_work
        if run?
          start
        else
          stop
        end
      end

      def name
        config['name']
      end

      def commands
        Array(config['command'])
      end

      def path
        config['path']
      end

      def run?
        work_to_do? || work_being_done?
      end

      def running?
        @running != false
      end

      def stopping?
        @stopping != false
      end

      def start
        @stopping = false
        return if running?
        log(name, "STARTING\n")
        @running = start_command
      end

      def start_command
        commands.map do |cmd|
          rout, wout = IO.pipe
          pid = spawn(path, cmd, wout)
          Thread.new do
            log(name, rout.gets) until rout.eof?
          end
          [pid, wout]
        end
      end

      def stop
        return unless running?
        if should_stop?
          really_stop
        else
          @stopping ||= stop_delay
          @stopping -= interval
        end
      end

      def should_stop?
        stopping? && stopping <= 0
      end

      def really_stop
        @stopping = false
        return unless running?
        log(name, "STOPPING\n")
        running.each do |(pid, wout)|
          Process.kill('-TERM', pid)
          wout.close
        end
        @running = false
      end

      def total_count
        queued_count + busy_count
      end

      private

      def log(*args)
        runner.log(*args)
      end

      def spawn(*args)
        runner.spawn(*args)
      end

      def stop_delay
        runner.stop_delay
      end

      def interval
        runner.interval
      end

      def work_to_do?
        queued_count > 0
      end

      def work_being_done?
        busy_count > 0
      end
    end
  end
end
