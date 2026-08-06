require "test_helper"

class Admin::CarMakesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = admins(:one)
    sign_in_admin(@admin)
  end

  # --- Authentication ---

  test "unauthenticated request redirects to admin sign in" do
    reset!
    get admin_car_makes_path
    assert_redirected_to new_admin_session_path
  end

  # --- Index ---

  test "index lists all car makes" do
    get admin_car_makes_path
    assert_response :success
    assert_select "table"
  end

  test "index filters by status" do
    get admin_car_makes_path(status: "pending")
    assert_response :success
  end

  test "index shows pending makes when filtered" do
    get admin_car_makes_path(status: "pending")
    assert_response :success
    assert_select "td", text: car_makes(:pending_make).name
  end

  # --- Transitions ---

  test "approve transitions pending make to approved" do
    car_make = car_makes(:pending_make)
    assert car_make.pending?

    patch transition_admin_car_make_path(car_make), params: { event: "approve" }
    assert_redirected_to admin_car_makes_path

    car_make.reload
    assert car_make.approved?
  end

  test "reject transitions pending make to rejected" do
    car_make = car_makes(:pending_make)
    assert car_make.pending?

    patch transition_admin_car_make_path(car_make), params: { event: "reject" }
    assert_redirected_to admin_car_makes_path

    car_make.reload
    assert car_make.rejected?
  end

  test "cannot approve already approved make" do
    car_make = car_makes(:toyota)
    assert car_make.approved?

    patch transition_admin_car_make_path(car_make), params: { event: "approve" }
    assert_redirected_to admin_car_makes_path

    car_make.reload
    assert car_make.approved?
  end

  test "approving make also approves its pending models" do
    car_make = car_makes(:pending_make)
    pending_model = car_make.car_models.create!(name: "PendingChild", status: :pending)

    patch transition_admin_car_make_path(car_make), params: { event: "approve" }

    pending_model.reload
    assert pending_model.approved?
  end
end
