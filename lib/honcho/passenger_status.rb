module Honcho
  class PassengerStatus
    def initialize
      @raw = `passenger-status`
    rescue
      raise 'could not execute passenger-status'
    end

    def data
      return [] if @raw =~ /not serving any applications/
      apps = @raw.split(/\-+ Application groups \-+/).last
      apps.split(/\n\n/).map do |raw_app|
        next unless (root_match = raw_app.match(/App root: (.+)/))
        data = {
          'root' => root_match[1]
        }
        data['name'] = data['root'].split('/').last
        data['workers'] = raw_app.scan(/\* PID.*\n.*/).map do |worker|
          worker.scan(/([\w ]+?) *: ([\d%MGKhms]+)/).each_with_object({}) do |(key, val), hash|
            hash[key.strip] = val.strip
          end
        end
        data
      end.compact.sort_by { |a| a['name'] }
    end
  end
end
