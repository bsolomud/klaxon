FactoryBot.define do
  factory :working_hour do
    workshop
    day_of_week { 1 }
    opens_at { "08:00" }
    closes_at { "18:00" }
    closed { false }

    trait :closed_day do
      opens_at { nil }
      closes_at { nil }
      closed { true }
    end

    trait :overnight do
      opens_at { "22:00" }
      closes_at { "06:00" }
      closed { false }
    end
  end
end
