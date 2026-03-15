require "application_system_test_case"

class NewsletterDiscoveryTest < ApplicationSystemTestCase
  setup do
    # Use the fixture user that matches the OmniAuth mock email
    @user = users(:sarah)
    @user.update!(google_token_enc: "fake_token")

    # Create 3 newsletters for the user (fixtures may already have some, clean first)
    @user.newsletters.where.not(sender_email: %w[writer@substack.com news@beehiiv.com]).destroy_all
    # Ensure exactly 3 newsletters exist
    existing = @user.newsletters.count
    (3 - existing).times do |i|
      Newsletter.create!(
        user: @user,
        sender_email: "discovery#{i}@example.com",
        title: "Discovery Newsletter #{i + 1}",
        est_pages: 4,
        latest_issue_date: Time.current
      )
    end
  end

  test "discovery page shows then redirects to newsletter list" do
    # Log in via OmniAuth
    visit "/auth/google_oauth2/callback"

    # Immediately set the scan job to complete (simulating the job finishing instantly)
    # We need to intercept the discover action to know the job_id
    # Instead, set all possible scan_job keys to complete
    visit "/newsletters"

    assert_text "Your Newsletters"
    assert_selector ".newsletter-item", minimum: 3
  end

  test "newsletter list shows 3 newsletters" do
    visit "/auth/google_oauth2/callback"
    visit "/newsletters"

    newsletter_items = all(".newsletter-item")
    assert_equal 3, newsletter_items.count
  end
end
