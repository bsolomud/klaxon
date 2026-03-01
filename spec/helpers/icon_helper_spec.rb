require "rails_helper"

RSpec.describe IconHelper, type: :helper do
  describe "#heroicon" do
    it "returns the SVG content for a valid icon" do
      result = helper.heroicon("x-mark")
      expect(result).to include("<svg")
      expect(result).to include("</svg>")
      expect(result).to include("currentColor")
    end

    it "adds a CSS class when provided" do
      result = helper.heroicon("x-mark", class: "h-4 w-4")
      expect(result).to include('class="h-4 w-4"')
    end

    it "uses the 20-solid variant by default" do
      result = helper.heroicon("x-mark")
      expect(result).to include('viewBox="0 0 20 20"')
    end

    it "includes aria-hidden by default" do
      result = helper.heroicon("x-mark")
      expect(result).to include('aria-hidden="true"')
    end

    it "replaces aria-hidden with aria-label when provided" do
      result = helper.heroicon("x-mark", aria_label: "Close")
      expect(result).to include('aria-label="Close"')
      expect(result).not_to include('aria-hidden="true"')
    end

    it "escapes HTML in aria_label" do
      result = helper.heroicon("x-mark", aria_label: '<script>alert("xss")</script>')
      expect(result).not_to include("<script>")
      expect(result).to include("&lt;script&gt;")
    end

    it "escapes HTML in CSS class" do
      result = helper.heroicon("x-mark", class: '"><script>')
      expect(result).not_to include("<script>")
    end

    it "raises ArgumentError for a non-existent icon" do
      expect { helper.heroicon("nonexistent-icon") }.to raise_error(ArgumentError, /Icon not found/)
    end

    it "returns html_safe content" do
      result = helper.heroicon("x-mark")
      expect(result).to be_html_safe
    end
  end
end
