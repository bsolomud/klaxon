FactoryBot.define do
  factory :workshop do
    sequence(:name) { |n| "Workshop #{n}" }
    phone { "+380441234567" }
    address { "123 Main Street" }
    city { "Kyiv" }
    country { "Ukraine" }
    active { true }
    service_category

    trait :inactive do
      active { false }
    end

    trait :with_working_hours do
      after(:create) do |workshop|
        (0..6).each do |day|
          create(:working_hour, workshop: workshop, day_of_week: day)
        end
      end
    end

    trait :with_description do
      description { "A full-service automotive workshop with certified technicians." }
    end

    trait :with_email do
      sequence(:email) { |n| "workshop#{n}@example.com" }
    end

    trait :with_coordinates do
      latitude { 50.4501 }
      longitude { 30.5234 }
    end
  end
end
