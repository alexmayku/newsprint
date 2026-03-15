require "application_system_test_case"

class NewspaperPreviewTest < ApplicationSystemTestCase
  setup do
    @user = users(:sarah)
    @newsletter = newsletters(:substack_one)

    @newspaper = Newspaper.create!(user: @user, newsletters: [ @newsletter ])
    @newspaper.update!(status: :generated, page_count: 12, generated_at: Time.current)

    # Attach a dummy PDF
    @newspaper.pdf.attach(
      io: StringIO.new("%PDF-1.4 test content"),
      filename: "test.pdf",
      content_type: "application/pdf"
    )

    # Log in
    visit "/auth/google_oauth2/callback"
  end

  test "preview page shows newspaper title and edition number" do
    visit preview_newspaper_path(@newspaper)
    assert_text @newspaper.title
    assert_text "Edition #{@newspaper.edition_number}"
  end

  test "preview page shows page count" do
    visit preview_newspaper_path(@newspaper)
    assert_text "12 pages"
  end

  test "Purchase button is present and links correctly" do
    visit preview_newspaper_path(@newspaper)
    purchase_link = find("[data-testid='purchase-btn']")
    assert_includes purchase_link[:href], "/orders/new?newspaper_id=#{@newspaper.id}"
  end

  test "Back to Selector button is present" do
    visit preview_newspaper_path(@newspaper)
    back_link = find("[data-testid='back-btn']")
    assert_includes back_link[:href], "/newsletters"
  end
end
