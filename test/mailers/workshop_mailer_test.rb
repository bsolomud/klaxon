require "test_helper"

class WorkshopMailerTest < ActionMailer::TestCase
  setup do
    @workshop = workshops(:pending_workshop)
    @owner = users(:three)
  end

  test "approved sends email to workshop owners" do
    @workshop.update!(status: :active)
    email = WorkshopMailer.with(workshop: @workshop).approved

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [@owner.email], email.to
    assert_match @workshop.name, email.subject
    assert_match @workshop.name, email.html_part.body.to_s
    assert_match @workshop.name, email.text_part.body.to_s
  end

  test "declined sends email with decline reason" do
    @workshop.update!(status: :declined, decline_reason: "Документи не повні")
    email = WorkshopMailer.with(workshop: @workshop).declined

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [@owner.email], email.to
    assert_match @workshop.name, email.subject
    assert_match "Документи не повні", email.html_part.body.to_s
    assert_match "Документи не повні", email.text_part.body.to_s
  end

  test "approved sends to multiple owners when present" do
    second_owner = users(:two)
    @workshop.workshop_operators.create!(user: second_owner, role: :owner)
    email = WorkshopMailer.with(workshop: @workshop).approved
    email.deliver_now

    assert_includes email.to, @owner.email
    assert_includes email.to, second_owner.email
  end
end
