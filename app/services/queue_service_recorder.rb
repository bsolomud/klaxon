# Turns a completed queue visit into a car-history entry so walk-in queue
# services land in the digital passport and become reviewable. No-op when the
# visit can't be attributed (no car, or the queue has no service category).
class QueueServiceRecorder
  def initialize(queue_entry)
    @entry = queue_entry
  end

  def call
    return if @entry.service_request_id.present?

    car = @entry.car
    queue = @entry.service_queue
    category = queue.service_category
    return unless car && category

    wsc = queue.workshop.workshop_service_categories.find_by(service_category: category)
    return unless wsc

    ServiceRequest.transaction do
      request = ServiceRequest.create!(
        car: car,
        workshop: wsc.workshop,
        workshop_service_category: wsc,
        preferred_time: @entry.joined_at,
        description: I18n.t("queue_entries.service_description"),
        status: :completed
      )
      request.create_service_record!(
        summary: I18n.t("queue_entries.service_summary", category: category.name),
        completed_at: Time.current
      )
      @entry.update_column(:service_request_id, request.id) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
