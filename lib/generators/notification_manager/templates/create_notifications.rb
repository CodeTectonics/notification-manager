class CreateNotifications < ActiveRecord::Migration[7.0]
  def change
    create_table :notifications do |t|
      t.references :user, foreign_key: true
      t.references :notifiable, polymorphic: true
      t.string :description
      t.string :link
      t.string :tag
      t.boolean :opened, default: false, null: false

      t.timestamps
    end
  end
end
