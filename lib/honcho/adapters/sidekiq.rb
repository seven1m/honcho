module Honcho
  module Adapters
    class Sidekiq < Base
      def queued_count
        queues = redis.keys("#{namespace}:queue:*")
        counts = queues.map { |q| redis.llen(q) }
        counts.inject(&:+) || 0
      end

      def busy_count
        processes = redis.smembers("#{namespace}:processes")
        counts = processes.map do |process|
          redis.hget("#{namespace}:#{process}", 'busy').to_i
        end
        counts.inject(&:+) || 0
      end

      def namespace
        config.fetch('namespace')
      end
    end
  end
end
