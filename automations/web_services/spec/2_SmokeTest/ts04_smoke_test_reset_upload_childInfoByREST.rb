require File.expand_path('../../spec_helper', __FILE__)
require 'authentication'
require 'child_management'
require 'learning_path/child_management'
require 'customer_management'
require 'child_management'
require 'device_profile_content'
require 'device_log_upload'
require 'child_management'

=begin
Smoke test: reset, upload function by using REST
=end

describe "TestSuite 04 - Smoke test 04 - #{Misc::CONST_ENV}" do
  caller_id = 'a023bc85-db5b-40b5-934c-28a72b4d9547'
  device_serial = 'L3xyz123321xyz27845298426'
  username = email = 'ltrc_1216213_qa@leapfrog.test'
  password = LFCommon.get_current_time
  screen_name = ''
  customer_id = '2842123'
  session = child_id = nil

  filename = 'Stretchy monkey.log'
  content_path = "#{Misc::CONST_PROJECT_PATH}/data/Log2.xml"

  context 'Test Case 01 - Precondition get session' do
    CustomerManagement.update_customer(caller_id, customer_id, username, email, password, screen_name)
    session = Authentication.get_service_session(caller_id, username, password)

    it 'Check for existence of [session]' do
      expect(session).not_to be_empty
    end
  end

  context 'Test Case 02 - Get Child Information' do
    xml_list_child = ChildManagement.list_children(caller_id, session, customer_id)
    child_id = xml_list_child.xpath('//child[1]/@id').text

    xml_fetch_child = ChildManagement.fetch_child(caller_id, session, child_id)

    it 'Match content of [@id]' do
      expect(xml_fetch_child.xpath('//child/@id').text).to eq(child_id)
    end

    it 'Check for existence of [@dob]' do
      expect(xml_fetch_child.xpath('//child/@dob').text).not_to be_empty
    end

    it 'Check for existence of [@name]' do
      expect(xml_fetch_child.xpath('//child/@name').text).not_to be_empty
    end

    it 'Check for existence of [@grade]' do
      expect(xml_fetch_child.xpath('//child/@grade').text).not_to be_empty
    end
  end

  context 'Test Case 03 - Reset Password' do
    xml_fetch_cus1 = CustomerManagement.fetch_customer(caller_id, customer_id)
    CustomerManagement.reset_password(caller_id, username)
    xml_fetch_cus2 = CustomerManagement.fetch_customer(caller_id, customer_id)
    session = Authentication.get_service_session(caller_id, username, password)

    it "Check 'password-temporary' before resetting password" do
      expect(xml_fetch_cus1.xpath('//customer/credentials/@password-temporary').text).to eq('false')
    end

    it "Check 'password-temporary' after resetting password" do
      expect(xml_fetch_cus2.xpath('//customer/credentials/@password-temporary').text).to eq('true')
    end

    it 'Check for existence of [session]' do
      expect(session).not_to be_empty
    end
  end

  context 'Test Case 04 - Upload Logs' do
    rio_log_info = { caller_id: caller_id, session: session, device_serial: device_serial, child_id: child_id, file_name: filename, content_path: content_path, slot: '0' }

    upload_logs rio_log_info, 'RIO'
  end

  context 'Test Case 05 - Use REST to get child information' do
    get_child_res = ChildManagementRest.fetch_child(Misc::CONST_REST_CALLER_ID, child_id, session)

    it 'Match content of [@childID]' do
      expect(get_child_res['data']['childID']).to eq(child_id)
    end

    it 'Match content of [@childName]' do
      expect(get_child_res['data']['childName']).to eq('RIOKid')
    end
  end
end
