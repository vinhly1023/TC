require File.expand_path('../../spec_helper', __FILE__)
require 'parent_management'
require 'license_management'
require 'pages/subscription/login_page'
require 'pages/subscription/payment_page'
require 'pages/subscription/app_center_sb_page'
require 'pages/subscription/confirmation_page'

=begin
Subscriptions: Complete OOBE flow - Sign up subscriptions and purchase app
=end

describe "TS02 - Claim Bogota device then sign up subscriptions and purchase app - #{Misc::CONST_ENV}" do
  # services variables
  caller_id = Misc::CONST_REST_CALLER_ID
  device_serial = DeviceManagement.generate_serial 'BOGOTA'
  platform = 'leappadplatinum'
  locale = 'en_us'
  email = 'ltrcvn' + LFCommon.get_current_time + 'sbgroupf01@leapfrog.test'
  firstname = 'ltrc'
  lastname = 'vn'
  password = '123456'
  email_optin = 'true'
  session = ''
  parent_id = nil
  type = 'service'
  slot = '0'
  profile_name = 'profile1'
  dob = '2006-10-08'
  grade = '5'
  gender = 'male'
  pin = '1111'
  package_id = 'PHRS-0x0028001F-000000'
  title = 'PAW Patrol: Ready for Action'

  # atg variables
  start_browser

  context 'Pre-condition: Complete OOBE flow with Bogota device' do
    context "1. Create parent account. (URL: #{LFREST::CONST_ENDPOINT}#{LFRESOURCES::CONST_CREATE_PARENT})" do
      create_parent_response = nil

      before :all do
        create_parent_response = ParentManagementRest.create_parent(caller_id, email, password, firstname, lastname, email_optin, locale)
        session = create_parent_response['data']['token']
        parent_id = create_parent_response['data']['parent']['parentID']
      end

      it "Verify parent account is created successful: (Email: #{email} - Password: #{password})" do
        expect(create_parent_response['status']).to eq(true)
      end

      it 'Verify parent id is created' do
        expect(parent_id).not_to be_empty
      end

      it 'Verify token is generated' do
        expect(create_parent_response['data']['token']).not_to be_empty
      end
    end

    context '2. Claim device' do
      device_id = owner_id = nil

      it "Claim device (URL: #{LFREST::CONST_ENDPOINT}#{LFRESOURCES::CONST_UPDATE_BOGOTA % device_serial})" do
        claim_response = update_bogota(
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

        device_id = claim_response['data']['devId'].to_s
      end

      it 'Verify device Id is created' do
        expect(device_id).not_to be_empty
      end

      it "Set device owner id (URL: #{LFREST::CONST_ENDPOINT}#{LFRESOURCES::CONST_OWNER_BOGOTA % device_serial})" do
        response_owner = owner_bogota caller_id, session, device_serial
        owner_id = response_owner['data']['devOwnerId'].to_s
      end

      it 'Verify device Owner Id is created' do
        expect(owner_id).not_to be_empty
      end
    end

    context '3. Create parent lock and child profiles' do
      device_response = nil

      before :all do
        data_input = { caller_id: caller_id, session: session, type: type, device_serial: device_serial, platform: platform, slot: slot, profile_name: profile_name, dob: dob, grade: grade, gender: gender, locale: locale, pin: pin }
        DeviceManagement.update_profiles_and_parent_lock data_input
        device_response = fetch_device caller_id, device_serial
      end

      it 'Verify parent lock is created' do
        expect(device_response['data']['devUsers'][0]['userChildName']).to eq(profile_name)
      end

      it 'Verify child profile is created' do
        expect(device_response['data']['devPin']).to eq(pin)
      end
    end
  end

  context 'Sign up Subscription and start FREE trial' do
    login_page = LogInPage.new
    payment_page = PaymentPage.new

    context '1. Sign up Subscription' do
      it "Go to Subscription Login page #{SUBSCRIPTIONS::CONST_LOGIN_URL}" do
        login_page.load SUBSCRIPTIONS::CONST_LOGIN_URL
      end

      it "Log in with username #{email} and password #{password}" do
        login_page.log_in email, password
      end
    end

    context '2. Start your FREE 2-day trial' do
      it "Fill billing information #{SUBSCRIPTIONS::CONST_BILLING_INFO}" do
        payment_page.fill_billing_info SUBSCRIPTIONS::CONST_BILLING_INFO
      end

      it "Fill billing address #{SUBSCRIPTIONS::CONST_BILLING_ADDRESS}" do
        payment_page.fill_address_info SUBSCRIPTIONS::CONST_BILLING_ADDRESS
      end

      it 'Start free trial' do
        payment_page.start_free_trial
      end

      it 'Verify that user registers successfully' do
        expect(ConfirmationPage.new.confirmation_page_exist?).to be true
      end
    end
  end

  context 'Check license, download and install KidUI app' do
    license_type_kidui = status_kidui = package_id_kidui = status_install_kidui = nil

    before :all do
      device_inventory_res = PackageManagement.device_inventory(caller_id, 'service', device_serial, 'device', session)
      license_type_kidui = device_inventory_res.xpath('//device/package').attr('lictype').text
      status_kidui = device_inventory_res.xpath('//device/package').attr('status').text
      package_id_kidui = device_inventory_res.xpath('//device/package').attr('id').text
    end

    it "Verify the KidUI app is granted license is 'sbcrKidUI'" do
      expect(license_type_kidui).to eq('sbcrKidUI')
    end

    it "Verify the KidUI app has status is 'pending'" do
      expect(status_kidui).to eq('pending')
    end

    it 'Download and install KidUI app' do
      data_input = { caller_id: caller_id, session: session, device_serial: device_serial, package_id: package_id_kidui, type: 'Application' }
      authorize_res = PackageManagement.authorize_installation_package data_input
      license_id = authorize_res.xpath('//license').attr('id').text

      # reportInstallation
      PackageManagement.report_installation(caller_id, session, device_serial, '-1', package_id_kidui, license_id)

      # device inventory
      device_inventory_res = PackageManagement.device_inventory(caller_id, 'service', device_serial, 'device', session)
      status_install_kidui = device_inventory_res.xpath('//device/package').attr('status').text
    end

    it 'Verify the KidUI app install successful' do
      expect(status_install_kidui).to eq('installed')
    end
  end

  context 'Purchase app' do
    license_id = license_type = nil

    it "Purchase app #{title}" do
      grant_license_res = LicenseManagement.grant_license(caller_id, session, parent_id, device_serial, package_id)
      license_id = grant_license_res.xpath('//license').attr('id').text
      device_inventory = PackageManagement.device_inventory(caller_id, 'application', device_serial, 'Application')
      license_type = PackageManagement.get_type_of_license(device_inventory, package_id)
    end

    it 'Verify license id is created' do
      expect(license_id).not_to be_empty
    end

    it "Verify the app is granted license is 'purchase'" do
      expect(license_type).to eq('purchase')
    end

    it 'Download and install app on device' do
      LicenseManagement.install_package(caller_id, device_serial, '0', package_id)
      PackageManagement.report_installation(caller_id, session, device_serial, '0', package_id, license_id)
    end

    it 'Verify app is install successful' do
      device_inventory_res = PackageManagement.device_inventory(caller_id, 'application', device_serial, 'Application')
      install_status = LicenseManagement.check_install_package(device_inventory_res, package_id, 'installed')

      expect(install_status).to eq(1)
    end
  end
end
