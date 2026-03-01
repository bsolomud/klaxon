require "rails_helper"

RSpec.describe ServiceCategory, type: :model do
  describe "validations" do
    subject { build(:service_category) }

    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "requires name" do
      subject.name = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:name]).to include("can't be blank")
    end

    it "requires slug" do
      subject.slug = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:slug]).to include("can't be blank")
    end

    it "requires unique slug" do
      create(:service_category, slug: "sto")
      subject.slug = "sto"
      expect(subject).not_to be_valid
      expect(subject.errors[:slug]).to include("has already been taken")
    end
  end

  describe "associations" do
    it "has many workshops" do
      category = create(:service_category)
      workshop = create(:workshop, service_category: category)
      expect(category.workshops).to include(workshop)
    end

    it "restricts deletion when workshops exist" do
      category = create(:service_category)
      create(:workshop, service_category: category)
      expect { category.destroy! }.to raise_error(ActiveRecord::DeleteRestrictionError)
    end

    it "allows deletion when no workshops exist" do
      category = create(:service_category)
      expect { category.destroy! }.not_to raise_error
    end
  end
end
