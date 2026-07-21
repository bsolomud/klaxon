# Generates a workshop's bookable appointment slots for a given day from its
# working hours and the service's duration. Idempotent: safe to call repeatedly.
class SlotAvailability
  DEFAULT_DURATION_MINUTES = 60

  def initialize(workshop, workshop_service_category, date)
    @workshop = workshop
    @wsc = workshop_service_category
    @date = date
  end

  def generate!
    hours = @workshop.working_hours.find_by(day_of_week: @date.wday)
    return AppointmentSlot.none if hours.nil? || hours.closed?

    duration = (@wsc.estimated_duration_minutes || DEFAULT_DURATION_MINUTES).minutes
    slot_start = combine(hours.opens_at)
    closes_at = combine(hours.closes_at)

    while slot_start + duration <= closes_at
      slot_end = slot_start + duration
      create_slot(slot_start, slot_end) if slot_start.future?
      slot_start = slot_end
    end

    slots_for_day
  end

  def slots_for_day
    @wsc.appointment_slots.for_day(@date).chronological
  end

  private

  def create_slot(slot_start, slot_end)
    AppointmentSlot.find_or_create_by!(workshop_service_category: @wsc, starts_at: slot_start) do |slot|
      slot.workshop = @workshop
      slot.ends_at = slot_end
      slot.capacity = 1
    end
  end

  def combine(time)
    Time.zone.local(@date.year, @date.month, @date.day, time.hour, time.min)
  end
end
