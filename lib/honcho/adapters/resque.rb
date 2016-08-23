module Honcho
  module Adapters
    class Resque < Base
      private

      def work_to_do?
        queues = redis.smembers("#{namespace}:queues")
        counts = queues.map { |q| redis.llen("#{namespace}:queue:#{q}") }
        counts.any?(&:nonzero?)
      end

      def work_being_done?
        # No way to tell via redis if work is being done in resque? Booo.
        false
      end

      def namespace
        config.fetch('namespace')
      end
    end
  end
end
