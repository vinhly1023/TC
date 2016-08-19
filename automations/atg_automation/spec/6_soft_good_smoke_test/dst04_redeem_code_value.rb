require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_catalog_page'
require 'atg_login_register_page'
require 'atg_my_profile_page'

=begin
Verify that user can redeem value code to account
=end

# ATG page
atg_app_center_catalog_page = AtgAppCenterCatalogPage.new
atg_login_register_page = nil
atg_my_profile_page = nil
cookie_session_id = nil

# Account info
env = General::ENV_CONST
locale = General::LOCALE_CONST
before_ab = ''
after_ab = ''
pin_number = ''

feature 'DST04 - Account Management - Redeem Value Code', js: true do
  next unless pin_available?(env, locale)

  before :all do
    cookie_session_id = atg_app_center_catalog_page.load
  end

  context 'Print Session ID' do
    scenario '' do
      pending "***SESSION_ID: #{cookie_session_id}"
    end
  end

  context 'Login to an existing account' do
    scenario '1. Go to Login/Register page' do
      atg_login_register_page = atg_app_center_catalog_page.goto_login
      pending "***1. Go to Login/Register page (URL: #{atg_login_register_page.current_url})"
    end

    scenario "2. Login to an existing account (Email: #{Account::EMAIL_EXIST_BALANCE_CONST})" do
      atg_my_profile_page = atg_login_register_page.login(Account::EMAIL_EXIST_BALANCE_CONST, General::PASSWORD_CONST)
    end
  end

  context 'Redeem value card' do
    before :each do
      skip 'Error while redeem code. Please re-check!' if pin_number.nil?
    end

    scenario '1. Get existing Account Balance before redeem' do
      atg_my_profile_page.mouse_hover_my_account_link
      before_ab = atg_my_profile_page.account_balance_under_my_profile
      pending "***1. Get existing Account Balance before redeem: '#{before_ab}'"
    end

    scenario '2. Click on Redeem Code link' do
      atg_my_profile_page.click_redeem_code_link
    end

    scenario '3. Redeem a value code' do
      pin_number = atg_my_profile_page.redeem_code(env, locale)
      fail 'Error while redeem code. Please re-check!' if pin_number.nil?
      pending "***3. Redeem a value code (#{pin_number})"
    end

    scenario '4. Get Account Balance after redeeming Code' do
      atg_my_profile_page.mouse_hover_my_account_link
      after_ab = atg_my_profile_page.account_balance_under_my_profile
      pending "***4. Get Account Balance after redeeming Code: '#{after_ab}'"
    end

    scenario '5. Verify Account Balance is updated correctly' do
      expect(Title.cal_account_balance(before_ab, pin_number['amount'], locale)).to eq(after_ab)
    end
  end
end
