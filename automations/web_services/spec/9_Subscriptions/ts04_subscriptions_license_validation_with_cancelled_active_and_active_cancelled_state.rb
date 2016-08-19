require File.expand_path('../../spec_helper', __FILE__)
require 'parent_management'
require 'credential_management'
require 'license_management'
require 'pages/subscription/login_page'
require 'pages/subscription/app_center_sb_page'

=begin
Subscriptions: Check license for KidUI app with active, cancelled and active cancelled state
=end

describe "TS04 - Check license for KidUI app - #{Misc::CONST_ENV}" do
  caller_id = Misc::CONST_REST_CALLER_ID
  package_id_kidui = 'PHR2-0x002E0004-000000'

  start_browser

  login_page = LogInPage.new
  app_center_sb_page = AppCenterSbPage.new

  context 'Active state: Verify status of KidUI app is installed and user is able to open landing page' do
    installed_state = nil
    session = ''
    device_serial = SUBSCRIPTIONS::CONST_DEVICE_SERIAL_BELONG_EMAIL_ACTIVE
    email_active = SUBSCRIPTIONS::CONST_EMAIL_ACTIVE
    password = SUBSCRIPTIONS::CONST_PASSWORD_OF_EMAIL_ACTIVE
    grade = SUBSCRIPTIONS::CONST_GRADE_CHILD_OF_EMAIL_ACTIVE

    before :all do
      device_inventory_res = PackageManagement.device_inventory(caller_id, 'service', device_serial, 'device')
      installed_state = LicenseManagement.check_install_package(device_inventory_res, package_id_kidui, 'installed')
      response = CredentialManagementRest.login caller_id, email_active, password
      session = response['data']['token']
    end

    it '1. Verify status of KidUI app is installed' do
      expect(installed_state).to eq(1)
    end

    it '2. Go to landing page' do
      login_page.load SUBSCRIPTIONS::CONST_LOGIN_URL
      login_page.log_in email_active, password
      expect(login_page.already_signed_up_popup?).to eq(true)
      app_center_sb_page.load SUBSCRIPTIONS::CONST_LANDING_URL % [device_serial, caller_id, email_active, session, device_serial, grade]
    end

    it 'Verify user is able to open landing page successful' do
      expect(app_center_sb_page.most_popular?).to eq(true)
    end
  end

  context 'Active-Canceled state: Verify status of KidUI app is installed and user is able to open landing page' do
    installed_state = nil
    session = ''
    device_serial = SUBSCRIPTIONS::CONST_DEVICE_SERIAL_BELONG_EMAIL_ACTIVE_CANCEL
    email_active_cancel = SUBSCRIPTIONS::CONST_EMAIL_ACTIVE_CANCEL
    password = SUBSCRIPTIONS::CONST_PASSWORD_OF_EMAIL_ACTIVE_CANCEL
    grade = SUBSCRIPTIONS::CONST_GRADE_CHILD_OF_EMAIL_ACTIVE_CANCEL

    before :all do
      cancel_membership email_active_cancel, password
      device_inventory_res = PackageManagement.device_inventory(caller_id, 'service', device_serial, 'device')
      installed_state = LicenseManagement.check_install_package(device_inventory_res, package_id_kidui, 'installed')
      response = CredentialManagementRest.login caller_id, email_active_cancel, password
      session = response['data']['token']
    end

    it '1. Verify status of KidUI app is installed' do
      expect(installed_state).to eq(1)
    end

    it '2. Go to landing page' do
      login_page.load SUBSCRIPTIONS::CONST_LOGIN_URL
      login_page.log_in email_active_cancel, password
      expect(login_page.already_signed_up_popup?).to eq(true)
      app_center_sb_page.load SUBSCRIPTIONS::CONST_LANDING_URL % [device_serial, caller_id, email_active_cancel, session, device_serial, grade]
    end

    it 'Verify user is able to open landing page successful' do
      expect(app_center_sb_page.most_popular?).to eq(true)
    end

    after :all do
      restart_membership email_active_cancel, password
    end
  end

  context 'Canceled state: Verify status of KidUI app is installed and message expired account displays when user goes to landing page' do
    installed_state = nil
    session = ''
    device_serial = SUBSCRIPTIONS::CONST_DEVICE_SERIAL_BELONG_EMAIL_EXPIRED
    email_expired = SUBSCRIPTIONS::CONST_EMAIL_EXPIRED
    password = SUBSCRIPTIONS::CONST_PASSWORD_OF_EMAIL_EXPIRED
    grade = SUBSCRIPTIONS::CONST_GRADE_CHILD_OF_EMAIL_EXPIRED

    before :all do
      device_inventory_res = PackageManagement.device_inventory(caller_id, 'service', device_serial, 'device')
      installed_state = LicenseManagement.check_install_package(device_inventory_res, package_id_kidui, 'installed')
      response = CredentialManagementRest.login caller_id, email_expired, password
      session = response['data']['token']
    end

    it '1. Verify status of KidUI app is installed' do
      expect(installed_state).to eq(1)
    end

    it '2. Go to landing page' do
      login_page.load SUBSCRIPTIONS::CONST_LOGIN_URL
      login_page.log_in email_expired, password
      expect(login_page.already_signed_up_popup?).to eq(true)
      app_center_sb_page.load SUBSCRIPTIONS::CONST_LANDING_URL % [device_serial, caller_id, email_expired, session, device_serial, grade]
    end

    it 'Verify message expired account displays when user goes to landing page' do
      expect(app_center_sb_page.expired_message?).to eq(true)
    end
  end
end
