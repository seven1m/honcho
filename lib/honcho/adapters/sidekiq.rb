class Honcho
  module Adapters
    class Sidekiq < Base
      private

      def work_to_do?
        queues = redis.keys("#{namespace}:queue:*")
        counts = queues.map { |q| redis.llen(q) }
        counts.any?(&:nonzero?)
      end

      def work_being_done?
        processes = redis.smembers("#{namespace}:processes")
        counts = processes.map do |process|
          redis.hget("#{namespace}:#{process}", 'busy').to_i
        end
        counts.any?(&:nonzero?)
      end

      def namespace
        config.fetch('namespace')
      end
    end
  end
end
