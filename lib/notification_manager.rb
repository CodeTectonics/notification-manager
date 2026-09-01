# frozen_string_literal: true

require_relative "notification_manager/version"
require_relative "notification_manager/notification_definitions/base"
require_relative "notification_manager/notification_managers/base"
require_relative "notification_manager/notification_sources/active_record_notifiable"

module NotificationManager
  class Error < StandardError; end
end
