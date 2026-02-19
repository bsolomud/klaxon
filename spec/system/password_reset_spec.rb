require "rails_helper"

RSpec.describe "Password Reset", type: :system do
  before do
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
  end

  let(:user) { create(:user, email: "test@aulabs.io", password: "password123") }

  describe "request password reset" do
    it "shows the password reset form with correct styling" do
      visit new_user_password_path

      expect(page).to have_text("Password recovery")
      expect(page).to have_field("Corporate email")
      expect(page).to have_button("Send instructions")
      expect(page).to have_text("Remember your password?")
    end

    it "sends reset instructions for valid email" do
      visit new_user_password_path

      fill_in "Corporate email", with: user.email
      click_button "Send instructions"

      expect(page).to have_text("instructions")
    end

    it "shows error for non-existent email" do
      visit new_user_password_path

      fill_in "Corporate email", with: "nonexistent@aulabs.io"
      click_button "Send instructions"

      expect(page).to have_text("not found")
    end
  end

  describe "navigating from sign-in" do
    it "links to password reset from sign-in page" do
      visit new_user_session_path

      click_link "Forgot your password?"

      expect(page).to have_current_path(new_user_password_path)
    end
  end
end
