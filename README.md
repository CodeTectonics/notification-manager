# NotificationManager

A flexible notification management system for Rails applications that automatically triggers notifications based on ActiveRecord model lifecycle events and attribute changes.

## Features

- 🔔 Trigger notifications on model lifecycle events (create, update, destroy)
- 🎯 Trigger notifications based on attribute status changes
- 🏷️ Tag-based notification clearing to prevent duplicate notifications
- 👥 Support for multiple recipients per notification
- 🔄 Polymorphic notification system supporting any notifiable model
- ⏭️ Conditional notification skipping
- 🎨 Extensible architecture with customizable notification managers

## Requirements

- Ruby >= 3.2.0
- Rails >= 6.1

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'notification_manager'
```

And then execute:

```bash
$ bundle install
```

## Usage

### 1. Generate the Notification Model

First, generate the notification model and migration:

```bash
$ rails generate notification_manager:notifications
$ rails db:migrate
```

This creates:
- `app/models/notification.rb` - The Notification model
- `db/migrate/[timestamp]_create_notifications.rb` - The database migration

The notifications table includes:
- `user_id` - Reference to the user receiving the notification
- `notifiable` - Polymorphic reference to any notifiable model
- `description` - Notification message
- `link` - Optional link for the notification
- `tag` - Tag for grouping/clearing related notifications
- `opened` - Boolean flag to track read/unread status

### 2. Include the Notifiable Concern

Add the `ActiveRecordNotifiable` concern to any model you want to send notifications from:

```ruby
class Order < ApplicationRecord
  include NotificationManager::NotificationSources::ActiveRecordNotifiable
  
  # Your model code...
end
```

This adds an `after_commit` callback that automatically triggers notifications based on your notification manager configuration.

### 3. Create a Notification Manager

Create a notification manager class for your notifiable model. The class name should follow the pattern `[ModelName]NotificationManager`:

```ruby
# app/notification_managers/order_notification_manager.rb
class OrderNotificationManager < NotificationManager::NotificationManagers::Base
  def notification_steps
    [
      order_created_notification,
      order_shipped_notification,
      order_delivered_notification
    ]
  end

  private

  def order_created_notification
    NotificationManager::NotificationDefinitions::Base.new(
      lifecycle_triggers: [:created],
      status_triggers: [],
      notification_tags_to_clear: [],
      notifications_to_send: [
        {
          recipients: :seller_recipient,
          notification: :send_order_created_notification
        }
      ]
    )
  end

  def order_shipped_notification
    NotificationManager::NotificationDefinitions::Base.new(
      lifecycle_triggers: [:updated],
      status_triggers: [
        {
          attr: :status,
          triggers: -> { ['shipped'] }
        }
      ],
      notification_tags_to_clear: ['order_pending'],
      notifications_to_send: [
        {
          recipients: :buyer_recipient,
          notification: :send_order_shipped_notification
        }
      ]
    )
  end

  def order_delivered_notification
    NotificationManager::NotificationDefinitions::Base.new(
      lifecycle_triggers: [:updated],
      status_triggers: [
        {
          attr: :status,
          triggers: -> { ['delivered'] }
        }
      ],
      notification_tags_to_clear: ['order_shipped'],
      notifications_to_send: [
        {
          recipients: :buyer_recipient,
          notification: :send_order_delivered_notification
        }
      ]
    )
  end

  # Recipient methods return arrays of users
  def seller_recipient
    [notifiable.seller]
  end

  def buyer_recipient
    [notifiable.buyer]
  end

  # Notification sender methods
  def send_order_created_notification(order, recipient)
    Notification.create!(
      user: recipient,
      notifiable: order,
      description: "New order ##{order.id} received",
      link: "/orders/#{order.id}",
      tag: 'order_created'
    )
  end

  def send_order_shipped_notification(order, recipient)
    Notification.create!(
      user: recipient,
      notifiable: order,
      description: "Your order ##{order.id} has been shipped",
      link: "/orders/#{order.id}",
      tag: 'order_shipped'
    )
  end

  def send_order_delivered_notification(order, recipient)
    Notification.create!(
      user: recipient,
      notifiable: order,
      description: "Your order ##{order.id} has been delivered",
      link: "/orders/#{order.id}",
      tag: 'order_delivered'
    )
  end
end
```

### 4. Notification Definition Options

Each notification definition accepts the following options:

#### `lifecycle_triggers` (Array)
Specifies which lifecycle events should trigger the notification:
- `:created` - Triggers when the record is created
- `:updated` - Triggers when the record is updated
- `:destroyed` - Triggers when the record is destroyed

#### `status_triggers` (Array of Hashes)
Defines attribute-based conditions for triggering notifications:
```ruby
status_triggers: [
  {
    attr: :status,           # The attribute to watch
    triggers: -> { ['value'] }  # Lambda returning array of trigger values
  }
]
```

Use `-> { '*' }` to trigger on any change to the attribute.

#### `notification_tags_to_clear` (Array)
Array of notification tags to clear before sending new notifications. This prevents duplicate or outdated notifications:
```ruby
notification_tags_to_clear: ['order_pending', 'order_processing']
```

#### `notifications_to_send` (Array of Hashes)
Defines which notifications to send:
```ruby
notifications_to_send: [
  {
    recipients: :method_name,      # Method that returns array of users
    notification: :method_name     # Method that creates the notification
  }
]
```

### 5. Skipping Notifications

You can temporarily skip notifications for a specific operation:

```ruby
order = Order.new(...)
order.skip_notifications = true
order.save
```

## Advanced Examples

### Multiple Recipients

```ruby
def admin_recipients
  User.where(role: 'admin').to_a
end

def stakeholder_recipients
  [notifiable.owner, notifiable.manager].compact
end
```

### Conditional Status Triggers

```ruby
status_triggers: [
  {
    attr: :priority,
    triggers: -> { ['high', 'critical'] }
  },
  {
    attr: :assigned_to_id,
    triggers: -> { '*' }  # Trigger on any assignment change
  }
]
```

### Chaining Notifications

Clear previous notifications when sending new ones to maintain a clean notification state:

```ruby
NotificationManager::NotificationDefinitions::Base.new(
  lifecycle_triggers: [:updated],
  status_triggers: [{ attr: :status, triggers: -> { ['completed'] } }],
  notification_tags_to_clear: ['task_pending', 'task_in_progress'],
  notifications_to_send: [
    { recipients: :task_owner, notification: :send_completion_notification }
  ]
)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/CodeTectonics/notification-manager. This project is intended to be a safe, welcoming space for collaboration.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).
