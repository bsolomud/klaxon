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

  # Кастомний метод для Чекбоксів (Input зліва, Label справа)
  # def check_box(name, options = {}, checked_value = "1", unchecked_value = "0")
  #   error_class = object.errors[name].any? ? "ring-2 ring-red-500 ring-offset-2" : ""
  #   options[:class] = Array(options[:class]).join(" ") + " #{error_class}"
  #
  #   @template.content_tag(:div, class: "mb-2") do
  #     @template.content_tag(:div, class: "flex items-center") do
  #       super(name, options, checked_value, unchecked_value) +
  #         label(name, options[:label_text], class: "ml-2 text-sm text-gray-700")
  #     end + error_message_for(name)
  #   end
  # end

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

  def error_message_for(name)
    return unless object.errors[name].any?

    @template.content_tag(:p, object.errors[name].first,
                          class: "mt-1 text-xs font-medium text-red-600 animate-in fade-in slide-in-from-top-1")
  end
end
