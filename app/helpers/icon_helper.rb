module IconHelper
  ICONS_PATH = Rails.root.join("app", "assets", "icons")

  def heroicon(name, variant: "20-solid", **options)
    css_class = options.delete(:class)
    aria_label = options.delete(:aria_label)

    svg = read_icon("heroicons", variant, name)

    if aria_label
      svg = svg.sub('aria-hidden="true"', "")
      svg = svg.sub("<svg ", "<svg aria-label=\"#{ERB::Util.html_escape(aria_label)}\" ")
    end

    svg = svg.sub("<svg ", "<svg class=\"#{ERB::Util.html_escape(css_class)}\" ") if css_class

    svg.html_safe # rubocop:disable Rails/OutputSafety
  end

  private

  def read_icon(library, variant, name)
    cache_key = "#{library}/#{variant}/#{name}"

    if Rails.env.production?
      icon_cache[cache_key] ||= load_icon(library, variant, name)
    else
      load_icon(library, variant, name)
    end
  end

  def load_icon(library, variant, name)
    path = ICONS_PATH.join(library, variant, "#{name}.svg")
    raise ArgumentError, "Icon not found: #{library}/#{variant}/#{name}" unless path.exist?

    path.read.strip
  end

  def icon_cache
    @icon_cache ||= {}
  end
end
