require "test_helper"
require "tmpdir"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1200 ] do |options|
    chrome_binary = ENV["CHROME_BINARY"] || %w[
      /usr/bin/google-chrome
      /usr/bin/chromium
      /usr/bin/chromium-browser
      /snap/bin/chromium
    ].find { |path| File.executable?(path) }
    options.binary = chrome_binary if chrome_binary
    #options.binary = "/snap/bin/chromium"
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--remote-debugging-port=0")
    options.add_argument("--user-data-dir=#{Dir.mktmpdir("notebook-calendar-chrome-")}")
  end
end
