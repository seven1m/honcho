module Honcho
  module Adapters
    class Resque < Base
      def queued_count
        queues = redis.smembers("#{namespace}:queues")
        counts = queues.map { |q| redis.llen("#{namespace}:queue:#{q}") }
        counts.inject(&:+) || 0
      end

      def busy_count
        # No way to tell via redis if work is being done in resque? Booo.
        0
      end

      def namespace
        config.fetch('namespace')
      end
    end
  end
end
