require "test_helper"

class PriceFormattableTest < ActiveSupport::TestCase
  class Dummy
    include PriceFormattable
    def call(...) = format_price(...)
  end

  setup { @f = Dummy.new }

  test "very wide range collapses to 'from min'" do
    I18n.with_locale(:en) do
      assert_equal "from 500 UAH / послуга", @f.call(500, 5000, "UAH", unit: "послуга")
    end
  end

  test "moderate range is shown as a range" do
    I18n.with_locale(:en) do
      assert_equal "200–800 UAH / послуга", @f.call(200, 800, "UAH", unit: "послуга")
    end
  end

  test "equal min and max shows a single price" do
    assert_equal "300 UAH", @f.call(300, 300, "UAH")
  end

  test "only min present shows 'from'" do
    I18n.with_locale(:en) do
      assert_equal "from 300 UAH", @f.call(300, nil, "UAH")
    end
  end

  test "blank prices show on request" do
    I18n.with_locale(:en) do
      assert_equal "Price on request", @f.call(nil, nil, "UAH")
    end
  end
end
