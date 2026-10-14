defmodule Site.HtmlTest do
  use ExUnit.Case, async: true

  alias Site.Html

  describe "escape/1" do
    test "escapes ampersands" do
      assert Html.escape("R&D") == "R&amp;D"
    end

    test "escapes angle brackets" do
      assert Html.escape("<b>") == "&lt;b&gt;"
    end

    test "escapes double quotes" do
      assert Html.escape(~s("x")) == "&quot;x&quot;"
    end

    test "escapes single quotes" do
      assert Html.escape("Amex's") == "Amex&#x27;s"
    end

    test "accepts non-strings" do
      assert Html.escape(2014) == "2014"
    end
  end

  describe "strip_whitespace_between_tags/1" do
    test "removes whitespace between tags" do
      assert Html.strip_whitespace_between_tags("<p>\n  <span>a</span>\n</p>") ==
               "<p><span>a</span></p>"
    end

    test "keeps text between tags" do
      assert Html.strip_whitespace_between_tags("<a>x</a> · <a>y</a>") == "<a>x</a> · <a>y</a>"
    end
  end
end
