FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@aulabs.io" }
    password { "password123" }
    password_confirmation { "password123" }
    confirmed_at { Time.current }

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :locked do
      locked_at { Time.current }
      failed_attempts { 20 }
    end

    trait :with_profile do
      first_name { "Іван" }
      last_name { "Шевченко" }
      phone_number { "+380501234567" }
    end
  end
end
