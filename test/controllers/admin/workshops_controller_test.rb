require "test_helper"

class Admin::WorkshopsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = admins(:one)
    sign_in_admin(@admin)
  end

  # --- Authentication ---

  test "unauthenticated request redirects to admin sign in" do
    reset!
    get admin_workshops_path
    assert_redirected_to new_admin_session_path
  end

  # --- Index ---

  test "index lists all workshops" do
    get admin_workshops_path
    assert_response :success
    assert_select "table"
  end

  test "index filters by status" do
    get admin_workshops_path(status: "pending")
    assert_response :success
  end

  test "index shows pending workshops when filtered" do
    get admin_workshops_path(status: "pending")
    assert_response :success
    assert_select "td", text: workshops(:pending_workshop).name
  end

  # --- Show ---

  test "show displays workshop details" do
    workshop = workshops(:one)
    get admin_workshop_path(workshop)
    assert_response :success
    assert_select "h1", text: workshop.name
  end

  test "show displays owner info" do
    workshop = workshops(:one)
    owner = workshop.workshop_operators.find_by(role: :owner).user
    get admin_workshop_path(workshop)
    assert_response :success
    assert_select "dd", text: owner.email
  end

  test "show displays approve button for pending workshop" do
    workshop = workshops(:pending_workshop)
    get admin_workshop_path(workshop)
    assert_response :success
    assert_select "button[type=submit]", text: I18n.t("admin.workshops.show.approve")
  end

  test "show does not display approve button for active workshop" do
    workshop = workshops(:one)
    get admin_workshop_path(workshop)
    assert_response :success
    assert_select "button[type=submit]", text: I18n.t("admin.workshops.show.approve"), count: 0
  end

  # --- Approve ---

  test "approve sets pending workshop to active" do
    workshop = workshops(:pending_workshop)
    assert workshop.pending?

    patch transition_admin_workshop_path(workshop), params: { event: "approve" }
    assert_redirected_to admin_workshop_path(workshop)

    workshop.reload
    assert workshop.active?
  end

  test "approve does not change already active workshop" do
    workshop = workshops(:one)
    assert workshop.active?

    patch transition_admin_workshop_path(workshop), params: { event: "approve" }
    assert_redirected_to admin_workshop_path(workshop)
    assert_equal I18n.t("admin.workshops.transition.invalid_status"), flash[:alert]

    workshop.reload
    assert workshop.active?
  end

  # --- Decline ---

  test "decline sets pending workshop to declined" do
    workshop = workshops(:pending_workshop)
    assert workshop.pending?

    patch transition_admin_workshop_path(workshop), params: { event: "decline", decline_reason: "Incomplete documents" }
    assert_redirected_to admin_workshop_path(workshop)

    workshop.reload
    assert workshop.declined?
    assert_equal "Incomplete documents", workshop.decline_reason
  end

  test "decline without reason still works" do
    workshop = workshops(:pending_workshop)

    patch transition_admin_workshop_path(workshop), params: { event: "decline" }
    assert_redirected_to admin_workshop_path(workshop)

    workshop.reload
    assert workshop.declined?
    assert_nil workshop.decline_reason
  end

  test "decline does not change already active workshop" do
    workshop = workshops(:one)
    assert workshop.active?

    patch transition_admin_workshop_path(workshop), params: { event: "decline", decline_reason: "test" }
    assert_redirected_to admin_workshop_path(workshop)
    assert_equal I18n.t("admin.workshops.transition.invalid_status"), flash[:alert]

    workshop.reload
    assert workshop.active?
  end

  test "show displays decline button for pending workshop" do
    workshop = workshops(:pending_workshop)
    get admin_workshop_path(workshop)
    assert_response :success
    assert_select "button", text: I18n.t("admin.workshops.show.decline")
  end

  test "show does not display decline button for active workshop" do
    workshop = workshops(:one)
    get admin_workshop_path(workshop)
    assert_response :success
    assert_select "button", text: I18n.t("admin.workshops.show.decline"), count: 0
  end

  test "show displays decline reason for declined workshop" do
    workshop = workshops(:declined_workshop)
    get admin_workshop_path(workshop)
    assert_response :success
    assert_select "p", text: workshop.decline_reason
  end

  # --- Suspend ---

  test "suspend sets active workshop to suspended" do
    workshop = workshops(:one)
    assert workshop.active?

    patch transition_admin_workshop_path(workshop), params: { event: "suspend" }
    assert_redirected_to admin_workshop_path(workshop)

    workshop.reload
    assert workshop.suspended?
  end

  test "suspend does not change pending workshop" do
    workshop = workshops(:pending_workshop)
    assert workshop.pending?

    patch transition_admin_workshop_path(workshop), params: { event: "suspend" }
    assert_redirected_to admin_workshop_path(workshop)
    assert_equal I18n.t("admin.workshops.transition.invalid_status"), flash[:alert]

    workshop.reload
    assert workshop.pending?
  end

  test "show displays suspend button for active workshop" do
    workshop = workshops(:one)
    get admin_workshop_path(workshop)
    assert_response :success
    assert_select "button[type=submit]", text: I18n.t("admin.workshops.show.suspend")
  end

  test "show does not display suspend button for pending workshop" do
    workshop = workshops(:pending_workshop)
    get admin_workshop_path(workshop)
    assert_response :success
    assert_select "button[type=submit]", text: I18n.t("admin.workshops.show.suspend"), count: 0
  end
end
