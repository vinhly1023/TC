require File.expand_path('../../spec_helper', __FILE__)
require 'authentication'
require 'child_management'
require 'customer_management'
require 'child_management'
require 'device_management'
require 'owner_management'
require 'device_profile_management'
require 'device_log_upload'

=begin
Smoke test 02: upload game/device log functions devices: RIO, LPAD2, LR
=end

describe "TestSuite 02 - Smoke test 02 - #{Misc::CONST_ENV}" do
  caller_id = 'a023bc85-db5b-40b5-934c-28a72b4d9547'
  device_serial1 = 'RIO' + DeviceManagement.generate_serial
  device_serial2 = 'LP2' + DeviceManagement.generate_serial
  device_serial3 = 'LR' + DeviceManagement.generate_serial
  username = email = LFCommon.generate_email
  screen_name = CustomerManagement.generate_screenname
  password = '123456'
  customer_id = session = nil
  rio_child_id = lp2_child_id = lr_child_id = nil

  filename = 'Stretchy monkey.log'
  content_path = "#{Misc::CONST_PROJECT_PATH}/data/Log2.xml"

  context 'Test Case 01 - Account Setup' do
    xml_register_cus_res = CustomerManagement.register_customer(caller_id, screen_name, email, username)
    arr_register_cus_res = CustomerManagement.get_customer_info(xml_register_cus_res)
    customer_id = arr_register_cus_res[:id]

    type1 = xml_register_cus_res.xpath('//customer').attr('type').text
    username1 = xml_register_cus_res.xpath('//customer/credentials').attr('username').text

    it 'Match content of [@type]' do
      expect(type1).to eq('Registered')
    end

    it 'Match content of [@username]' do
      expect(username1).to eq(username)
    end

    session = Authentication.get_service_session(caller_id, username, password)

    it 'Check for existance of [session]' do
      expect(session).not_to be_empty
    end

    # create RIO, LP2 and LR children
    rio_child_info = { caller_id: caller_id, session: session, customer_id: customer_id, child_name: 'RIO', gender: 'male', grade: '1' }
    lp2_child_info = { caller_id: caller_id, session: session, customer_id: customer_id, child_name: 'LP2', gender: 'female', grade: '1' }
    lr_child_info = { caller_id: caller_id, session: session, customer_id: customer_id, child_name: 'LR', gender: 'male', grade: '2' }

    rio_child_id = create_child rio_child_info
    lp2_child_id = create_child lp2_child_info
    lr_child_id = create_child lr_child_info
  end

  context 'Test Case 02 - Claim Devices' do
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

    it "Verify 'Assign Device Profiles' calls successfully" do
      expect(soap_fault).to eq(0)
    end

    # Step 3: Get Device Profiles
    xml_get_device_profile = DeviceProfileManagement.list_device_profiles(caller_id, username, customer_id, '10', '10', '')
    profile_num = xml_get_device_profile.xpath('//device-profile').count

    it 'Check count of [device-profile]' do
      expect(profile_num).to eq(3)
    end
  end

  context 'Test Case 03 - Device Log & Content Upload - RIO' do
    upload_device_log_and_game_log(caller_id, device_serial1, rio_child_id, filename, content_path)
  end

  context 'Test Case 04 - Device Log & Content Upload - LP2' do
    upload_device_log_and_game_log(caller_id, device_serial2, lp2_child_id, filename, content_path)
  end

  context 'Test Case 05 - Device Log & Content Upload - LR' do
    upload_device_log_and_game_log(caller_id, device_serial3, lr_child_id, filename, content_path)
  end
end
