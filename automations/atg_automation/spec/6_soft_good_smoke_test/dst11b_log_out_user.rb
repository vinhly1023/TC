require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_catalog_page'
require 'atg_login_register_page'
require 'atg_my_profile_page'

=begin
Verify that user can login with an existing account successfully
=end

# initial variables
atg_app_center_catalog_page = AtgAppCenterCatalogPage.new
atg_login_register_page = nil
atg_my_profile_page = nil
cookie_session_id = nil

# Account info
email = Account::EMAIL_EXIST_EMPTY_CONST
password = General::PASSWORD_CONST
first_name = General::FIRST_NAME_CONST

feature 'DST11B - Account Management - Logout User', js: true do
  before :all do
    cookie_session_id = atg_app_center_catalog_page.load
  end

  context 'Print Session ID' do
    scenario '' do
      pending "***SESSION_ID: #{cookie_session_id}"
    end
  end

  context 'Login to an existing Account' do
    scenario '1. Click \'Login / Register\' > \'Login / Register\'' do
      atg_login_register_page = atg_app_center_catalog_page.goto_login
      pending "***1. Go to Login/Register page (URL: #{atg_login_register_page.current_url})"
    end

    scenario "2. Login with an existing account (Email: #{email} - Password: #{password})" do
      atg_my_profile_page = atg_login_register_page.login(email, password)
    end

    scenario '3. Verify My Account Page is loaded' do
      expect(atg_my_profile_page.my_profile_page_exist?).to eq(true)
    end

    scenario '4. Verify \'Login / Register\' menu Item becomes \'My Account\'' do
      expect(atg_my_profile_page.login_register_text).to eq('My Account')
    end

    scenario "5. Verify 'My Account Menu' will have 'Welcome #{first_name}' as the first item" do
      atg_my_profile_page.mouse_hover_my_account_link
      expect(atg_my_profile_page.welcome_text).to eq('Welcome ' + first_name + '!')
    end
  end

  context 'Logout account' do
    scenario '1. Click \'My Account\' > \'Logout\'' do
      atg_my_profile_page.logout
    end

    scenario '2. Verify  \'My Account\' menu Item becomes \'Log In / Register\'' do
      expect(atg_my_profile_page.login_register_text).to eq('Log In / Register')
    end

    scenario '3. Verify user logout successful' do
      expect(atg_my_profile_page.logout_successful?).to eq(true)
    end
  end
end
