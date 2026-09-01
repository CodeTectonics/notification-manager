module NotificationManager
  module NotificationManagers
    class Base
      attr_accessor :notifiable

      def initialize(notifiable)
        @notifiable = notifiable
      end

      def run_notification_flow
        notification_steps.each do |step|
          next unless step.triggered?(@notifiable)

          step.clear_notifications(@notifiable)
          step.send_notifications(self, @notifiable)
        end
      end

      def notification_steps
        raise "Implement in subclass"
      end
    end
  end
end
