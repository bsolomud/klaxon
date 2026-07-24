require "test_helper"

class WorkshopManagement::OperatorsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @owner = users(:one)      # owner_one of workshop one
    @workshop = workshops(:one)
    @staff = users(:two)      # staff_two of workshop one
    sign_in @owner
  end

  test "owner sees the team" do
    get workshop_management_workshop_operators_path(@workshop)
    assert_response :success
    assert_select "p", text: @owner.email
  end

  test "owner adds an existing user as staff by email" do
    user = users(:three)
    assert_difference "WorkshopOperator.count", 1 do
      post workshop_management_workshop_operators_path(@workshop), params: { email: user.email }
    end
    assert @workshop.workshop_operators.exists?(user: user, role: "staff")
  end

  test "adding an unknown email adds nobody" do
    assert_no_difference "WorkshopOperator.count" do
      post workshop_management_workshop_operators_path(@workshop), params: { email: "nobody@example.com" }
    end
  end

  test "cannot add an existing member twice" do
    assert_no_difference "WorkshopOperator.count" do
      post workshop_management_workshop_operators_path(@workshop), params: { email: @staff.email }
    end
  end

  test "owner can change a member's role" do
    staff_op = @workshop.workshop_operators.find_by(user: @staff)
    patch workshop_management_workshop_operator_path(@workshop, staff_op),
      params: { workshop_operator: { role: "owner" } }
    assert staff_op.reload.owner?
  end

  test "cannot remove the last owner" do
    owner_op = @workshop.workshop_operators.owner.first
    assert_equal 1, @workshop.workshop_operators.owner.count
    assert_no_difference "WorkshopOperator.count" do
      delete workshop_management_workshop_operator_path(@workshop, owner_op)
    end
  end

  test "owner can remove staff" do
    staff_op = @workshop.workshop_operators.find_by(user: @staff)
    assert_difference "WorkshopOperator.count", -1 do
      delete workshop_management_workshop_operator_path(@workshop, staff_op)
    end
  end

  test "staff cannot manage the team" do
    sign_in @staff
    get workshop_management_workshop_operators_path(@workshop)
    assert_redirected_to workshop_management_workshop_dashboard_path(@workshop)
  end
end
