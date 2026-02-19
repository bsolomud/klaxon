require "rails_helper"

RSpec.describe "Account Unlock", type: :system do
  before do
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
  end

  describe "unlock instructions form" do
    it "shows the unlock form with correct styling" do
      visit new_user_unlock_path

      expect(page).to have_text("Account unlock")
      expect(page).to have_field("Corporate email")
      expect(page).to have_button("Send unlock instructions")
    end

    it "sends unlock instructions for locked account" do
      locked_user = create(:user, :locked, email: "locked@aulabs.io")

      visit new_user_unlock_path

      fill_in "Corporate email", with: locked_user.email
      click_button "Send unlock instructions"

      expect(page).to have_text("instructions")
    end
  end
end
