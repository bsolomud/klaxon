class AuFormBuilder < ActionView::Helpers::FormBuilder
  # Стандартні поля (Label зверху, Input знизу)
  (field_helpers - [:label, :check_box, :radio_button, :fields_for, :hidden_field]).each do |method_name|
    define_method(method_name) do |name, options = {}|
      # Додаємо червону рамку при помилці
      if object.errors[name].any?
        options[:class] = Array(options[:class]).join(" ") + " !border-red-500 !focus:ring-red-500"
      end

      @template.content_tag(:div, class: "mb-4") do
        super(name, options) + error_message_for(name)
      end
    end
  end

  def select(name, choices = nil, options = {}, html_options = {}, &block)
    if object.errors[name].any?
      html_options[:class] = Array(html_options[:class]).join(" ") + " !border-red-500 !focus:ring-red-500"
    end

    @template.content_tag(:div, class: "mb-4") do
      super(name, choices, options, html_options, &block) + error_message_for(name)
    end
  end

  # Appends a red "*" to a field's label when the model requires it (detected
  # from presence validators, evaluated against this record so conditional
  # rules resolve correctly). Keeps required-marking DRY and always in sync.
  def label(method, text = nil, options = {}, &block)
    if text.is_a?(Hash) # called as label(method, options)
      options = text
      text = nil
    end
    return super(method, text, options, &block) unless required_field?(method)

    marker = @template.required_mark

    if block
      super(method, options) { @template.capture(&block) + marker }
    else
      body = (text || method.to_s.humanize).to_s
      super(method, @template.safe_join([body, marker]), options)
    end
  end

  def check_box(name, options = {}, checked_value = "1", unchecked_value = "0")
    # Витягуємо текст лейбла, щоб він не потрапив у атрибути самого інпуту
    label_text = options.delete(:label_text)

    # Додаємо стиль помилки, якщо вона є
    error_class = object.errors[name].any? ? "ring-2 ring-red-500 ring-offset-2" : ""
    options[:class] = Array(options[:class]).join(" ") + " #{error_class}"

    @template.content_tag(:div, class: "flex flex-col") do
      @template.content_tag(:div, class: "flex items-center") do
        super(name, options, checked_value, unchecked_value) +
          label(name, label_text, class: "ml-2 block text-sm text-gray-600 cursor-pointer")
      end + error_message_for(name)
    end
  end

  private

  # True when the model has an active presence validation for this attribute.
  # Conditional validators (if:/unless:) are evaluated against the record, so a
  # field is marked required only in the context where it actually is.
  def required_field?(method)
    return false unless object.class.respond_to?(:validators_on)

    object.class.validators_on(method).any? do |validator|
      validator.is_a?(ActiveModel::Validations::PresenceValidator) && validator_active?(validator)
    end
  rescue StandardError
    false
  end

  def validator_active?(validator)
    if_cond = validator.options[:if]
    unless_cond = validator.options[:unless]
    (if_cond.nil? || evaluate_condition(if_cond)) &&
      (unless_cond.nil? || !evaluate_condition(unless_cond))
  end

  def evaluate_condition(condition)
    case condition
    when Symbol then object.send(condition)
    when Proc then object.instance_exec(&condition)
    else true
    end
  end

  def error_message_for(name)
    return unless object.errors[name].any?

    @template.content_tag(:p, object.errors[name].first,
                          class: "mt-1 text-xs font-medium text-red-600 animate-in fade-in slide-in-from-top-1")
  end
end
