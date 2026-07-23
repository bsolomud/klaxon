require "test_helper"

class ServiceReminderJobTest < ActiveJob::TestCase
  setup do
    # Isolate: start with no records due.
    ServiceRecord.update_all(next_service_at_date: nil, reminder_sent_at: nil) # rubocop:disable Rails/SkipsModelValidations
    @record = service_records(:completed_record)
  end

  test "notifies the car owner for a record due today and marks it reminded" do
    @record.update_columns(next_service_at_date: Date.current) # rubocop:disable Rails/SkipsModelValidations
    assert_difference "Notification.count", 1 do
      ServiceReminderJob.new.perform
    end
    notification = Notification.recent.first
    assert_equal "service_due_reminder", notification.event
    assert_equal @record.car.user, notification.user
    assert @record.reload.reminder_sent_at.present?
  end

  test "reminds overdue records too" do
    @record.update_columns(next_service_at_date: 3.days.ago.to_date) # rubocop:disable Rails/SkipsModelValidations
    assert_difference "Notification.count", 1 do
      ServiceReminderJob.new.perform
    end
  end

  test "does not remind twice" do
    @record.update_columns(next_service_at_date: Date.current) # rubocop:disable Rails/SkipsModelValidations
    ServiceReminderJob.new.perform
    assert_no_difference "Notification.count" do
      ServiceReminderJob.new.perform
    end
  end

  test "ignores records with no next service date and future dates" do
    @record.update_columns(next_service_at_date: 1.month.from_now.to_date) # rubocop:disable Rails/SkipsModelValidations
    assert_no_difference "Notification.count" do
      ServiceReminderJob.new.perform
    end
  end
end
