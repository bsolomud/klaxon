require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @workshop = workshops(:one)
    @completed_request = service_requests(:completed_request)
    @review = reviews(:published_review)
  end

  test "valid review" do
    assert @review.valid?
  end

  test "requires rating" do
    @review.rating = nil
    assert_not @review.valid?
    assert @review.errors[:rating].any?
  end

  test "rating must be between 1 and 5" do
    @review.rating = 0
    assert_not @review.valid?

    @review.rating = 6
    assert_not @review.valid?

    (1..5).each do |r|
      @review.rating = r
      assert @review.valid?, "rating #{r} should be valid"
    end
  end

  test "service_request must be completed" do
    pending_request = service_requests(:pending_request)
    review = Review.new(
      user: @user,
      workshop: @workshop,
      service_request: pending_request,
      rating: 4
    )
    assert_not review.valid?
    assert review.errors[:service_request].any?
  end

  test "service_request must belong to user" do
    other_completed = service_requests(:other_user_completed)
    review = Review.new(
      user: @user,
      workshop: other_completed.workshop,
      service_request: other_completed,
      rating: 4
    )
    assert_not review.valid?
    assert review.errors[:service_request].any?
  end

  test "one review per service request (uniqueness)" do
    duplicate = Review.new(
      user: @user,
      workshop: @workshop,
      service_request: @completed_request,
      rating: 3
    )
    assert_not duplicate.valid?
    assert duplicate.errors[:service_request_id].any?
  end

  test "enum status values" do
    expected = { "published" => 0, "hidden" => 1, "flagged" => 2 }
    assert_equal expected, Review.statuses
  end

  test "published scope returns only published reviews" do
    published = Review.published
    assert published.all?(&:published?)
  end

  test "recent scope orders by created_at desc" do
    assert_equal Review.order(created_at: :desc).to_a, Review.recent.to_a
  end

  test "body is optional" do
    @review.body = nil
    assert @review.valid?
  end
end
