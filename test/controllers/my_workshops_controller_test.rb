require "test_helper"

class MyWorkshopsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # --- Authentication ---

  test "index requires authentication" do
    get my_workshops_path
    assert_redirected_to new_user_session_path
  end

  # --- User with workshops (all statuses) ---

  test "index lists all workshops the user manages" do
    user = users(:three)
    sign_in user

    get my_workshops_path
    assert_response :success

    assert_select "h2", text: workshops(:pending_workshop).name
    assert_select "h2", text: workshops(:declined_workshop).name
    assert_select "h2", text: workshops(:suspended_workshop).name
  end

  test "index shows pending badge with spinner" do
    sign_in users(:three)
    get my_workshops_path
    assert_select "span.bg-yellow-100", text: /#{I18n.t('my_workshops.index.status_pending')}/
  end

  test "index shows declined badge with reason" do
    sign_in users(:three)
    get my_workshops_path
    assert_select "span.bg-red-100", text: /#{I18n.t('my_workshops.index.status_declined')}/
    assert_select "div.bg-red-50", text: /Неповний пакет документів/
  end

  test "index shows suspended badge" do
    sign_in users(:three)
    get my_workshops_path
    assert_select "span", text: /#{I18n.t('my_workshops.index.status_suspended')}/
  end

  test "index shows active badge with manage link" do
    sign_in users(:one)
    get my_workshops_path
    assert_select "span.bg-green-100", text: /#{I18n.t('my_workshops.index.status_active')}/
    assert_select "a", text: I18n.t("my_workshops.index.manage")
  end

  # --- User with no workshops ---

  test "index shows empty state for user with no workshops" do
    sign_in users(:driver_no_workshops)
    get my_workshops_path
    assert_response :success
    assert_select "p", text: I18n.t("my_workshops.index.empty")
  end

  # --- Does not show other users' workshops ---

  test "index does not include workshops from other users" do
    sign_in users(:driver_no_workshops)
    get my_workshops_path
    assert_select "h2", text: workshops(:one).name, count: 0
    assert_select "h2", text: workshops(:pending_workshop).name, count: 0
  end
end
