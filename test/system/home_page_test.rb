require "application_system_test_case"

class HomePageTest < ApplicationSystemTestCase
  test "visiting root shows Newsprint heading" do
    visit root_path
    assert_text "Newsprint"
  end

  test "page has Connect Gmail link" do
    visit root_path
    assert_link "Connect Gmail"
  end
end
