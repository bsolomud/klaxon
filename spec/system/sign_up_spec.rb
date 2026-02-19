require "rails_helper"

RSpec.describe "Sign Up", type: :system do
  before do
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
  end

  after do
    Warden.test_reset!
  end

  describe "registration form" do
    it "shows the registration form with correct English labels" do
      visit new_user_registration_path

      expect(page).to have_text("Sign up for")
      expect(page).to have_field("user_email")
      expect(page).to have_css("label[for='user_email']")
      expect(page).to have_field("user_password")
      expect(page).to have_button("Create account")
      expect(page).to have_text(/already have an account/i)
    end
  end

  describe "successful registration" do
    it "registers with valid data and redirects to sign-in" do
      visit new_user_registration_path

      fill_in "user_email", with: "newuser@aulabs.io"
      fill_in "user_password", with: "password123"
      fill_in "user_password_confirmation", with: "password123"
      click_button "Create account"

      # With :confirmable enabled, registration redirects to sign-in page.
      # Flash may show confirmation message or unauthenticated message depending on Turbo redirects.
      expect(page).to have_current_path(new_user_session_path)
      expect(User.find_by(email: "newuser@aulabs.io")).to be_present
    end
  end

  describe "failed registration" do
    it "shows errors with duplicate email" do
      create(:user, email: "existing@aulabs.io")

      using_session(:fresh_duplicate_test) do
        visit new_user_registration_path
        expect(page).to have_button("Create account", wait: 5)

        fill_in "user_email", with: "existing@aulabs.io"
        fill_in "user_password", with: "password123"
        fill_in "user_password_confirmation", with: "password123"
        click_button "Create account"

        expect(page).to have_css(".text-red-600", wait: 5)
      end
    end

    it "shows errors with mismatched passwords" do
      visit new_user_registration_path

      fill_in "user_email", with: "newuser@aulabs.io"
      fill_in "user_password", with: "password123"
      fill_in "user_password_confirmation", with: "differentpassword"
      click_button "Create account"

      expect(page).to have_css(".text-red-600")
    end

    it "shows errors with too short password" do
      visit new_user_registration_path

      fill_in "user_email", with: "newuser@aulabs.io"
      fill_in "user_password", with: "short"
      fill_in "user_password_confirmation", with: "short"
      click_button "Create account"

      expect(page).to have_css(".text-red-600")
    end
  end
end
