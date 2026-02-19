require "rails_helper"

RSpec.describe "Sign Out", type: :system do
  before do
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
  end

  let(:user) { create(:user, email: "test@aulabs.io", password: "password123") }

  describe "successful sign out" do
    it "signs out when clicking the sign-out button" do
      login_as(user, scope: :user)
      visit root_path

      click_button "Sign out"

      expect(page).to have_text("Sign in to")
    end

    it "cannot access protected page after sign out" do
      login_as(user, scope: :user)
      visit root_path

      click_button "Sign out"

      expect(page).to have_text("Sign in to")

      Warden.test_reset!
      visit root_path
      expect(page).to have_current_path(new_user_session_path)
    end
  end

  describe "sign out button visibility" do
    it "shows sign-out button in header when signed in" do
      login_as(user, scope: :user)
      visit root_path

      expect(page).to have_button("Sign out")
    end

    it "does not show sign-out button on sign-in page" do
      visit new_user_session_path

      expect(page).not_to have_button("Sign out")
    end
  end
end
