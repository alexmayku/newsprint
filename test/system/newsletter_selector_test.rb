require "application_system_test_case"

class NewsletterSelectorTest < ApplicationSystemTestCase
  setup do
    @user = users(:sarah)

    # Clear existing newsletters for clean state
    @user.newsletters.destroy_all

    @n1 = Newsletter.create!(user: @user, sender_email: "n1@example.com",
                             title: "Alpha Weekly", est_pages: 10, latest_issue_date: Time.current)
    @n2 = Newsletter.create!(user: @user, sender_email: "n2@example.com",
                             title: "Beta Digest", est_pages: 15, latest_issue_date: Time.current)
    @n3 = Newsletter.create!(user: @user, sender_email: "n3@example.com",
                             title: "Gamma Report", est_pages: 12, latest_issue_date: Time.current)

    # Log in
    visit "/auth/google_oauth2/callback"
  end

  def toggle(title)
    find("input[aria-label='Select #{title}']").click
  end

  test "all 3 newsletters are visible with titles and page counts" do
    visit newsletters_path
    assert_text "Alpha Weekly"
    assert_text "Beta Digest"
    assert_text "Gamma Report"
    assert_text "10 pages"
    assert_text "15 pages"
    assert_text "12 pages"
  end

  test "toggling newsletters updates page counter" do
    visit newsletters_path

    assert_selector "[data-testid='page-counter']", text: "0 / 32"

    toggle("Alpha Weekly")
    assert_selector "[data-testid='page-counter']", text: "10 / 32"

    toggle("Beta Digest")
    assert_selector "[data-testid='page-counter']", text: "25 / 32"
  end

  test "exceeding page limit shows warning and disables generate button" do
    visit newsletters_path

    toggle("Alpha Weekly")
    toggle("Beta Digest")
    toggle("Gamma Report")

    assert_selector "[data-testid='page-counter']", text: "37 / 32"
    assert_selector "[data-testid='warning']", text: "Page limit exceeded"
    assert_selector "[data-testid='generate-btn'][disabled]"
  end

  test "deselecting brings under limit and enables generate button" do
    visit newsletters_path

    toggle("Alpha Weekly")
    toggle("Beta Digest")
    toggle("Gamma Report")

    assert_selector "[data-testid='warning']"

    toggle("Gamma Report")

    assert_no_selector "[data-testid='warning']"
    assert_selector "[data-testid='page-counter']", text: "25 / 32"
    assert_selector "[data-testid='generate-btn']:not([disabled])"
  end

  test "generate button is disabled when nothing selected" do
    visit newsletters_path
    assert_selector "[data-testid='generate-btn'][disabled]"
  end

  test "clicking generate newspaper posts to /newspapers" do
    visit newsletters_path

    toggle("Alpha Weekly")
    click_button "Generate Newspaper"

    # After POST, should redirect back to newsletters
    assert_current_path newsletters_path
  end

  test "Scan Inbox button is visible" do
    visit newsletters_path
    assert_selector "[data-testid='scan-btn']", text: "Scan Inbox"
  end
end
