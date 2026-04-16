require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @workshop = workshops(:one)
  end

  test "defaults to driver role" do
    user = User.new
    assert user.driver?
  end

  test "driver? returns true for driver role" do
    assert @user.driver?
  end

  test "role column has default value of 0" do
    assert_equal "driver", @user.role
  end

  test "workshops returns workshops via join table" do
    assert_includes @user.workshops, @workshop
  end

  test "workshop_operators returns workshop operators" do
    assert_equal 1, @user.workshop_operators.count
    assert_equal @workshop, @user.workshop_operators.first.workshop
  end

  test "manages_workshop? returns true for managed workshop" do
    assert @user.manages_workshop?(@workshop)
  end

  test "manages_workshop? returns false for unmanaged workshop" do
    other_workshop = workshops(:two)
    user_two = users(:two)
    # user_two is staff on workshop :one, not on workshop :two
    assert_not user_two.manages_workshop?(other_workshop)
  end

  test "workshop_owner? returns true when user has owner role" do
    assert @user.workshop_owner?
  end

  test "workshop_owner? returns false when user is only staff" do
    user_two = users(:two)
    assert_not user_two.workshop_owner?
  end

  test "full_name returns first and last name" do
    @user.update_columns(first_name: "Іван", last_name: "Петренко")
    assert_equal "Іван Петренко", @user.full_name
  end

  test "full_name returns first name only when last name blank" do
    @user.update_columns(first_name: "Іван", last_name: nil)
    assert_equal "Іван", @user.full_name
  end

  test "full_name returns nil when both names blank" do
    @user.update_columns(first_name: nil, last_name: nil)
    assert_nil @user.full_name
  end

  test "show_welcome_banner? returns true for new user" do
    user = users(:brand_new_user)
    assert user.show_welcome_banner?
  end

  test "show_welcome_banner? returns false after dismissal" do
    user = users(:brand_new_user)
    user.dismiss_welcome_banner!
    assert_not user.show_welcome_banner?
  end

  test "show_welcome_banner? returns false for user older than 7 days" do
    user = users(:brand_new_user)
    user.update_columns(created_at: 8.days.ago)
    assert_not user.show_welcome_banner?
  end

  test "dismiss_welcome_banner! sets flags" do
    user = users(:brand_new_user)
    user.dismiss_welcome_banner!
    assert_equal true, user.onboarding_flags["welcome_dismissed"]
    assert user.onboarding_flags["welcome_dismissed_at"].present?
  end

  test "onboarding_flags defaults to empty hash" do
    user = User.new
    assert_equal({}, user.onboarding_flags)
  end
end
