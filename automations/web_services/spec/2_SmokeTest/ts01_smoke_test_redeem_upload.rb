require File.expand_path('../../spec_helper', __FILE__)
require 'authentication'
require 'child_management'
require 'customer_management'
require 'child_management'
require 'device_management'
require 'owner_management'
require 'device_profile_management'
require 'device_log_upload'
require 'device_profile_content'
require 'pin_management'
require 'automation_common'

=begin
Smoke test 01: redeem and upload functions devices: RIO, LPAD2, LGS, LR and MP
=end

start_browser

def link_device(data)
  xml_claim_device = OwnerManagement.claim_device(data[:caller_id], data[:session], data[:customer_id], data[:device_serial], data[:platform], data[:slot], data[:child_name], '04444454')
  claim_device = OwnerManagement.claim_device_info xml_claim_device

  it "Match content of [@serial] - #{data[:child_name]}" do
    expect(claim_device[:device_serial]).to eq(data[:device_serial])
  end

  it "Match content of [@platform] - #{data[:child_name]}" do
    expect(claim_device[:platform]).to eq(data[:platform])
  end
end

describe "TestSuite 01 - Smoke test 01 - Redeem - Upload - #{Misc::CONST_ENV}" do
  env = Misc::CONST_ENV
  caller_id = Misc::CONST_CALLER_ID
  serial_rio = 'RIO' + DeviceManagement.generate_serial
  serial_lp2 = 'LP2' + DeviceManagement.generate_serial
  serial_lgs = 'LGS' + DeviceManagement.generate_serial
  serial_lr = 'LR' + DeviceManagement.generate_serial
  serial_mp = 'MP' + DeviceManagement.generate_serial
  username = email = LFCommon.generate_email
  screen_name = CustomerManagement.generate_screenname
  password = '123456'
  content_path = "#{Misc::CONST_PROJECT_PATH}/data/Log2.xml"
  filename = 'Stretchy monkey.log'
  customer_id = session = nil
  rio_child_id = lp2_child_id = lgs_child_id = lr_child_id = mp_child_id = nil

  context 'Test Case 01 - Account Setup' do
    register_cus_res = CustomerManagement.register_customer(caller_id, screen_name, email, username)
    arr_register_cus_res = CustomerManagement.get_customer_info(register_cus_res)
    customer_id = arr_register_cus_res[:id]

    type1 = register_cus_res.xpath('//customer').attr('type').text
    username1 = register_cus_res.xpath('//customer/credentials').attr('username').text

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

    rio_child_info = { caller_id: caller_id, session: session, customer_id: customer_id, child_name: 'RIO', gender: 'male', grade: '1' }
    lp2_child_info = { caller_id: caller_id, session: session, customer_id: customer_id, child_name: 'LP2', gender: 'female', grade: '1' }
    lgs_child_info = { caller_id: caller_id, session: session, customer_id: customer_id, child_name: 'LGS', gender: 'female', grade: '3' }
    lr_child_info = { caller_id: caller_id, session: session, customer_id: customer_id, child_name: 'LR', gender: 'male', grade: '2' }
    mp_child_info = { caller_id: caller_id, session: session, customer_id: customer_id, child_name: 'Mypals', gender: 'female', grade: '1' }

    rio_child_id = create_child rio_child_info
    lp2_child_id = create_child lp2_child_info
    lgs_child_id = create_child lgs_child_info
    lr_child_id = create_child lr_child_info
    mp_child_id = create_child mp_child_info
  end

  context 'Test Case 02 - Claim Devices' do
    OwnerManagement.claim_device(caller_id, session, customer_id, serial_rio, 'leappad3', '0', 'RIOKid', '04444454')

    xml_list_nominated_devices_res = DeviceManagement.list_nominated_devices(caller_id, session, 'service')
    serial1 = xml_list_nominated_devices_res.xpath('//device[1]').attr('serial').text
    platform1 = xml_list_nominated_devices_res.xpath('//device[1]').attr('platform').text

    it 'Match content of [@serial] - RIO' do
      expect(serial1).to eq(serial_rio)
    end

    it 'Match content of [@platform] - RIO' do
      expect(platform1).to eq('leappad3')
    end

    lp2_device_info = { caller_id: caller_id, session: session, customer_id: customer_id, device_serial: serial_lp2, platform: 'leappad2', slot: '0', child_name: 'LP2' }
    lgs_device_info = { caller_id: caller_id, session: session, customer_id: customer_id, device_serial: serial_lgs, platform: 'explorer2', slot: '0', child_name: 'LGS' }
    lr_device_info = { caller_id: caller_id, session: session, customer_id: customer_id, device_serial: serial_lr, platform: 'leapreader', slot: '0', child_name: 'LR' }
    mp_device_info = { caller_id: caller_id, session: session, customer_id: customer_id, device_serial: serial_mp, platform: 'mypals', slot: '0', child_name: 'MyPals' }

    link_device lp2_device_info
    link_device lgs_device_info
    link_device lr_device_info
    link_device mp_device_info

    # Step 6: Assign Device Profiles
    xml_assign_device = LFCommon.soap_call(
      LFSOAP::CONST_INMON_ENDPOINTS[:device_profile_management][:endpoint],
      LFSOAP::CONST_INMON_ENDPOINTS[:device_profile_management][:namespace],
      :assign_device_profile,
      "<device-profile device='#{serial_rio}' platform='leappad3' slot='0' name='RIO' child-id='#{rio_child_id}'/>
      <device-profile device='#{serial_lp2}' platform='leappad2' slot='0' name='LP2' child-id='#{lp2_child_id}'/>
      <device-profile device='#{serial_lgs}' platform='explorer2' slot='0' name='LGS' child-id='#{lgs_child_id}'/>
      <device-profile device='#{serial_lr}' platform='leapreader' slot='0' name='LR' child-id='#{lr_child_id}'/>
      <device-profile device='#{serial_mp}' platform='mypals' slot='0' name='MyPals' child-id='#{mp_child_id}'/>
      <caller-id>#{caller_id}</caller-id>
      <username/>
      <customer-id>#{customer_id}</customer-id>"
    )

    soap_fault = xml_assign_device.xpath('//faultstring').count

    it "Verify 'assignDeviceProfiles' calls successfully" do
      expect(soap_fault).to eq(0)
    end

    xml_get_device_profile = DeviceProfileManagement.list_device_profiles(caller_id, username, customer_id, '10', '10', '')
    profile_num = xml_get_device_profile.xpath('//device-profile').count

    it 'Check count of [device-profile]' do
      expect(profile_num).to eq(5)
    end
  end

  context 'Test Case 03 - Redeem - USV1 PIN' do
    status_code_redemption = pin_value = pin = pin_status = pin_available = nil

    before :all do
      # Make account known to vindica system
      LFCommon.new.login_to_lfcom(username, password)

      pin_available = PinRedemption.get_pin_number(env, 'USV1', 'Available')
      pin = pin_available.delete('-')

      begin
        # Step 1: Redeem USV1 Code
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

  context 'Test Case 04 - Device Log & Content Upload - RIO' do
    rio_log_info = { caller_id: caller_id, session: session, device_serial: serial_rio, child_id: rio_child_id, file_name: filename, content_path: content_path, slot: '0' }
    upload_logs rio_log_info, 'RIO'
  end

  context 'Test Case 05 - Device Log & Content Upload - LP2' do
    lp2_log_info = { caller_id: caller_id, session: session, device_serial: serial_lp2, child_id: lp2_child_id, file_name: filename, content_path: content_path, slot: '0' }
    upload_logs lp2_log_info, 'LeapPad 2'
  end

  context 'Test Case 06 - Device Log & Content Upload - LGS' do
    lgs_log_info = { caller_id: caller_id, session: session, device_serial: serial_lgs, child_id: lgs_child_id, file_name: filename, content_path: content_path, slot: '0' }
    upload_logs lgs_log_info, 'LGS'
  end

  context 'Test Case 07 - Device Log & Content Upload - LR' do
    lr_log_info = { caller_id: caller_id, session: session, device_serial: serial_lr, child_id: lr_child_id, file_name: filename, content_path: content_path, slot: '0' }
    upload_logs lr_log_info, 'LeapReader'
  end

  context 'Test Case 08 - Device Log & Content Upload - MyPals' do
    mp_log_info = { caller_id: caller_id, session: session, device_serial: serial_mp, child_id: mp_child_id, file_name: filename, content_path: content_path, slot: '0' }
    upload_logs mp_log_info, 'MyPals'
  end
end
