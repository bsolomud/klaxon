require "rails_helper"

RSpec.describe "Workshops", type: :request do
  let(:user) { create(:user) }
  let(:category) { create(:service_category) }
  let(:valid_attrs) do
    {
      name: "AutoPro",
      phone: "+380441234567",
      address: "123 Main St",
      city: "Kyiv",
      country: "Ukraine",
      service_category_id: category.id,
      active: true
    }
  end

  describe "public access" do
    describe "GET /workshops" do
      it "returns success without authentication" do
        get workshops_path
        expect(response).to have_http_status(:success)
      end

      it "lists active workshops" do
        create(:workshop, name: "Active Shop", active: true)
        create(:workshop, name: "Inactive Shop", active: false)
        get workshops_path
        expect(response.body).to include("Active Shop")
        expect(response.body).not_to include("Inactive Shop")
      end

      it "filters by city" do
        create(:workshop, name: "Kyiv Shop", city: "Kyiv")
        create(:workshop, name: "Lviv Shop", city: "Lviv")
        get workshops_path, params: { city: "Kyiv" }
        expect(response.body).to include("Kyiv Shop")
        expect(response.body).not_to include("Lviv Shop")
      end

      it "filters by country" do
        create(:workshop, name: "UA Shop", country: "Ukraine")
        create(:workshop, name: "PL Shop", country: "Poland")
        get workshops_path, params: { country: "Ukraine" }
        expect(response.body).to include("UA Shop")
        expect(response.body).not_to include("PL Shop")
      end

      it "filters by category slug" do
        sto = create(:service_category, slug: "sto")
        wash = create(:service_category, slug: "car_wash")
        create(:workshop, name: "STO Shop", service_category: sto)
        create(:workshop, name: "Wash Shop", service_category: wash)
        get workshops_path, params: { category: "sto" }
        expect(response.body).to include("STO Shop")
        expect(response.body).not_to include("Wash Shop")
      end
    end

    describe "GET /workshops/:id" do
      it "returns success without authentication" do
        workshop = create(:workshop, :with_working_hours)
        get workshop_path(workshop)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "authenticated access" do
    before { sign_in user }

    describe "GET /workshops/new" do
      it "returns success" do
        get new_workshop_path
        expect(response).to have_http_status(:success)
      end
    end

    describe "POST /workshops" do
      it "creates a workshop" do
        expect {
          post workshops_path, params: { workshop: valid_attrs }
        }.to change(Workshop, :count).by(1)

        expect(response).to redirect_to(workshop_path(Workshop.last))
      end

      it "creates a workshop with nested working hours" do
        attrs = valid_attrs.merge(
          working_hours_attributes: [
            { day_of_week: 1, opens_at: "08:00", closes_at: "18:00", closed: false },
            { day_of_week: 0, closed: true }
          ]
        )

        expect {
          post workshops_path, params: { workshop: attrs }
        }.to change(Workshop, :count).by(1)
          .and change(WorkingHour, :count).by(2)
      end

      it "renders new on invalid params" do
        post workshops_path, params: { workshop: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "GET /workshops/:id/edit" do
      it "returns success" do
        workshop = create(:workshop, :with_working_hours)
        get edit_workshop_path(workshop)
        expect(response).to have_http_status(:success)
      end
    end

    describe "PATCH /workshops/:id" do
      it "updates the workshop" do
        workshop = create(:workshop)
        patch workshop_path(workshop), params: { workshop: { name: "Updated Name" } }
        expect(response).to redirect_to(workshop_path(workshop))
        expect(workshop.reload.name).to eq("Updated Name")
      end

      it "renders edit on invalid params" do
        workshop = create(:workshop, :with_working_hours)
        patch workshop_path(workshop), params: { workshop: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "DELETE /workshops/:id" do
      it "deletes the workshop and its working hours" do
        workshop = create(:workshop, :with_working_hours)
        expect {
          delete workshop_path(workshop)
        }.to change(Workshop, :count).by(-1)
          .and change(WorkingHour, :count).by(-7)

        expect(response).to redirect_to(workshops_path)
      end
    end
  end

  describe "unauthenticated CUD access" do
    it "redirects new to sign in" do
      get new_workshop_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects create to sign in" do
      post workshops_path, params: { workshop: valid_attrs }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects edit to sign in" do
      workshop = create(:workshop)
      get edit_workshop_path(workshop)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects update to sign in" do
      workshop = create(:workshop)
      patch workshop_path(workshop), params: { workshop: valid_attrs }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects delete to sign in" do
      workshop = create(:workshop)
      delete workshop_path(workshop)
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
