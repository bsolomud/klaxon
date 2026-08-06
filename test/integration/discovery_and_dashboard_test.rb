require "test_helper"

class DiscoveryAndDashboardTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "workshops index renders filter and sort controls" do
    get workshops_path
    assert_response :success
    assert_select "select[name=category]"
    assert_select "select[name=sort]"
    assert_select "input[name=open_now]"
  end

  test "filters workshops by category slug" do
    slug = service_categories(:car_wash).slug
    get workshops_path(category: slug)
    assert_response :success
    assert_match workshops(:two).name, response.body
    assert_no_match(/#{Regexp.escape(workshops(:one).name)}/, response.body)
  end

  test "sort by rating responds successfully" do
    get workshops_path(sort: "rating")
    assert_response :success
  end

  test "dashboard shows an upcoming appointments section" do
    sign_in users(:one)
    service_requests(:pending_request).update!(preferred_time: 2.days.from_now)
    get root_path
    assert_response :success
    assert_match I18n.t("dashboard.index.upcoming"), response.body
  end
end
