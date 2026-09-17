require "test_helper"

class MagicLinkAuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    ActionMailer::Base.deliveries.clear
    @user = User.create!(email: "person@example.com")
  end

  test "magic link request has the same response for known and unknown emails" do
    post api_auth_magic_links_url, params: { email: @user.email }, as: :json
    known_response = response.parsed_body

    post api_auth_magic_links_url, params: { email: "unknown@example.com" }, as: :json
    unknown_response = response.parsed_body

    assert_response :accepted
    assert_equal known_response, unknown_response
    assert_equal "If an account exists, a magic link has been sent.", known_response["message"]
  end

  test "valid magic link authenticates the user and is single use" do
    post api_auth_magic_links_url, params: { email: @user.email }, as: :json
    token = token_from_last_email

    assert_not_includes response.body, token
    get api_auth_magic_link_url(token: token), as: :json

    assert_response :success
    assert_equal @user.email, response.parsed_body.dig("user", "email")

    get api_auth_session_url, as: :json
    assert_response :success
    assert_equal @user.id, response.parsed_body.dig("user", "id")

    get api_auth_magic_link_url(token: token), as: :json
    assert_response :unauthorized
  end

  test "invalid and expired magic links are rejected" do
    get api_auth_magic_link_url(token: "invalid-token"), as: :json

    assert_response :unauthorized

    token = @user.issue_magic_link!
    @user.update!(magic_link_expires_at: 1.minute.ago)
    get api_auth_magic_link_url(token: token), as: :json

    assert_response :unauthorized
  end

  test "current user and logout require and invalidate the session" do
    get api_auth_session_url, as: :json
    assert_response :unauthorized

    token = @user.issue_magic_link!
    get api_auth_magic_link_url(token: token), as: :json
    assert_response :success

    delete api_auth_session_url, as: :json
    assert_response :no_content

    get api_auth_session_url, as: :json
    assert_response :unauthorized
  end

  private

  def token_from_last_email
    email = ActionMailer::Base.deliveries.last
    body = email.parts.map(&:decoded).join("\n")
    body.match(%r{/api/auth/magic_links/([A-Za-z0-9_-]+)})[1]
  end
end
