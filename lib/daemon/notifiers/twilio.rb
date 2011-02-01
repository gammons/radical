module Radical
  module Notifiers
    class Twilio
      attr_reader :opts

      def initialize(opts)
        @opts = opts
      end

      def connect
        p "connecting"
      end

      def notify
        p "sending sms"
      end
    end
  end
end
