require "test_helper"

class HealthCheckTest < ActionDispatch::IntegrationTest
  test "health check reports that the application is running" do
    get rails_health_check_url

    assert_response :success
  end
end
