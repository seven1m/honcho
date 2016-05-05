class Honcho
  module Adapters
    class Base
      def initialize(config:, redis:)
        @redis = redis
        @config = config
      end

      attr_reader :config, :redis

      def run?
        work_to_do? || work_being_done?
      end

      private

      def work_to_do?
        fail NotImplementedError, "please define #{this.class.name}##{__method__}"
      end

      def work_being_done?
        fail NotImplementedError, "please define #{this.class.name}##{__method__}"
      end
    end
  end
end
