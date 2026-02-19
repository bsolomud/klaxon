require "rails_helper"

RSpec.describe "Sign In", type: :system do
  before do
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
  end

  let(:user) { create(:user, email: "test@aulabs.io", password: "password123") }

  describe "successful sign in" do
    it "signs in with valid credentials and redirects to dashboard" do
      visit new_user_session_path

      fill_in "Corporate email", with: user.email
      fill_in "Password", with: "password123"
      click_button "Sign in"

      expect(page).to have_current_path(root_path)
      expect(page).to have_text("Signed in successfully")
    end

    it "shows the sign-in form with correct English labels" do
      visit new_user_session_path

      expect(page).to have_text("Sign in to")
      expect(page).to have_field("Corporate email")
      expect(page).to have_field("Password")
      expect(page).to have_button("Sign in")
      expect(page).to have_text("Forgot your password?")
      expect(page).to have_text("Create account")
    end

    it "signs in with remember me checked" do
      visit new_user_session_path

      fill_in "Corporate email", with: user.email
      fill_in "Password", with: "password123"
      check "Remember me"
      click_button "Sign in"

      expect(page).to have_current_path(root_path)
      expect(page).to have_text("Signed in successfully")
    end
  end

  describe "failed sign in" do
    it "shows error with wrong password" do
      visit new_user_session_path

      fill_in "Corporate email", with: user.email
      fill_in "Password", with: "wrongpassword"
      click_button "Sign in"

      expect(page).to have_text("Invalid")
      expect(page).to have_current_path(new_user_session_path)
    end

    it "shows error with non-existent email" do
      visit new_user_session_path

      fill_in "Corporate email", with: "nonexistent@aulabs.io"
      fill_in "Password", with: "password123"
      click_button "Sign in"

      expect(page).to have_text("Invalid")
    end
  end

  describe "unconfirmed user" do
    let(:unconfirmed_user) { create(:user, :unconfirmed, email: "unconfirmed@aulabs.io", password: "password123") }

    it "cannot sign in and sees confirmation message" do
      visit new_user_session_path

      fill_in "Corporate email", with: unconfirmed_user.email
      fill_in "Password", with: "password123"
      click_button "Sign in"

      expect(page).to have_text("confirm")
    end
  end

  describe "locked user" do
    let(:locked_user) { create(:user, :locked, email: "locked@aulabs.io", password: "password123") }

    it "cannot sign in and sees locked message" do
      visit new_user_session_path

      fill_in "Corporate email", with: locked_user.email
      fill_in "Password", with: "password123"
      click_button "Sign in"

      expect(page).to have_text("locked")
    end
  end

  describe "unauthenticated access" do
    it "redirects to sign-in page when accessing protected page" do
      visit root_path

      expect(page).to have_current_path(new_user_session_path)
    end
  end
end
