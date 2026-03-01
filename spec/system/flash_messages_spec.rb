require "rails_helper"

RSpec.describe "Flash Messages", type: :system do
  let(:user) { create(:user, email: "flash@aulabs.io", password: "password123") }

  after do
    Warden.test_reset!
  end

  describe "flash message display" do
    it "shows success flash with green indicator after sign in" do
      visit new_user_session_path

      fill_in "Corporate email", with: user.email
      fill_in "Password", with: "password123"
      click_button "Sign in"

      within("[data-controller='flash']") do
        expect(page).to have_text("Signed in successfully")
        expect(page).to have_css(".bg-green-500")
      end
    end

    it "shows alert flash with red indicator on failed sign in" do
      visit new_user_session_path

      fill_in "Corporate email", with: user.email
      fill_in "Password", with: "wrongpassword"
      click_button "Sign in"

      within("[data-controller='flash']") do
        expect(page).to have_text("Invalid")
        expect(page).to have_css(".bg-red-500")
      end
    end
  end

  describe "close button" do
    it "renders a close button with the x-mark icon" do
      visit new_user_session_path

      fill_in "Corporate email", with: user.email
      fill_in "Password", with: "password123"
      click_button "Sign in"

      within("[data-controller='flash']") do
        close_button = find("button[aria-label='Close']")
        expect(close_button).to be_present
        expect(close_button).to have_css("svg")
      end
    end

    it "dismisses flash when close button is clicked" do
      visit new_user_session_path

      fill_in "Corporate email", with: user.email
      fill_in "Password", with: "password123"
      click_button "Sign in"

      expect(page).to have_css("[data-controller='flash']")

      find("button[aria-label='Close']").click

      expect(page).to have_no_css("[data-controller='flash']", wait: 2)
    end
  end

  describe "auto-dismiss" do
    it "automatically disappears after the duration" do
      visit new_user_session_path

      fill_in "Corporate email", with: user.email
      fill_in "Password", with: "password123"
      click_button "Sign in"

      expect(page).to have_css("[data-controller='flash']")

      # Default duration is 5000ms + 300ms transition
      expect(page).to have_no_css("[data-controller='flash']", wait: 7)
    end
  end
end
