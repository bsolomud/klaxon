module Normalizable
  extend ActiveSupport::Concern

  class_methods do
    def normalizes_upcase(*attributes)
      attributes.each do |attr|
        before_validation do
          value = send(attr)
          send(:"#{attr}=", value.upcase.strip) if value.present?
        end
      end
    end
  end
end
