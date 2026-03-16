require "application_system_test_case"

class HomePageTest < ApplicationSystemTestCase
  test "visiting root shows Newsprint heading" do
    visit root_path
    assert_text "Newsprint"
  end

  test "page has Connect Gmail button" do
    visit root_path
    assert_button "Connect Gmail"
  end

  test "Connect Gmail button is inside a POST form" do
    visit root_path
    form = find("form[action='/auth/google_oauth2']")
    assert_equal "post", form[:method]
  end
end
