require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "renders the Vue application mount point" do
    get root_url

    assert_response :success
    assert_select "main#app"
  end

  test "health endpoint responds successfully" do
    get rails_health_check_url

    assert_response :success
  end
end
