require "test_helper"

class AdminTest < ActiveSupport::TestCase
  def setup
    @admin = admins(:one)
  end

  test "admin is valid with email and password" do
    admin = Admin.new(email: "new@aulabs.dev", password: "password")
    assert admin.valid?
  end

  test "admin is invalid without email" do
    admin = Admin.new(email: nil, password: "password")
    assert_not admin.valid?
    assert_includes admin.errors[:email], "can't be blank"
  end

  test "admin is invalid without password" do
    admin = Admin.new(email: "new@aulabs.dev", password: nil)
    assert_not admin.valid?
    assert_includes admin.errors[:password], "can't be blank"
  end

  test "admin email must be unique" do
    duplicate = Admin.new(email: @admin.email, password: "password")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "admin table is separate from users" do
    assert_not_equal Admin.table_name, User.table_name
    assert_equal "admins", Admin.table_name
  end

  test "admin can be created with valid attributes" do
    admin = Admin.create!(email: "a@b.com", password: "password")
    assert admin.persisted?
  end
end
