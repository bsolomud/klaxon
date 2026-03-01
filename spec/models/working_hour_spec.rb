require "rails_helper"

RSpec.describe WorkingHour, type: :model do
  describe "validations" do
    subject { build(:working_hour) }

    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "requires day_of_week in 0..6" do
      subject.day_of_week = 7
      expect(subject).not_to be_valid
    end

    it "requires opens_at when not closed" do
      subject.closed = false
      subject.opens_at = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:opens_at]).to include("can't be blank")
    end

    it "requires closes_at when not closed" do
      subject.closed = false
      subject.closes_at = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:closes_at]).to include("can't be blank")
    end

    it "does not require opens_at when closed" do
      subject.closed = true
      subject.opens_at = nil
      subject.closes_at = nil
      expect(subject).to be_valid
    end

    it "does not require closes_at when closed" do
      subject.closed = true
      subject.opens_at = nil
      subject.closes_at = nil
      expect(subject).to be_valid
    end

    it "enforces unique day_of_week per workshop" do
      workshop = create(:workshop)
      create(:working_hour, workshop: workshop, day_of_week: 1)
      duplicate = build(:working_hour, workshop: workshop, day_of_week: 1)
      expect(duplicate).not_to be_valid
    end
  end

  describe "associations" do
    it "belongs to workshop" do
      wh = create(:working_hour)
      expect(wh.workshop).to be_a(Workshop)
    end
  end
end
