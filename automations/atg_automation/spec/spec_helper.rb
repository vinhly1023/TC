$LOAD_PATH.unshift('automations/lib')
$LOAD_PATH.unshift('automations/atg_automation')
$LOAD_PATH.unshift('automations/atg_automation/pages/atg')
$LOAD_PATH.unshift('automations/atg_automation/pages/atg_content')
$LOAD_PATH.unshift('automations/atg_automation/pages/atg_dv')
$LOAD_PATH.unshift('automations/atg_automation/pages/csc')
$LOAD_PATH.unshift('automations/atg_automation/pages/vindicia')
$LOAD_PATH.unshift('automations/atg_automation/pages/mail')

require 'rails'
require 'json'
require 'nokogiri'
require 'connection'
require 'test_driver_manager'
require 'lib/const'
require 'lib/encode'
require 'lib/excelprocessing'
require 'lib/generate'
require 'lib/localesweep'
require 'lib/services'
require 'lib/soft_good_common_methods'
require 'lib/atg_dv_common'

module Capybara
  class << self
    alias_method :old_reset_sessions!, :reset_sessions!

    def reset_sessions!
    end
  end
end

# Get User agent
device_store = $atg_xml_data.search('//devices/device_store').text
device_store_info = JSON.parse(File.read("#{File.expand_path('..', File.dirname(__FILE__))}/data/device_store_urls.json"))[device_store]
user_agent = device_store_info.nil? ? '' : device_store_info['user_agent']

# Get GEO IP
locale = $atg_xml_data.search('//information/locale').text.presence || 'US'
geo_ip_info = JSON.parse(File.read("#{File.expand_path('..', File.dirname(__FILE__))}/data/geo_ips.json"))[locale]
geo_ip = geo_ip_info.nil? ? '' : geo_ip_info

case General::WEB_DRIVER_CONST
when 'FIREFOX'
  TestDriverManager.run_with(:firefox, user_agent, geo_ip)
when 'CHROME'
  TestDriverManager.run_with(:chrome, user_agent, geo_ip)
when 'IE'
  TestDriverManager.run_with(:internet_explorer, user_agent, geo_ip)
else
  TestDriverManager.run_with(:webkit, user_agent, geo_ip)
end

def app_exist?
  titles_count = Connection.my_sql_connection(AppCenterContent::CONST_QUERY_CHECK_APP_EXIST).count
  return true unless titles_count.zero?
  skip 'BLOCKED: No titles found in MOAS for this release'
  false
end

def app_available?(titles_count, message = 'There were no apps found in MOAS')
  return true unless titles_count.zero?

  it message do
  end

  false
end

def pin_available?(env, locale)
  code_env = (env.upcase == 'PROD') ? 'PROD' : 'QA'
  code_type = Title.locale_to_code_type locale
  pin = PinRedemption.get_pin_info(code_env, code_type, 'Available')

  return true unless pin.blank?

  skip "BLOCKED: There is no available #{code_env} Code for #{locale} locale. Please import code before running test case"
  false
end

def com_server(has_context = true)
  if has_context
    context 'COM Server Check' do
      com_server_scenario
    end
  else
    com_server_scenario
  end
end

def com_server_scenario
  scenario '' do
    begin
      com_server_str = page.evaluate_script("$('script').text().split('serverName')[1].split(',')[0].replace(/[': ]+/g, '');")
    rescue => e
      com_server_str = "Could not get COM server name, error: #{e.message}"
    end

    pending "***COM Server: #{com_server_str}"
  end
end
