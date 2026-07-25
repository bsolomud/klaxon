require "test_helper"

class Admin::CarModelsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = admins(:one)
    sign_in_admin(@admin)
    @pending = car_models(:pending_model)
  end

  test "index lists car models" do
    get admin_car_models_path
    assert_response :success
  end

  test "approve transitions a pending model" do
    patch transition_admin_car_model_path(@pending, event: "approve")
    assert @pending.reload.approved?
    assert_redirected_to admin_car_models_path
  end

  test "reject transitions a pending model" do
    patch transition_admin_car_model_path(@pending, event: "reject")
    assert @pending.reload.rejected?
  end

  test "invalid event leaves the model unchanged" do
    patch transition_admin_car_model_path(@pending, event: "bogus")
    assert @pending.reload.pending?
    assert_redirected_to admin_car_models_path
  end

  test "requires admin auth" do
    reset!
    get admin_car_models_path
    assert_redirected_to new_admin_session_path
  end
end
