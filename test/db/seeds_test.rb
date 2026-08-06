require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  test "seeds create admin record" do
    Admin.delete_all

    load Rails.root.join("db/seeds.rb")

    admin = Admin.find_by(email: "admin@aulabs.dev")
    assert admin, "Admin record should be created"
    assert admin.valid_password?("password"), "Admin should authenticate with default password"
  end

  test "seeds are idempotent" do
    Admin.delete_all

    load Rails.root.join("db/seeds.rb")
    load Rails.root.join("db/seeds.rb")

    assert_equal 1, Admin.where(email: "admin@aulabs.dev").count
  end

  test "seeds use ADMIN_PASSWORD env var when set" do
    Admin.delete_all

    ENV["ADMIN_PASSWORD"] = "custom_secret"
    load Rails.root.join("db/seeds.rb")
    ENV.delete("ADMIN_PASSWORD")

    admin = Admin.find_by(email: "admin@aulabs.dev")
    assert admin.valid_password?("custom_secret")
  end
end
