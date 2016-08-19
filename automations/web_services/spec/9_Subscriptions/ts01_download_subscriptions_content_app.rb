require File.expand_path('../../spec_helper', __FILE__)
require 'parent_management'
require 'pages/subscription/login_page'
require 'pages/subscription/payment_page'
require 'pages/subscription/app_center_sb_page'
require 'pages/subscription/confirmation_page'

=begin
Subscriptions: Complete OOBE flow - Sign up subscriptions and download Subscriptions content
=end

describe "TS01 - Claim Bogota device then sign up subscriptions and download Subscription content app - #{Misc::CONST_ENV}" do
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
  type = 'service'
  slot = '0'
  profile_name = 'profile1'
  dob = '2006-10-08'
  grade = '5'
  gender = 'male'
  pin = '1111'

  start_browser
  login_page = LogInPage.new
  payment_page = PaymentPage.new

  context 'Pre-condition: Complete OOBE flow with Bogota device' do
    context "1. Create parent account. (URL: #{LFREST::CONST_ENDPOINT}#{LFRESOURCES::CONST_CREATE_PARENT})" do
      create_parent_response = nil

      before :all do
        create_parent_response = ParentManagementRest.create_parent(caller_id, email, password, firstname, lastname, email_optin, locale)
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

    context '2. Claim device' do
      claim_response = response_owner = nil

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
      end

      it 'Verify device Id is created' do
        expect(claim_response['data']['devId'].to_s).not_to be_empty
      end

      it "Set device owner id (URL: #{LFREST::CONST_ENDPOINT}#{LFRESOURCES::CONST_OWNER_BOGOTA % device_serial})" do
        response_owner = owner_bogota(caller_id, session, device_serial)
      end

      it 'Verify device Owner Id is created' do
        expect(response_owner['data']['devOwnerId'].to_s).not_to be_empty
      end
    end

    context '3. Create parent lock and child profiles' do
      device_response = nil

      before :all do
        data_input = { caller_id: caller_id, session: session, type: type, device_serial: device_serial, platform: platform, slot: slot, profile_name: profile_name, dob: dob, grade: grade, gender: gender, locale: locale, pin: pin }
        DeviceManagement.update_profiles_and_parent_lock data_input
        device_response = fetch_device(caller_id, device_serial)
      end

      it 'Verify child profile is created' do
        expect(device_response['data']['devUsers'][0]['userChildName']).to eq(profile_name)
      end

      it 'Verify parent lock is created' do
        expect(device_response['data']['devPin']).to eq(pin)
      end
    end
  end

  context 'Sign up Subscription and start FREE trial' do
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

  context 'Download and install Subscriptions content app' do
    license_type_sub_app = status_sub_app = package_id_sub_app = status_install_sub_app = nil
    app_center_sb_page = AppCenterSbPage.new

    it 'Go to landing page' do
      login_page.load SUBSCRIPTIONS::CONST_LOGIN_URL
      login_page.log_in email, password
      expect(login_page.already_signed_up_popup?).to eq(true)
      app_center_sb_page.load SUBSCRIPTIONS::CONST_LANDING_URL % [device_serial, caller_id, email, session, device_serial, grade]
    end

    it 'Choose Subscriptions content app' do
      app_center_sb_page.choose_the_first_app
    end

    it 'Verify getting app successfully' do
      expect(app_center_sb_page.downloading_popup?).to eq(true)
    end

    it 'Get licence of subscriptions app' do
      device_inventory_res = PackageManagement.device_inventory(caller_id, 'service', device_serial, 'device', session)

      5.times do
        break unless device_inventory_res.xpath('//device/package[2]').class == NilClass
        sleep 1
        device_inventory_res = PackageManagement.device_inventory(caller_id, 'service', device_serial, 'device', session)
      end

      index = (device_inventory_res.xpath('//device/package[2]').attr('lictype').text == 'subscription') ? '2' : '1'
      device_package_xpath = "//device/package[#{index}]"
      license_type_sub_app = device_inventory_res.xpath(device_package_xpath).attr('lictype').text
      status_sub_app = device_inventory_res.xpath(device_package_xpath).attr('status').text
      package_id_sub_app = device_inventory_res.xpath(device_package_xpath).attr('id').text
    end

    it "Verify the Subscriptions content app is granted license is 'subscription'" do
      expect(license_type_sub_app).to eq('subscription')
    end

    it "Verify the Subscriptions content app has status is 'pending'" do
      expect(status_sub_app).to eq('pending')
    end

    it 'Download and install Subscriptions content app on device' do
      data_input = { caller_id: caller_id, session: session, device_serial: device_serial, package_id: package_id_sub_app, type: 'Application' }
      authorize_res = PackageManagement.authorize_installation_package data_input
      license_id = authorize_res.xpath('//license').attr('id').text

      # reportInstallation
      PackageManagement.report_installation(caller_id, session, device_serial, '-1', package_id_sub_app, license_id)

      # device inventory
      device_inventory_res = PackageManagement.device_inventory(caller_id, 'service', device_serial, 'device', session)
      index = (device_inventory_res.xpath('//device/package[2]').attr('lictype').text == 'subscription') ? '2' : '1'
      status_install_sub_app = device_inventory_res.xpath("//device/package[#{index}]").attr('status').text
    end

    it 'Verify the Subscriptions content app install successful' do
      expect(status_install_sub_app).to eq('installed')
    end
  end
end
