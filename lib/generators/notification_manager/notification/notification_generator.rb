require "rails/generators"
require "rails/generators/named_base"
require "rails/generators/migration"

module AnalyticsPlane
  module Generators
    class NotificationGenerator < Rails::Generators::NamedBase
      include Rails::Generators::Migration

      source_root File.expand_path("../templates", __dir__)

      desc "Creates a Notification model and migration for NotificationManager"

      def create_model
        template "notification_model.rb", "app/models/#{file_name}.rb"
      end

      def create_notification_migration
        migration_template(
          "create_notifications.rb",
          "db/migrate/create_#{file_name.pluralize}.rb"
        )
      end

      def self.next_migration_number(dirname)
        if @next_migration_number
          @next_migration_number += 1
        else
          @next_migration_number = Time.now.utc.strftime("%Y%m%d%H%M%S")
        end
      end
    end
  end
end
