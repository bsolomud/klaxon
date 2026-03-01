FactoryBot.define do
  factory :service_category do
    sequence(:name) { |n| "Category #{n}" }
    sequence(:slug) { |n| "category_#{n}" }
  end
end
