require "rails/generators"
require "rails/generators/named_base"
require "rails/generators/migration"

module NotificationManager
  module Generators
    class NotificationsGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      desc "Creates the Notification model and miration for use with Notification Managers."

      def create_models
        template "notification_model.rb", "app/models/notification.rb"
      end

      def create_migrations
        migration_template "create_notifications.rb",
                           "db/migrate/create_notifications.rb"
      end

      def self.next_migration_number(dirname)
        if ActiveRecord::Base.timestamped_migrations
          @@migration_number ||= Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
          @@migration_number += 1
          @@migration_number.to_s
        else
          format("%03d", current_migration_number(dirname) + 1)
        end
      end
    end
  end
end
