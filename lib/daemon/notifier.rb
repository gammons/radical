Dir[File.dirname(__FILE__) + "/notifiers/*.rb"].each { |file| require file }
module Radical
  class Notifier
    def self.create(type, options = {})
      case type
      when :twilio
        Radical::Notifiers::Twilio.new(options)
      else
        raise "Unknown sms provider"
      end
    end
  end
end
