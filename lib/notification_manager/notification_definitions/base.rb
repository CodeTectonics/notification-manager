module NotificationManager
  module NotificationDefinitions
    class Base
      attr_accessor :lifecycle_triggers, :status_triggers, :notification_tags_to_clear,
                    :notifications_to_send

      def initialize(options)
        @lifecycle_triggers = options[:lifecycle_triggers] || []
        @status_triggers = options[:status_triggers]
        @notification_tags_to_clear = options[:notification_tags_to_clear] || []
        @notifications_to_send = options[:notifications_to_send] || []
      end

      def triggered?(notifiable)
        lifecycle_event_reached?(notifiable) && status_reached?(notifiable)
      end

      def lifecycle_event_reached?(notifiable)
        if notifiable.created_at_previously_changed?
          lifecycle_triggers.include?(:created)
        elsif notifiable.updated_at_previously_changed?
          lifecycle_triggers.include?(:updated)
        elsif notifiable.destroyed?
          lifecycle_triggers.include?(:destroyed)
        end
      end

      def status_reached?(notifiable)
        return true if status_triggers.empty?

        status_triggers.each do |event|
          next unless notifiable.send("#{event[:attr]}_previously_changed?")

          triggers = event[:triggers].yield

          return true if triggers == '*'

          return true if notifiable[event[:attr]].in?(triggers)
        end

        false
      end

      def clear_notifications(notifiable)
        return if notification_tags_to_clear.empty?

        Notification.where(
          notifiable_id: notifiable.id,
          notifiable_type: notifiable.class.name,
          tag: notification_tags_to_clear
        ).destroy_all
      end

      def send_notifications(notification_manager, notifiable)
        notifications_to_send.each do |notification|
          recipients = notification_manager.send(notification[:recipients])
          recipients.compact.each do |recipient|
            notification_manager.send(notification[:notification], notifiable, recipient)
          end
        end
      end
    end
  end
end
