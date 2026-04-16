require "test_helper"

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @completed_request = service_requests(:completed_request)
    sign_in @user
  end

  # --- Authentication ---

  test "unauthenticated request redirects to sign in" do
    sign_out @user
    get new_service_request_review_path(@completed_request)
    assert_redirected_to new_user_session_path
  end

  # --- New ---

  test "new renders form for completed request with no review" do
    # Remove existing review first
    reviews(:published_review).destroy!
    get new_service_request_review_path(@completed_request)
    assert_response :success
    assert_select "form"
  end

  test "new redirects when request already has review" do
    get new_service_request_review_path(@completed_request)
    assert_redirected_to service_request_path(@completed_request)
  end

  test "new returns 404 for non-completed request" do
    pending_request = service_requests(:pending_request)
    get new_service_request_review_path(pending_request)
    assert_response :not_found
  end

  test "new returns 404 for other users request" do
    other_completed = service_requests(:other_user_completed)
    get new_service_request_review_path(other_completed)
    assert_response :not_found
  end

  # --- Create ---

  test "create saves review and redirects to workshop" do
    reviews(:published_review).destroy!
    assert_difference "Review.count", 1 do
      post service_request_review_path(@completed_request), params: {
        review: { rating: 5, body: "Great!" }
      }
    end
    assert_redirected_to workshop_path(@completed_request.workshop)
    assert_equal I18n.t("reviews.create.success"), flash[:notice]
  end

  test "create assigns current_user and workshop automatically" do
    reviews(:published_review).destroy!
    post service_request_review_path(@completed_request), params: {
      review: { rating: 4, body: "Good" }
    }
    review = Review.last
    assert_equal @user.id, review.user_id
    assert_equal @completed_request.workshop_id, review.workshop_id
  end

  test "create re-renders form on invalid params" do
    reviews(:published_review).destroy!
    assert_no_difference "Review.count" do
      post service_request_review_path(@completed_request), params: {
        review: { rating: nil, body: "" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "cannot create duplicate review" do
    post service_request_review_path(@completed_request), params: {
      review: { rating: 3, body: "Duplicate" }
    }
    assert_redirected_to service_request_path(@completed_request)
    assert_equal I18n.t("reviews.create.already_reviewed"), flash[:alert]
  end
end
