# Override Device Store data.xml
$LOAD_PATH.unshift('automations/lib')
require 'automation_common'
ATGConfiguration.override_atg_data('device_store' => 'LeapPad Platinum')

require File.expand_path('../../spec_helper', __FILE__)
require 'pages/atg_dv/atg_dv_starter_page'
require 'pages/atg_dv/atg_dv_pdp_page'
require 'pages/atg_dv/atg_dv_starter_success_page'
require 'pages/atg/atg_app_center_catalog_page'
require 'pages/atg/atg_login_register_page'

=begin
ATG: Bogota - Complete starter flow smoke test
=end

describe 'Bogota - Starter flow smoke test' do
  caller_id = ServicesInfo::CONST_CALLER_ID
  device_serial = DeviceManagementService.generate_serial 'leappadplatinum'
  platform = 'leappadplatinum'
  locale = 'en_us'
  email = Account::EMAIL_GUEST_CONST
  firstname = 'ltrc'
  lastname = 'vn'
  password = '123456'
  email_optin = 'true'
  session = ''
  type = 'service'
  slot = '0'
  profile_name = 'Bogota'
  dob = '2006-10-08'
  grade = '5'
  gender = 'male'
  pin = '1111'
  starter_page = pdp_page = nil
  atg_app_center_catalog_page = AtgAppCenterCatalogPage.new

  context "1. Create parent account. (URL: #{ServicesInfo::CONST_REST_ENDPOINT}#{ServicesInfo::CONST_CREATE_PARENT})" do
    create_parent_response = nil

    before :all do
      atg_app_center_catalog_page.load
      data = { caller_id: caller_id, email: email, password: password, firstname: firstname, lastname: lastname, email_optin: email_optin, locale: locale }
      create_parent_response = LFRestServices.create_parent data
      session = create_parent_response['data']['token']
    end

    it "Verify parent account is created successful (Email: #{email} - Password: #{password})" do
      expect(create_parent_response['status']).to eq(true)
    end

    it 'Verify parent id is created' do
      expect(create_parent_response['data']['parent']['parentID']).not_to be_empty
    end

    it 'Verify token is generated' do
      expect(session).not_to be_empty
    end
  end

  context "2. Link account with Bogota device (Device serial:#{device_serial})" do
    context "Link account. (Email: #{email} - device: #{device_serial})" do
      claim_response = response_owner = nil

      it "Claim device (URL: #{ServicesInfo::CONST_REST_ENDPOINT}#{ServicesInfo::CONST_UPDATE_BOGOTA % device_serial})" do
        claim_response = LFRestServices.update_bogota(
          caller_id,
          device_serial,
          platform,
          '[]',
          '{
          "mfgsku": "12345-11111",
          "model": "1",
          "locale": "%s"
          }' % locale
        )
      end

      it 'Verify device Id is created' do
        expect(claim_response['data']['devId'].to_s).not_to be_empty
      end

      it "Set device owner id (URL: #{ServicesInfo::CONST_REST_ENDPOINT}#{ServicesInfo::CONST_OWNER_BOGOTA % device_serial})" do
        response_owner = LFRestServices.owner_bogota(caller_id, session, device_serial)
      end

      it 'Verify device Owner Id is created' do
        expect(response_owner['data']['devOwnerId'].to_s).not_to be_empty
      end
    end

    context "Create Parent Pin and Child profiles. (Pin: #{pin} - Profile name: #{profile_name})" do
      device_response = nil

      before :all do
        data_input = { caller_id: caller_id, session: session, type: type, device_serial: device_serial, platform: platform, slot: slot, profile_name: profile_name, dob: dob, grade: grade, gender: gender, locale: locale, pin: pin }
        DeviceManagementService.update_profiles_and_parent_lock data_input
        device_response = LFRestServices.fetch_device(caller_id, device_serial)
      end

      it 'Verify child profile is created' do
        expect(device_response['data']['devUsers'][0]['userChildName']).to eq(profile_name)
      end

      it 'Verify parent lock is created' do
        expect(device_response['data']['devPin']).to eq(pin)
      end
    end
  end

  context '3. Go to Bogota starter page' do
    starter_url = Title.url_mapping("http://#{General::ENV_CONST.downcase}-www.leapfrog.com/en-us/app-center-dv/starter.jsp?UPCConnectedDeviceType=leappadplatinum&UPCConnectedDevice=#{device_serial}&UPCCallerId=e0d79c58-5111-413e-a756-06d4a0b2cd42&UPCSlot=-1&UPCModel=01&parentMode=true&UPCServiceSession=ea5bb3c1-f2ab-4c96-9c61-cc8f793e1b68&UPCDeviceType=leappadplatinum&UPCDevice=#{device_serial}&UPCConnectedDeviceModel=01&UPCConnectedDeviceTypeServiceCode=leappadplatinum&emailAddress=#{email}&UPCLocale=en_US&UPCInstallLocale=en_US&UPCGrade=5&appCenterMode=OOBE&currentBrowserAppName=InitialSetupApp&UPCNewDeviceSetup=1&rioMode=OOBE")

    before :all do
      atg_login_register_page = atg_app_center_catalog_page.goto_login
      atg_login_register_page.login(email, password)
    end

    it 'Go to Starter page' do
      starter_page = AtgDvStarterPage.new
      starter_page.go_to_starter_page starter_url
      pending("***Go to Starter page (URL: #{starter_url})")
    end
  end

  context '4. Select a starter app and go to PDP page' do
    it 'Choose the first app on Starter page' do
      starter_page.select_the_first_app_on_starter_page
      pdp_page = AtgDvPDPPage.new
    end

    it 'Verify PDP display' do
      expect(pdp_page.select_button_exist?).to eq(true)
    end
  end

  context '5. Select the app on PDP page' do
    it 'Click Select button on PDP page' do
      pdp_page.click_select_button
    end

    it 'Verify Confirmation pop-up displays' do
      expect(pdp_page.confirmation_pop_up_exist?).to eq(true)
    end
  end

  context '6. Click Yes button on Starter confirmation pop-up' do
    it 'Click Yes button on Starter confirmation pop-up' do
      pdp_page.click_yes_on_confirm_pop_up
    end
  end

  context '7. Verify user is taken to Starter Success page' do
    starter_success_page = AtgDvStarterSuccessPage.new

    it 'Verify Starter Success page display' do
      expect(starter_success_page.starter_success_page_exist?).to eq(true)
      pending("*** Verify Starter Success page display( URL: #{starter_success_page.current_url})")
    end
  end
end
