require "test_helper"

class NewsletterDetectorTest < ActiveSupport::TestCase
  def make_message(from_email:, from_name: "Sender", date: Time.current, has_unsubscribe: false)
    headers = {}
    headers["List-Unsubscribe"] = "<https://example.com/unsub>" if has_unsubscribe
    { from_email: from_email, from_name: from_name, date: date, headers: headers }
  end

  def messages_from(email, count: 1, from_name: "Sender", has_unsubscribe: false)
    count.times.map do |i|
      make_message(from_email: email, from_name: from_name, date: i.days.ago, has_unsubscribe: has_unsubscribe)
    end
  end

  test "sender with List-Unsubscribe header scores >= 0.4" do
    msgs = [ make_message(from_email: "a@unknown.com", has_unsubscribe: true) ]
    detector = NewsletterDetector.new(msgs)
    results = detector.detect(threshold: 0.0)
    assert results.first[:confidence] >= 0.4
  end

  test "sender from substack.com domain scores >= 0.3" do
    msgs = [ make_message(from_email: "writer@substack.com") ]
    detector = NewsletterDetector.new(msgs)
    results = detector.detect(threshold: 0.0)
    assert results.first[:confidence] >= 0.3
  end

  test "sender from beehiiv.com scores >= 0.3" do
    msgs = [ make_message(from_email: "news@beehiiv.com") ]
    detector = NewsletterDetector.new(msgs)
    results = detector.detect(threshold: 0.0)
    assert results.first[:confidence] >= 0.3
  end

  test "sender from mailchimp.com scores >= 0.3" do
    msgs = [ make_message(from_email: "digest@mail.mailchimp.com") ]
    detector = NewsletterDetector.new(msgs)
    results = detector.detect(threshold: 0.0)
    assert results.first[:confidence] >= 0.3
  end

  test "sender from convertkit.com scores >= 0.3" do
    msgs = [ make_message(from_email: "author@convertkit.com") ]
    detector = NewsletterDetector.new(msgs)
    results = detector.detect(threshold: 0.0)
    assert results.first[:confidence] >= 0.3
  end

  test "sender from buttondown.email scores >= 0.3" do
    msgs = [ make_message(from_email: "writer@buttondown.email") ]
    detector = NewsletterDetector.new(msgs)
    results = detector.detect(threshold: 0.0)
    assert results.first[:confidence] >= 0.3
  end

  test "sender appearing 3+ times gets recurring bonus" do
    single = messages_from("a@unknown.com", count: 1)
    recurring = messages_from("a@unknown.com", count: 3)

    single_score = NewsletterDetector.new(single).detect(threshold: 0.0).first[:confidence]
    recurring_score = NewsletterDetector.new(recurring).detect(threshold: 0.0).first[:confidence]

    assert recurring_score >= single_score + 0.2
  end

  test "sender name matching newsletter pattern gets bonus" do
    msgs = [ make_message(from_email: "a@unknown.com", from_name: "Weekly Newsletter") ]
    detector = NewsletterDetector.new(msgs)
    results = detector.detect(threshold: 0.0)

    plain = [ make_message(from_email: "b@unknown.com", from_name: "John") ]
    plain_score = NewsletterDetector.new(plain).detect(threshold: 0.0).first[:confidence]

    assert results.first[:confidence] >= plain_score + 0.1
  end

  test "List-Unsubscribe + known platform + recurring = high confidence >= 0.7" do
    msgs = messages_from("writer@substack.com", count: 4, has_unsubscribe: true)
    detector = NewsletterDetector.new(msgs)
    results = detector.detect(threshold: 0.0)
    assert results.first[:confidence] >= 0.7
  end

  test "single email from unknown domain without List-Unsubscribe scores < 0.7" do
    msgs = [ make_message(from_email: "random@unknown.com") ]
    detector = NewsletterDetector.new(msgs)
    results = detector.detect(threshold: 0.0)
    assert results.first[:confidence] < 0.7
  end

  test "results are sorted by confidence descending" do
    msgs = messages_from("high@substack.com", count: 5, has_unsubscribe: true) +
           messages_from("low@unknown.com", count: 1)
    detector = NewsletterDetector.new(msgs)
    results = detector.detect(threshold: 0.0)
    confidences = results.map { |r| r[:confidence] }
    assert_equal confidences, confidences.sort.reverse
  end

  test "each result has required keys" do
    msgs = messages_from("writer@substack.com", count: 2, from_name: "Writer", has_unsubscribe: true)
    detector = NewsletterDetector.new(msgs)
    result = detector.detect(threshold: 0.0).first
    assert_equal "writer@substack.com", result[:sender_email]
    assert_equal "Writer", result[:sender_name]
    assert_kind_of Float, result[:confidence]
    assert_not_nil result[:platform]
    assert_not_nil result[:latest_date]
    assert_equal 2, result[:message_count]
  end

  test "threshold is configurable with default 0.7" do
    msgs = [ make_message(from_email: "low@unknown.com") ]
    detector = NewsletterDetector.new(msgs)

    default_results = detector.detect
    assert default_results.empty?

    low_results = detector.detect(threshold: 0.0)
    assert_not low_results.empty?
  end

  test "scores are capped at 1.0" do
    msgs = messages_from("writer@substack.com", count: 10, from_name: "Daily Newsletter Digest", has_unsubscribe: true)
    detector = NewsletterDetector.new(msgs)
    results = detector.detect(threshold: 0.0)
    assert results.first[:confidence] <= 1.0
  end
end
