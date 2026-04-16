require "application_system_test_case"

class LiveQueueTest < ApplicationSystemTestCase
  def setup
    @workshop = workshops(:one)
    @queue = service_queues(:open_queue)
    @driver = users(:driver_no_workshops)
    @operator = users(:one) # workshop owner
  end

  test "driver sees called status without reload when operator calls them" do
    # Create a queue entry for the driver
    entry = QueueEntry.create!(
      service_queue: @queue,
      user: @driver,
      position: @queue.next_position,
      joined_at: Time.current
    )

    # Driver signs in and views their queue entry
    using_session(:driver) do
      sign_in_user(@driver)

      visit queue_entry_path(entry)
      assert_selector "[data-testid]", count: 0 # no called banner yet
      assert_text I18n.t("queue_entries.statuses.waiting")
    end

    # Operator signs in and calls the driver
    using_session(:operator) do
      sign_in_user(@operator)

      visit workshop_management_workshop_queue_path(@workshop, @queue)
      within("##{ActionView::RecordIdentifier.dom_id(entry, :operator)}") do
        click_button I18n.t("workshop_management.queues.show.call")
      end
    end

    # Driver sees the update without refreshing
    using_session(:driver) do
      assert_selector "[data-testid='called-banner']", wait: 5
      assert_text I18n.t("queue_entries.show.you_are_up")
    end
  end
end
