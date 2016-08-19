require 'rspec'
require 'capybara'
require 'capybara/rspec'
require 'selenium-webdriver'
require 'capybara/dsl'
require 'browsermob/proxy'
require 'socket'

class TestDriverManager
  def self.run_with(driver, user_agent = '', geo_ip = '')
    if driver == :webkit
      config_rspec_with_webkit(user_agent, geo_ip)
    else
      config_rspec_with_selenium(driver, user_agent, geo_ip)
    end
  end

  def self.config_rspec_with_webkit(user_agent = '', geo_ip = '')
    require 'capybara-webkit'
    require 'capybara/webkit/connection'
    require 'capybara/webkit/browser'

    RSpec.configure do |config|
      connection = Capybara::Webkit::Connection.new
      config.before :all do
        Capybara.register_driver :webkit do |app|
          browser = Capybara::Webkit::Browser.new(connection)
          browser.timeout = 600
          browser.url_blacklist = ['https://www.facebook.com', 'http://www.facebook.com']
          browser.ignore_ssl_errors
          browser.header('user-agent', user_agent) unless user_agent.empty?

          unless geo_ip.empty?
            browser.header('X-Forwarded-For', geo_ip['X-Forwarded-For'])
            browser.header('X-LF-ATG-XFF', geo_ip['X-LF-ATG-XFF'])
          end

          Capybara::Webkit::Driver.new(app, browser: browser)
        end

        Capybara.javascript_driver = :webkit
        Capybara.default_driver = :webkit
        Capybara.default_wait_time = 10
      end

      config.after :all do
        TestDriverManager.kill_webkit_server(connection.pid)
      end
    end
  end

  def self.start_proxy
    # Start server
    server_port = available_port
    server = BrowserMob::Proxy::Server.new("#{File.expand_path File.dirname(__FILE__)}/browsermob-proxy/bin/browsermob-proxy.bat", port: server_port, log: true)
    server.start

    # Start proxy
    proxy_port = available_port
    proxy = server.create_proxy proxy_port
    proxy
  end

  def self.web_proxy(headers = {})
    proxy = start_proxy
    proxy.header headers unless headers.empty?
    proxy
  rescue # Handle if Port is already used
    proxy = start_proxy
    proxy.header headers unless headers.empty?
    proxy
  end

  def self.available_port
    (10_000..65_000).each do |port|
      return port if port_available? port
    end
  end

  def self.port_available?(port)
    TCPSocket.new('127.0.0.1', port).close
    false
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError
    true
  end

  def self.config_rspec_with_selenium(driver = :firefox, user_agent = '', geo_ip = '')
    file_path = File.expand_path File.dirname(__FILE__)

    RSpec.configure do |config|
      config.before :all do
        case driver
        when :internet_explorer
          Selenium::WebDriver::IE.driver_path = "#{file_path}/IEDriverServer_2_53_1.exe"
        when :chrome
          Selenium::WebDriver::Chrome::Service.executable_path = "#{file_path}/chromedriver_2_22.exe"
        end

        Capybara.register_driver :selenium do |app|
          client = Selenium::WebDriver::Remote::Http::Default.new
          client.timeout = TimeOut::READ_TIMEOUT_CONST

          if user_agent.empty?
            if geo_ip.empty?
              Capybara::Selenium::Driver.new(app, browser: driver, http_client: client)
            else # Using proxy and rewrite header for special locale
              proxy = TestDriverManager.web_proxy('X-Forwarded-For' => geo_ip['X-Forwarded-For'], 'X-LF-ATG-XFF' => geo_ip['X-LF-ATG-XFF'])

              case driver
              when :firefox # Setting up Capabilities for each webdriver
                driver_proxy = Selenium::WebDriver::Remote::Capabilities.firefox
              when :chrome
                driver_proxy = Selenium::WebDriver::Remote::Capabilities.chrome
              else
                driver_proxy = Selenium::WebDriver::Remote::Capabilities.internet_explorer
              end
              # Apply ssl proxy for selenium webdriver
              driver_proxy.proxy = proxy.selenium_proxy(:http, :ssl)
              Capybara::Selenium::Driver.new(app, browser: driver, http_client: client, desired_capabilities: driver_proxy)
            end
          else # Override User-Agent
            proxy = ''
            unless geo_ip.empty? # Initialize proxy and rewrite header
              proxy = TestDriverManager.web_proxy('X-Forwarded-For' => geo_ip['X-Forwarded-For'], 'X-LF-ATG-XFF' => geo_ip['X-LF-ATG-XFF'])
            end

            case driver # Setting up user_agent and proxy for each webdriver
            when :firefox
              profile = Selenium::WebDriver::Firefox::Profile.new
              profile['general.useragent.override'] = user_agent

              if geo_ip.empty?
                Capybara::Selenium::Driver.new(app, browser: driver, http_client: client, profile: profile)
              else
                driver_proxy = Selenium::WebDriver::Remote::Capabilities.firefox
                driver_proxy.proxy = proxy.selenium_proxy(:http, :ssl)
                Capybara::Selenium::Driver.new(app, browser: driver, http_client: client, profile: profile, desired_capabilities: driver_proxy)
              end
            when :chrome
              if geo_ip.empty?
                Capybara::Selenium::Driver.new(app, browser: driver, http_client: client, switches: %W[--user-agent=#{user_agent.gsub(/ /, '\ ')}])
              else
                driver_proxy = Selenium::WebDriver::Remote::Capabilities.chrome
                driver_proxy.proxy = proxy.selenium_proxy(:http, :ssl)
                Capybara::Selenium::Driver.new(app, browser: driver, http_client: client, desired_capabilities: driver_proxy, switches: %W[--user-agent=#{user_agent.gsub(/ /, '\ ')}])
              end
            else # The IE driver does not support changing the user agent, using capabilities or otherwise
              if geo_ip.empty?
                Capybara::Selenium::Driver.new(app, browser: driver, http_client: client)
              else
                driver_proxy = Selenium::WebDriver::Remote::Capabilities.internet_explorer
                driver_proxy.proxy = proxy.selenium_proxy(:http, :ssl)
                Capybara::Selenium::Driver.new(app, browser: driver, http_client: client, desired_capabilities: driver_proxy)
              end
            end
          end
        end

        Capybara.javascript_driver = :selenium
        Capybara.default_driver = :selenium
        Capybara.default_wait_time = TimeOut::WAIT_CONTROL_CONST
        browser = Capybara.current_session.driver.browser
        browser.manage.delete_all_cookies
        browser.manage.window.maximize
      end
    end
  end

  def self.delete_cookies
    browser = Capybara.current_session.driver.browser
    browser.manage.delete_all_cookies
  end

  def self.kill_webkit_server(pid)
    if Capybara.current_driver == :webkit
      Process.detach(pid)
      Process.kill('KILL', pid)
    end
  end

  def self.session_id
    begin
      if Capybara.default_driver == :webkit
        sessionid = page.driver.cookies['JSESSIONID']
      else
        cookies = Capybara.current_session.driver.browser.manage.all_cookies
        cookies.each do |cookie|
          sessionid = cookie[:value] if cookie[:name] == 'JSESSIONID'
        end
      end
    rescue => e
      sessionid = e.message
    end

    sessionid
  end
end
