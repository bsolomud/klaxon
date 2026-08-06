require "test_helper"

class WorkshopsMapTest < ActionDispatch::IntegrationTest
  test "index renders a map wired with geolocated workshop points" do
    get workshops_path
    assert_response :success
    assert_select "[data-controller='map']"
    assert_match workshops(:one).name, response.body
    assert_match "50.4501", response.body
  end

  test "show replaces raw coordinates with a map" do
    get workshop_path(workshops(:one))
    assert_response :success
    assert_select "[data-controller='map']"
    assert_select "dd.font-mono", false
  end
end
