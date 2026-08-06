require "application_system_test_case"

class QueueFlowTest < ApplicationSystemTestCase
  def setup
    @workshop = workshops(:one)
    @driver = users(:driver_no_workshops)
    @operator = users(:one)
    @tire = service_categories(:tire_service)
    @diagnostics = service_categories(:diagnostics)

    # Start from a clean slate so the operator opens queues from scratch.
    @workshop.service_queues.today.destroy_all
  end

  test "operator opens a per-service queue, driver picks it and joins, operator serves and completes" do
    using_session(:operator) do
      sign_in_user(@operator)

      visit workshop_management_workshop_queues_path(@workshop)
      within "##{ActionView::RecordIdentifier.dom_id(@tire)}" do
        click_button I18n.t("workshop_management.queues.index.open_queue")
      end
      assert_text I18n.t("workshop_management.queues.open.success")
    end

    queue = @workshop.service_queues.today.open.find_by(service_category: @tire)
    assert queue.present?, "Queue should have been created for the tire service"

    using_session(:driver) do
      sign_in_user(@driver)

      visit workshop_path(@workshop)
      click_button I18n.t("workshops.show.join_queue") # opens the modal
      within "dialog" do
        # First queue radio is pre-checked; confirm.
        click_button I18n.t("workshops.show.join_queue")
      end
      assert_text I18n.t("queue_entries.show.title")
      assert_text I18n.t("queue_entries.statuses.waiting")
    end

    entry = queue.queue_entries.find_by!(user: @driver)
    assert entry.waiting?

    using_session(:operator) do
      visit workshop_management_workshop_queue_path(@workshop, queue)
      click_button I18n.t("workshop_management.queues.show.call")
      assert_text I18n.t("workshop_management.queue_entries.call.success")
    end

    using_session(:driver) do
      assert_selector "[data-testid='called-banner']", wait: 5
      assert_text I18n.t("queue_entries.show.you_are_up")
    end

    using_session(:operator) do
      visit workshop_management_workshop_queue_path(@workshop, queue)
      click_button I18n.t("workshop_management.queues.show.serve")
      assert_text I18n.t("workshop_management.queue_entries.serve.success")

      visit workshop_management_workshop_queue_path(@workshop, queue)
      click_button I18n.t("workshop_management.queues.show.complete")
      assert_text I18n.t("workshop_management.queue_entries.complete.success")
    end

    entry.reload
    assert entry.completed?, "Queue entry should be completed"
  end

  test "driver leaves one queue and can then join a different one" do
    tire_queue = @workshop.service_queues.create!(
      service_category: @tire, date: Date.current, status: :open
    )
    diag_queue = @workshop.service_queues.create!(
      service_category: @diagnostics, date: Date.current, status: :open
    )

    sign_in_user(@driver)

    # Join the tire queue via the modal.
    visit workshop_path(@workshop)
    click_button I18n.t("workshops.show.join_queue")
    within "dialog" do
      find("input[name='queue_id'][value='#{tire_queue.id}']").click
      click_button I18n.t("workshops.show.join_queue")
    end
    assert_text I18n.t("queue_entries.show.title")

    # Returning to the workshop now shows the already-in-queue banner (no button).
    visit workshop_path(@workshop)
    assert_text I18n.t("workshops.show.already_in_queue", workshop: @workshop.name)
    assert_no_button I18n.t("workshops.show.join_queue")

    # Leave from the position page.
    entry = tire_queue.queue_entries.find_by!(user: @driver)
    visit queue_entry_path(entry)
    accept_confirm do
      click_button I18n.t("queue_entries.show.leave")
    end
    assert_current_path workshop_path(@workshop)

    # Now the driver can join the diagnostics queue.
    click_button I18n.t("workshops.show.join_queue")
    within "dialog" do
      find("input[name='queue_id'][value='#{diag_queue.id}']").click
      click_button I18n.t("workshops.show.join_queue")
    end
    assert_text I18n.t("queue_entries.show.title")
    assert diag_queue.queue_entries.exists?(user: @driver)
  end
end
