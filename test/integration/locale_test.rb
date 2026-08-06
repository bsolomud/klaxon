require "test_helper"

class LocaleTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "defaults to Ukrainian locale" do
    get workshops_path
    assert_select "html[lang=?]", "uk"
  end

  test "ignores browser Accept-Language and stays Ukrainian by default" do
    get workshops_path, headers: { "HTTP_ACCEPT_LANGUAGE" => "en-US,en;q=0.9" }
    assert_select "html[lang=?]", "uk"
  end

  test "explicit locale param switches language" do
    get workshops_path(locale: "en")
    assert_select "html[lang=?]", "en"
  end

  test "unknown locale falls back to default" do
    get workshops_path(locale: "zz")
    assert_select "html[lang=?]", "uk"
  end

  test "persists locale preference for signed-in user" do
    user = users(:one)
    sign_in user
    get workshops_path(locale: "en")
    assert_equal "en", user.reload.locale
  end

  test "signed-in user's saved locale is used without a param" do
    user = users(:one)
    user.update!(locale: "en")
    sign_in user
    get workshops_path
    assert_select "html[lang=?]", "en"
  end
end
