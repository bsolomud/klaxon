require "application_system_test_case"

class QueueFlowTest < ApplicationSystemTestCase
  def setup
    @workshop = workshops(:one)
    @driver = users(:driver_no_workshops)
    @operator = users(:one)

    # Clear existing queues for workshop :one so the empty state renders.
    # `dependent: :destroy` on queue_entries handles the cascade.
    @workshop.service_queues.today.destroy_all
  end

  test "full queue flow: operator opens, driver joins, operator calls/serves/completes" do
    # Operator signs in and opens a queue from the empty state
    using_session(:operator) do
      sign_in_user(@operator)

      visit workshop_management_workshop_queues_path(@workshop)
      click_button I18n.t("workshop_management.queues.index.open_queue")
      assert_text I18n.t("workshop_management.queues.open.success")
    end

    # Find the queue created by the operator
    queue = @workshop.service_queues.today.open.last
    assert queue.present?, "Queue should have been created"

    # Driver signs in and joins the queue from the workshop show page
    using_session(:driver) do
      sign_in_user(@driver)

      visit workshop_path(@workshop)
      click_button I18n.t("workshops.show.join_queue")
      assert_text I18n.t("queue_entries.show.title")
      assert_text I18n.t("queue_entries.statuses.waiting")
    end

    # Find the queue entry
    entry = queue.queue_entries.find_by!(user: @driver)
    assert entry.waiting?

    # Operator calls the driver
    using_session(:operator) do
      visit workshop_management_workshop_queue_path(@workshop, queue)
      click_button I18n.t("workshop_management.queues.show.call")
      assert_text I18n.t("workshop_management.queue_entries.call.success")
    end

    # Driver sees "Called" status update via Turbo Streams (live)
    using_session(:driver) do
      assert_selector "[data-testid='called-banner']", wait: 5
      assert_text I18n.t("queue_entries.show.you_are_up")
    end

    # Operator serves the driver
    using_session(:operator) do
      visit workshop_management_workshop_queue_path(@workshop, queue)
      click_button I18n.t("workshop_management.queues.show.serve")
      assert_text I18n.t("workshop_management.queue_entries.serve.success")
    end

    # Operator completes the service
    using_session(:operator) do
      visit workshop_management_workshop_queue_path(@workshop, queue)
      click_button I18n.t("workshop_management.queues.show.complete")
      assert_text I18n.t("workshop_management.queue_entries.complete.success")
    end

    # Verify final state
    entry.reload
    assert entry.completed?, "Queue entry should be completed"
  end
end
