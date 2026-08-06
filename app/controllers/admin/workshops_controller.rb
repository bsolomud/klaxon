class Admin::WorkshopsController < Admin::BaseController
  include NotificationDispatch
  include StateTransitionable

  before_action :set_workshop, only: %i[show transition document]

  TRANSITIONS = {
    "approve"  => { from: :pending,  to: :active },
    "decline"  => { from: :pending,  to: :declined },
    "suspend"  => { from: :active,   to: :suspended }
  }.freeze

  def index
    scope = Workshop.order(created_at: :desc)
    scope = scope.where(status: params[:status]) if valid_status_filter?
    @pagy, @workshops = pagy(scope, limit: 50)
  end

  def show
    @owner = @workshop.workshop_operators.find_by(role: :owner)&.user
  end

  # Streams the verification document through this admin-only action, so the
  # file is never exposed via a public (signed) ActiveStorage URL.
  def document
    unless @workshop.verification_document.attached?
      return redirect_to admin_workshop_path(@workshop), alert: t("admin.workshops.document.missing")
    end

    doc = @workshop.verification_document
    response.headers["X-Content-Type-Options"] = "nosniff"
    send_data doc.download, filename: doc.filename.to_s, type: doc.content_type, disposition: "inline"
  end

  def transition
    event = params[:event]
    rule = TRANSITIONS[event]
    unless rule
      return redirect_to admin_workshop_path(@workshop), alert: t("admin.workshops.transition.invalid_status")
    end

    transition_status(
      @workshop,
      required_status: rule[:from],
      transition: "#{rule[:to]}!".to_sym,
      redirect_path: admin_workshop_path(@workshop),
      invalid_message: t("admin.workshops.transition.invalid_status"),
      after_success: ->(_workshop) { notify_workshop_owners(event) }
    ) do |workshop|
      workshop.decline_reason = params[:decline_reason] if event == "decline"
    end
  end

  private

  def valid_status_filter?
    params[:status].present? && params[:status].in?(Workshop.statuses.keys)
  end

  def set_workshop
    @workshop = Workshop.includes(:service_categories).find(params[:id])
  end

  def notify_workshop_owners(event)
    owner_ids = @workshop.workshop_operators.where(role: :owner).pluck(:user_id)

    case event
    when "approve"
      dispatch_notification(
        recipients: owner_ids,
        notifiable: @workshop,
        event: :workshop_approved,
        mailer: WorkshopMailer.with(workshop: @workshop).approved
      )
    when "decline"
      dispatch_notification(
        recipients: owner_ids,
        notifiable: @workshop,
        event: :workshop_declined,
        mailer: WorkshopMailer.with(workshop: @workshop).declined
      )
    end
  end
end
