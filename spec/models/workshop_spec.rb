require "rails_helper"

RSpec.describe Workshop, type: :model do
  describe "validations" do
    subject { build(:workshop) }

    it "is valid with valid attributes" do
      expect(subject).to be_valid
    end

    it "requires name" do
      subject.name = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:name]).to include("can't be blank")
    end

    it "requires phone" do
      subject.phone = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:phone]).to include("can't be blank")
    end

    it "requires address" do
      subject.address = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:address]).to include("can't be blank")
    end

    it "requires city" do
      subject.city = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:city]).to include("can't be blank")
    end

    it "requires country" do
      subject.country = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:country]).to include("can't be blank")
    end

    it "requires service_category" do
      subject.service_category = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:service_category]).to include("can't be blank")
    end
  end

  describe "associations" do
    it "belongs to service_category" do
      category = create(:service_category)
      workshop = create(:workshop, service_category: category)
      expect(workshop.service_category).to eq(category)
    end

    it "has many working_hours" do
      workshop = create(:workshop)
      wh = create(:working_hour, workshop: workshop, day_of_week: 1)
      expect(workshop.working_hours).to include(wh)
    end

    it "destroys working_hours when destroyed" do
      workshop = create(:workshop, :with_working_hours)
      expect { workshop.destroy! }.to change(WorkingHour, :count).by(-7)
    end

    it "accepts nested attributes for working_hours" do
      workshop = build(:workshop)
      workshop.working_hours_attributes = [
        { day_of_week: 1, opens_at: "08:00", closes_at: "18:00", closed: false }
      ]
      workshop.save!
      expect(workshop.working_hours.count).to eq(1)
    end
  end

  describe "scopes" do
    describe ".active" do
      it "returns only active workshops" do
        active = create(:workshop, active: true)
        create(:workshop, :inactive)
        expect(Workshop.active).to eq([active])
      end
    end

    describe ".by_city" do
      it "filters by city" do
        kyiv = create(:workshop, city: "Kyiv")
        create(:workshop, city: "Lviv")
        expect(Workshop.by_city("Kyiv")).to eq([kyiv])
      end
    end

    describe ".by_country" do
      it "filters by country" do
        ua = create(:workshop, country: "Ukraine")
        create(:workshop, country: "Poland")
        expect(Workshop.by_country("Ukraine")).to eq([ua])
      end
    end

    describe ".by_category_slug" do
      it "filters by category slug" do
        sto = create(:service_category, slug: "sto")
        wash = create(:service_category, slug: "car_wash")
        w1 = create(:workshop, service_category: sto)
        create(:workshop, service_category: wash)
        expect(Workshop.by_category_slug("sto")).to eq([w1])
      end
    end

    describe ".open_now" do
      it "returns workshops open at the current time (normal hours)" do
        workshop = create(:workshop)
        now = Time.current
        create(:working_hour,
               workshop: workshop,
               day_of_week: now.wday,
               opens_at: (now - 1.hour).strftime("%H:%M"),
               closes_at: (now + 1.hour).strftime("%H:%M"),
               closed: false)

        expect(Workshop.open_now).to include(workshop)
      end

      it "excludes workshops that are closed today" do
        workshop = create(:workshop)
        now = Time.current
        create(:working_hour, :closed_day, workshop: workshop, day_of_week: now.wday)

        expect(Workshop.open_now).not_to include(workshop)
      end

      it "excludes workshops outside operating hours" do
        workshop = create(:workshop)
        now = Time.current
        create(:working_hour,
               workshop: workshop,
               day_of_week: now.wday,
               opens_at: (now + 2.hours).strftime("%H:%M"),
               closes_at: (now + 4.hours).strftime("%H:%M"),
               closed: false)

        expect(Workshop.open_now).not_to include(workshop)
      end

      it "handles overnight hours (opens_at > closes_at)" do
        workshop = create(:workshop)
        now = Time.current

        # Create overnight hours: from 2 hours ago to 2 hours from now, crossing midnight
        # We simulate this by setting opens_at in the "evening" and closes_at in the "morning"
        travel_to Time.zone.local(2026, 3, 1, 23, 30) do
          create(:working_hour,
                 workshop: workshop,
                 day_of_week: Time.current.wday,
                 opens_at: "22:00",
                 closes_at: "06:00",
                 closed: false)

          expect(Workshop.open_now).to include(workshop)
        end
      end

      it "handles overnight hours early morning side" do
        workshop = create(:workshop)

        travel_to Time.zone.local(2026, 3, 2, 3, 0) do
          create(:working_hour,
                 workshop: workshop,
                 day_of_week: Time.current.wday,
                 opens_at: "22:00",
                 closes_at: "06:00",
                 closed: false)

          expect(Workshop.open_now).to include(workshop)
        end
      end
    end
  end

  describe "#open_now?" do
    it "returns true when within normal operating hours" do
      workshop = create(:workshop)
      now = Time.current
      create(:working_hour,
             workshop: workshop,
             day_of_week: now.wday,
             opens_at: (now - 1.hour).strftime("%H:%M"),
             closes_at: (now + 1.hour).strftime("%H:%M"),
             closed: false)

      expect(workshop.open_now?).to be true
    end

    it "returns false when outside operating hours" do
      workshop = create(:workshop)
      now = Time.current
      create(:working_hour,
             workshop: workshop,
             day_of_week: now.wday,
             opens_at: (now + 2.hours).strftime("%H:%M"),
             closes_at: (now + 4.hours).strftime("%H:%M"),
             closed: false)

      expect(workshop.open_now?).to be false
    end

    it "returns false when closed" do
      workshop = create(:workshop)
      create(:working_hour, :closed_day, workshop: workshop, day_of_week: Time.current.wday)

      expect(workshop.open_now?).to be false
    end

    it "returns false when no working hours for today" do
      workshop = create(:workshop)
      expect(workshop.open_now?).to be false
    end

    it "handles overnight hours" do
      workshop = create(:workshop)

      travel_to Time.zone.local(2026, 3, 1, 23, 30) do
        create(:working_hour,
               workshop: workshop,
               day_of_week: Time.current.wday,
               opens_at: "22:00",
               closes_at: "06:00",
               closed: false)

        expect(workshop.open_now?).to be true
      end
    end
  end

  describe "#today_working_hours" do
    it "returns working hours for current day" do
      workshop = create(:workshop)
      wh = create(:working_hour, workshop: workshop, day_of_week: Time.current.wday)

      expect(workshop.today_working_hours).to eq(wh)
    end

    it "returns nil when no hours set for today" do
      workshop = create(:workshop)
      expect(workshop.today_working_hours).to be_nil
    end
  end
end
