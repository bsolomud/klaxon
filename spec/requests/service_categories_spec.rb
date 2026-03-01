require "rails_helper"

RSpec.describe "ServiceCategories", type: :request do
  let(:user) { create(:user) }
  let(:valid_attrs) { { name: "STO", slug: "sto" } }

  describe "public access" do
    describe "GET /service_categories" do
      it "returns success without authentication" do
        get service_categories_path
        expect(response).to have_http_status(:success)
      end

      it "lists all categories" do
        create(:service_category, name: "STO")
        create(:service_category, name: "Car Wash")
        get service_categories_path
        expect(response.body).to include("STO")
        expect(response.body).to include("Car Wash")
      end
    end

    describe "GET /service_categories/:id" do
      it "returns success without authentication" do
        category = create(:service_category)
        get service_category_path(category)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "authenticated access" do
    before { sign_in user }

    describe "GET /service_categories/new" do
      it "returns success" do
        get new_service_category_path
        expect(response).to have_http_status(:success)
      end
    end

    describe "POST /service_categories" do
      it "creates a service category" do
        expect {
          post service_categories_path, params: { service_category: valid_attrs }
        }.to change(ServiceCategory, :count).by(1)

        expect(response).to redirect_to(service_category_path(ServiceCategory.last))
      end

      it "renders new on invalid params" do
        post service_categories_path, params: { service_category: { name: "", slug: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "GET /service_categories/:id/edit" do
      it "returns success" do
        category = create(:service_category)
        get edit_service_category_path(category)
        expect(response).to have_http_status(:success)
      end
    end

    describe "PATCH /service_categories/:id" do
      it "updates the category" do
        category = create(:service_category)
        patch service_category_path(category), params: { service_category: { name: "Updated" } }
        expect(response).to redirect_to(service_category_path(category))
        expect(category.reload.name).to eq("Updated")
      end

      it "renders edit on invalid params" do
        category = create(:service_category)
        patch service_category_path(category), params: { service_category: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "DELETE /service_categories/:id" do
      it "deletes the category" do
        category = create(:service_category)
        expect {
          delete service_category_path(category)
        }.to change(ServiceCategory, :count).by(-1)

        expect(response).to redirect_to(service_categories_path)
      end

      it "does not delete category with workshops" do
        category = create(:service_category)
        create(:workshop, service_category: category)

        expect {
          delete service_category_path(category)
        }.not_to change(ServiceCategory, :count)

        expect(response).to redirect_to(service_category_path(category))
      end
    end
  end

  describe "unauthenticated CUD access" do
    it "redirects new to sign in" do
      get new_service_category_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects create to sign in" do
      post service_categories_path, params: { service_category: valid_attrs }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects edit to sign in" do
      category = create(:service_category)
      get edit_service_category_path(category)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects update to sign in" do
      category = create(:service_category)
      patch service_category_path(category), params: { service_category: valid_attrs }
      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects delete to sign in" do
      category = create(:service_category)
      delete service_category_path(category)
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
