class NewsletterDetector
  KNOWN_PLATFORMS = {
    "substack.com" => :substack,
    "beehiiv.com" => :beehiiv,
    "mailchimp.com" => :mailchimp,
    "convertkit.com" => :convertkit,
    "buttondown.email" => :buttondown
  }.freeze

  NEWSLETTER_NAME_PATTERN = /newsletter|digest|weekly|daily/i

  DEFAULT_THRESHOLD = 0.7

  def initialize(messages)
    @messages = messages
  end

  def detect(threshold: DEFAULT_THRESHOLD)
    grouped = @messages.group_by { |m| m[:from_email] }

    results = grouped.map do |email, msgs|
      score_sender(email, msgs)
    end

    results
      .select { |r| r[:confidence] >= threshold }
      .sort_by { |r| -r[:confidence] }
  end

  private

  def score_sender(email, msgs)
    confidence = 0.0

    confidence += 0.4 if has_unsubscribe?(msgs)
    confidence += 0.3 if (platform = detect_platform(email))
    confidence += 0.2 if msgs.size >= 3
    confidence += 0.1 if NEWSLETTER_NAME_PATTERN.match?(msgs.first[:from_name].to_s)

    confidence = [ confidence, 1.0 ].min

    {
      sender_email: email,
      sender_name: msgs.first[:from_name],
      confidence: confidence,
      platform: platform,
      latest_date: msgs.map { |m| m[:date] }.max,
      message_count: msgs.size
    }
  end

  def has_unsubscribe?(msgs)
    msgs.any? { |m| m[:headers]&.key?("List-Unsubscribe") }
  end

  def detect_platform(email)
    domain = email.split("@").last.downcase
    KNOWN_PLATFORMS.each do |platform_domain, name|
      return name if domain == platform_domain || domain.end_with?(".#{platform_domain}")
    end
    nil
  end
end
