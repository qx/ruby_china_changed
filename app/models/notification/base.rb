module Notification
  class Base < ApplicationRecord
    include BaseModel

    self.table_name = 'notifications'

    belongs_to :user

    scope :unread, -> { where(read: false) }

    after_create :realtime_push_to_client
    after_update :realtime_push_to_client

    def realtime_push_to_client
      if user
        self.class.realtime_push_to_client(user)

        PushJob.perform_later(user_id, apns_note)
      end
    end

    def self.realtime_push_to_client(user)
      ActionCable.server.broadcast "notifications_count/#{user.id}", { count: user.notifications.unread.count }
    end

    def content_path
      ''
    end

    def apns_note
      @note ||= { alert: notify_hash[:title], badge: user.notifications.unread.count }
    end

    def actor
      nil
    end

    def anchor
      "notification-#{id}"
    end
  end
end
