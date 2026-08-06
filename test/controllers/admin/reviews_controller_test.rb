require "test_helper"

class Admin::ReviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = admins(:one)
    sign_in_admin(@admin)
    @review = reviews(:published_review)
  end

  # --- Authentication ---

  test "unauthenticated request redirects to admin sign in" do
    reset!
    get admin_reviews_path
    assert_redirected_to new_admin_session_path
  end

  # --- Index ---

  test "index lists all reviews" do
    get admin_reviews_path
    assert_response :success
    assert_select "table"
  end

  test "index filters by status" do
    get admin_reviews_path(status: "published")
    assert_response :success
  end

  test "index shows hidden reviews when filtered" do
    get admin_reviews_path(status: "hidden")
    assert_response :success
  end

  # --- Update (hide) ---

  test "hide sets review to hidden" do
    assert @review.published?

    patch admin_review_path(@review), params: { status: "hidden" }
    assert_redirected_to admin_reviews_path

    @review.reload
    assert @review.hidden?
  end

  test "hiding recomputes workshop rating" do
    workshop = @review.workshop
    workshop.recompute_rating!
    original_count = workshop.review_count

    patch admin_review_path(@review), params: { status: "hidden" }
    workshop.reload

    assert_equal original_count - 1, workshop.review_count
  end

  # --- Update (unhide) ---

  test "unhide sets review back to published" do
    hidden = reviews(:hidden_review)
    assert hidden.hidden?

    patch admin_review_path(hidden), params: { status: "published" }
    assert_redirected_to admin_reviews_path

    hidden.reload
    assert hidden.published?
  end

  test "unhiding recomputes workshop rating" do
    hidden = reviews(:hidden_review)
    workshop = hidden.workshop
    workshop.recompute_rating!
    original_count = workshop.review_count

    patch admin_review_path(hidden), params: { status: "published" }
    workshop.reload

    assert_equal original_count + 1, workshop.review_count
  end

  # --- Invalid status ---

  test "update rejects invalid status" do
    patch admin_review_path(@review), params: { status: "bogus" }
    assert_redirected_to admin_reviews_path
    assert_equal I18n.t("admin.reviews.update.invalid_status"), flash[:alert]

    @review.reload
    assert @review.published?
  end

  test "update rejects flagged as target status" do
    patch admin_review_path(@review), params: { status: "flagged" }
    assert_redirected_to admin_reviews_path
    assert_equal I18n.t("admin.reviews.update.invalid_status"), flash[:alert]
  end
end
