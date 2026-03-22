require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
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
end
