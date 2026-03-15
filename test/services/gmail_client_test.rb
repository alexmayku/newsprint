require "test_helper"
require "google/apis/gmail_v1"

class GmailClientTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "gmail-test@example.com", google_token_enc: "fake_refresh_token")
    @client = GmailClient.new(@user)

    @list_json = JSON.parse(file_fixture("gmail_api/messages_list.json").read)
    @detail_json = JSON.parse(file_fixture("gmail_api/message_detail.json").read)
    @no_unsub_json = JSON.parse(file_fixture("gmail_api/message_no_unsubscribe.json").read)
  end

  test "initializes without error for a user with google_token_enc" do
    assert_instance_of GmailClient, @client
  end

  test "fetch_messages returns an array of message ID hashes" do
    list_response = Google::Apis::GmailV1::ListMessagesResponse.new(
      messages: @list_json["messages"].map { |m| Google::Apis::GmailV1::Message.new(id: m["id"]) },
      result_size_estimate: 2
    )
    mock_service(:list_user_messages, list_response)
    result = @client.fetch_messages(query: "newer_than:30d", max_results: 100)
    assert_kind_of Array, result
    assert_equal 2, result.size
    assert_equal "msg_1", result.first[:id]
  end

  test "fetch_message_detail returns a hash with expected keys" do
    message = build_gmail_message(@detail_json)
    mock_service(:get_user_message, message)
    result = @client.fetch_message_detail("msg_1")
    assert_equal "msg_1", result[:id]
    assert_equal "Weekly Digest #42", result[:subject]
    assert_equal "writer@substack.com", result[:from_email]
    assert_equal "Writer Name", result[:from_name]
    assert_instance_of Time, result[:date]
    assert_includes result[:html_body], "<h1>Hello Newsletter</h1>"
    assert_kind_of Hash, result[:headers]
  end

  test "correctly extracts List-Unsubscribe header when present" do
    message = build_gmail_message(@detail_json)
    mock_service(:get_user_message, message)
    result = @client.fetch_message_detail("msg_1")
    assert_equal "<https://example.com/unsubscribe>", result[:headers]["List-Unsubscribe"]
  end

  test "correctly handles message without List-Unsubscribe" do
    message = build_gmail_message(@no_unsub_json)
    mock_service(:get_user_message, message)
    result = @client.fetch_message_detail("msg_2")
    assert_nil result[:headers]["List-Unsubscribe"]
  end

  test "html_body is correctly decoded from base64url" do
    message = build_gmail_message(@detail_json)
    mock_service(:get_user_message, message)
    result = @client.fetch_message_detail("msg_1")
    assert_equal "<h1>Hello Newsletter</h1><p>This is the body.</p>", result[:html_body]
  end

  test "raises GmailClient::ApiError when the API call fails" do
    service = @client.service
    service.define_singleton_method(:get_user_message) do |*_args|
      raise Google::Apis::ClientError.new("forbidden")
    end
    assert_raises(GmailClient::ApiError) do
      @client.fetch_message_detail("msg_1")
    end
  end

  private

  def mock_service(method_name, return_value)
    @client.service.define_singleton_method(method_name) { |*_args| return_value }
  end

  def build_gmail_message(json)
    payload = json["payload"]
    headers = payload["headers"].map do |h|
      Google::Apis::GmailV1::MessagePartHeader.new(name: h["name"], value: h["value"])
    end
    parts = payload["parts"].map do |p|
      Google::Apis::GmailV1::MessagePart.new(
        mime_type: p["mimeType"],
        body: Google::Apis::GmailV1::MessagePartBody.new(data: p["body"]["data"])
      )
    end
    Google::Apis::GmailV1::Message.new(
      id: json["id"],
      payload: Google::Apis::GmailV1::MessagePart.new(
        mime_type: payload["mimeType"],
        headers: headers,
        parts: parts
      )
    )
  end
end
