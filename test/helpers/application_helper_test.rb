require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "format_money shows whole amounts without decimals" do
    assert_equal "1700 UAH", format_money(1700, "UAH")
    assert_equal "1700 UAH", format_money(BigDecimal("1700.00"), "UAH")
  end

  test "format_money keeps kopiykas when present" do
    assert_equal "1700.50 UAH", format_money(BigDecimal("1700.50"), "UAH")
  end

  test "format_money handles zero" do
    assert_equal "0 UAH", format_money(0, "UAH")
  end
end
