require File.expand_path('../../spec_helper', __FILE__)
require 'authentication'
require 'child_management'
require 'customer_management'
require 'child_management'
require 'learning_path/child_management'
require 'device_management'
require 'owner_management'
require 'device_profile_management'
require 'device_log_upload'
require 'device_profile_content'
require 'pin_management'
require 'child_management'
require 'automation_common'

=begin
Smoke test: redeem, upload function by using REST
=end

start_browser

describe "TestSuite 03 - Smoke test 03 - #{Misc::CONST_ENV}" do
  env = Misc::CONST_ENV
  caller_id = 'a023bc85-db5b-40b5-934c-28a72b4d9547'
  device_serial1 = 'RIO' + DeviceManagement.generate_serial
  device_serial2 = 'LP2' + DeviceManagement.generate_serial
  device_serial3 = 'LR' + DeviceManagement.generate_serial
  username = email = LFCommon.generate_email
  screen_name = CustomerManagement.generate_screenname
  password = '123456'
  customer_id = session = nil
  rio_child_id = lp2_child_id = lr_child_id = nil
  rio_child_info = lp2_child_info = lr_child_info = nil

  filename = 'Stretchy monkey.log'
  content_path = "#{Misc::CONST_PROJECT_PATH}/data/Log2.xml"

  context 'Test Case 01 - Account Setup' do
    register_cus_res = CustomerManagement.register_customer(caller_id, screen_name, email, username)
    type1 = register_cus_res.xpath('//customer').attr('type').text
    username1 = register_cus_res.xpath('//customer/credentials').attr('username').text

    arr_register_cus_res = CustomerManagement.get_customer_info(register_cus_res)
    customer_id = arr_register_cus_res[:id]

    xml_acquire_session_res = Authentication.acquire_service_session(caller_id, username, password)
    session = xml_acquire_session_res.xpath('//session').text

    it 'Match content of [@type]' do
      expect(type1).to eq('Registered')
    end

    it 'Match content of [@username]' do
      expect(username1).to eq(username)
    end

    it 'Check for existence of [session]' do
      expect(session).not_to be_empty
    end
  end

  context 'Test Case 02 - Register Child' do
    # create RIO, LP2 and LR children
    rio_child_info = { caller_id: caller_id, session: session, customer_id: customer_id, child_name: 'RIO', gender: 'male', grade: '5' }
    lp2_child_info = { caller_id: caller_id, session: session, customer_id: customer_id, child_name: 'LP2', gender: 'female', grade: '1' }
    lr_child_info = { caller_id: caller_id, session: session, customer_id: customer_id, child_name: 'LR', gender: 'male', grade: '2' }

    rio_child_id = create_child rio_child_info
    lp2_child_id = create_child lp2_child_info
    lr_child_id = create_child lr_child_info
  end

  context 'Test Case 03 - Get Child Information' do
    fetch_and_verify_child_info(rio_child_info, rio_child_id)
    fetch_and_verify_child_info(lp2_child_info, lp2_child_id)
    fetch_and_verify_child_info(lr_child_info, lr_child_id)
  end

  context 'Test Case 04 - Claim Devices' do
    # Step 1: Claim RIO, LP2 and LR devices
    rio_device_info = { caller_id: caller_id, session: session, customer_id: customer_id, device_serial: device_serial1, platform: 'leappad3', slot: '0', child_name: 'RIO', index: '1' }
    lp2_device_info = { caller_id: caller_id, session: session, customer_id: customer_id, device_serial: device_serial2, platform: 'leappad2', slot: '0', child_name: 'LP2', index: '2' }
    lr_device_info = { caller_id: caller_id, session: session, customer_id: customer_id, device_serial: device_serial3, platform: 'leapreader', slot: '0', child_name: 'LR', index: '3' }

    link_device_to_account rio_device_info
    link_device_to_account lp2_device_info
    link_device_to_account lr_device_info

    # Step 2: Assign Device Profiles
    xml_assign_device = LFCommon.soap_call(
      LFSOAP::CONST_INMON_ENDPOINTS[:device_profile_management][:endpoint],
      LFSOAP::CONST_INMON_ENDPOINTS[:device_profile_management][:namespace],
      :assign_device_profile,
      "<device-profile device='#{device_serial1}' platform='leappad3' slot='0' name='RIO' child-id='#{rio_child_id}'/>
      <device-profile device='#{device_serial2}' platform='leappad2' slot='0' name='LP2' child-id='#{lp2_child_id}'/>
      <device-profile device='#{device_serial3}' platform='leapreader' slot='0' name='LR' child-id='#{lr_child_id}'/>
      <caller-id>#{caller_id}</caller-id>
      <username/>
      <customer-id>#{customer_id}</customer-id>"
    )

    soap_fault = xml_assign_device.xpath('//faultstring').count

    xml_get_device_profile = DeviceProfileManagement.list_device_profiles(caller_id, username, customer_id, '10', '10', '')
    profile_num = xml_get_device_profile.xpath('//device-profile').count

    it "Verify 'Assign Device Profiles' calls successfully" do
      expect(soap_fault).to eq(0)
    end

    it 'Check count of [device-profile]' do
      expect(profile_num).to eq(3)
    end
  end

  context 'Test Case 05 - Claim USV1 PIN' do
    status_code_redemption = pin_value = pin_status = pin_available = pin = nil

    before :all do
      # Make account known to vindica system
      LFCommon.new.login_to_lfcom(username, password)

      # Get available PIN
      pin_available = PinRedemption.get_pin_number(env, 'USV1', 'Available')
      pin = pin_available.delete('-')

      # Step 1: Redeem USV1 Code
      begin
        client = Savon.client(
          endpoint: LFSOAP::CONST_INMON_ENDPOINTS[:pin_management][:endpoint],
          namespace: LFSOAP::CONST_INMON_ENDPOINTS[:pin_management][:namespace],
          log: true,
          pretty_print_xml: true,
          namespace_identifier: :man
        )

        red_val_card_res = client.call(
          :redeem_value_card,
          message:
            "<caller-id>#{caller_id}</caller-id>
            <session type='service'/>
            <cust-key>#{customer_id}</cust-key>
            <pin-text>#{pin}</pin-text>
            <locale>US</locale>
            <references key='accountSuffix' value='USD'/>
            <references key='currency' value='USD'/>
            <references key='locale' value='en_US'/>
            <references key='CUST_KEY' value='#{customer_id}'/>
            <references key='transactionId' value='11223344'/>"
        )
        status_code_redemption = red_val_card_res.http.code
      rescue => e
        status_code_redemption = e
      end

      # Step 2: Get Pin Attributes
      fet_pin_att_res = PINManagement.fetch_pin_attributes(Misc::CONST_CALLER_ID, pin)
      pin_status = fet_pin_att_res.xpath('//pins/@status').text
      pin_value = fet_pin_att_res.xpath('//pins/@pin').text
    end

    it "Verify 'redeemValueCard' calls successfully" do
      expect(status_code_redemption).to eq(200)
    end

    it 'Match content of [@pin]' do
      expect(pin_value).to eq(pin)
    end

    it "Match content of [@status] = 'REDEEMED'" do
      expect(pin_status).to eq('REDEEMED')
    end

    it 'Update PIN status to Used' do
      PinRedemption.update_pin_status(env, 'USV1', pin_available, 'Used') if status_code_redemption == 200 && pin_status == 'REDEEMED'
    end
  end

  context 'Test Case 06 - Upload Logs' do
    rio_log_info = { caller_id: caller_id, session: session, device_serial: device_serial1, child_id: rio_child_id, file_name: filename, content_path: content_path, slot: '0' }
    lp2_log_info = { caller_id: caller_id, session: session, device_serial: device_serial2, child_id: lp2_child_id, file_name: filename, content_path: content_path, slot: '0' }
    lr_log_info = { caller_id: caller_id, session: session, device_serial: device_serial3, child_id: lr_child_id, file_name: filename, content_path: content_path, slot: '0' }

    upload_logs rio_log_info, 'RIO'
    upload_logs lp2_log_info, 'LeapPad2'
    upload_logs lr_log_info, 'LeapReader'
  end

  context 'Test Case 07 - Use REST to get child information' do
    get_child_rio_res = get_child_lp2_res = get_child_lr_res = nil

    before :all do
      get_child_rio_res = ChildManagementRest.fetch_child(Misc::CONST_REST_CALLER_ID, rio_child_id, session)
      get_child_lp2_res = ChildManagementRest.fetch_child(Misc::CONST_REST_CALLER_ID, lp2_child_id, session)
      get_child_lr_res = ChildManagementRest.fetch_child(Misc::CONST_REST_CALLER_ID, lr_child_id, session)
    end

    it 'Match content of [@childID] - RIO' do
      expect(get_child_rio_res['data']['childID']).to eq(rio_child_id)
    end

    it 'Match content of [@childName] - RIO' do
      expect(get_child_rio_res['data']['childName']).to eq('RIO')
    end

    it 'Match content of [@childID] - LeapPad2' do
      expect(get_child_lp2_res['data']['childID']).to eq(lp2_child_id)
    end

    it 'Match content of [@childName] - LeapPad2' do
      expect(get_child_lp2_res['data']['childName']).to eq('LP2')
    end

    it 'Match content of [@childID] - LeapReader' do
      expect(get_child_lr_res['data']['childID']).to eq(lr_child_id)
    end

    it 'Match content of [@childName] - LeapReader' do
      expect(get_child_lr_res['data']['childName']).to eq('LR')
    end
  end
end
