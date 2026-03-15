require "google/apis/gmail_v1"

class GmailClient
  class ApiError < StandardError; end

  attr_reader :service

  def initialize(user)
    @user = user
    @service = Google::Apis::GmailV1::GmailService.new
    @service.authorization = build_credentials
  end

  def fetch_messages(query:, max_results: 100)
    response = @service.list_user_messages("me", q: query, max_results: max_results)
    return [] unless response.messages

    response.messages.map { |m| { id: m.id } }
  rescue Google::Apis::Error => e
    raise ApiError, e.message
  end

  def fetch_message_detail(message_id)
    message = @service.get_user_message("me", message_id, format: "full")
    parse_message(message)
  rescue Google::Apis::Error => e
    raise ApiError, e.message
  end

  private

  def build_credentials
    Google::Auth::UserRefreshCredentials.new(
      client_id: ENV["GOOGLE_CLIENT_ID"],
      client_secret: ENV["GOOGLE_CLIENT_SECRET"],
      refresh_token: @user.google_token_enc,
      scope: "https://www.googleapis.com/auth/gmail.readonly"
    )
  end

  def parse_message(message)
    headers = extract_headers(message.payload.headers)
    from_name, from_email = parse_from(headers["From"])

    {
      id: message.id,
      subject: headers["Subject"],
      from_email: from_email,
      from_name: from_name,
      date: Time.parse(headers["Date"]),
      html_body: extract_html_body(message.payload),
      headers: headers
    }
  end

  def extract_headers(headers)
    headers.each_with_object({}) { |h, hash| hash[h.name] = h.value }
  end

  def parse_from(from_string)
    if from_string =~ /\A(.+?)\s*<(.+?)>\z/
      [ $1.strip, $2.strip ]
    else
      [ nil, from_string ]
    end
  end

  def extract_html_body(payload)
    part = find_html_part(payload)
    return nil unless part&.body&.data

    Base64.urlsafe_decode64(part.body.data).force_encoding("UTF-8")
  end

  def find_html_part(part)
    return part if part.mime_type == "text/html"
    return nil unless part.parts

    part.parts.each do |p|
      found = find_html_part(p)
      return found if found
    end
    nil
  end
end
