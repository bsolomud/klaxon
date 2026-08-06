module TimeRangeable
  extend ActiveSupport::Concern

  class_methods do
    def time_within_range?(time, opens, closes)
      if opens <= closes
        time >= opens && time <= closes
      else
        time >= opens || time <= closes
      end
    end
  end
end
