require "test_helper"

class WorkshopManagement::ReviewsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @owner = users(:one)
    @workshop = workshops(:one)
    @review = reviews(:published_review)
    @non_manager = users(:driver_no_workshops)
  end

  test "owner sees the reviews index" do
    sign_in @owner
    get workshop_management_workshop_reviews_path(@workshop)
    assert_response :success
  end

  test "non-manager cannot access the reviews index" do
    sign_in @non_manager
    get workshop_management_workshop_reviews_path(@workshop)
    assert_response :not_found
  end

  test "owner can respond to a review" do
    sign_in @owner
    patch respond_workshop_management_workshop_review_path(@workshop, @review),
      params: { review: { response: "Дякуємо за ваш відгук!" } }
    assert_redirected_to workshop_management_workshop_reviews_path(@workshop)
    @review.reload
    assert_equal "Дякуємо за ваш відгук!", @review.response
    assert @review.responded_at.present?
  end

  test "non-manager cannot respond to a review" do
    sign_in @non_manager
    patch respond_workshop_management_workshop_review_path(@workshop, @review),
      params: { review: { response: "hijack" } }
    assert_response :not_found
    assert_nil @review.reload.response
  end
end
