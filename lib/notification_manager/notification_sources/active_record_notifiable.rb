module NotificationManager
  module NotificationSources
    module ActiveRecordNotifiable
      extend ActiveSupport::Concern

      included do
        attr_accessor :skip_notifications

        after_commit :send_notifications

        def send_notifications
          return if skip_notifications
          return if notification_manager_class_name.nil?

          notification_manager = notification_manager_class_name.constantize.new(self)
          notification_manager.run_notification_flow
        end

        def notification_manager_class_name
          "#{self.class.name}NotificationManager"
        end
      end
    end
  end
end
