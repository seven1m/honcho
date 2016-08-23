require_relative './adapters/base'
require_relative './adapters/resque'
require_relative './adapters/sidekiq'

module Honcho
  module Adapters
    module_function

    def from_type(type)
      case type
      when 'sidekiq'
        Adapters::Sidekiq
      when 'resque'
        Adapters::Resque
      when 'path' # special config key that gets ignored
        nil
      else
        raise "Unknown type #{type}"
      end
    end
  end
end
