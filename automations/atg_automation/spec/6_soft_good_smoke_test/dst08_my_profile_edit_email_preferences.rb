require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_catalog_page'
require 'atg_login_register_page'
require 'atg_my_profile_page'

=begin
Verify that user can update the Email preference
=end

# initial variables
atg_app_center_catalog_page = AtgAppCenterCatalogPage.new
atg_login_register_page = nil
atg_my_profile_page = nil
cookie_session_id = nil
email_preferences = nil

feature 'DST08 - Account Management - My Profile - Edit Email Preferences (opt-in/opt out)', js: true do
  before :all do
    cookie_session_id = atg_app_center_catalog_page.load
  end

  context 'Print Session ID' do
    scenario '' do
      pending "***SESSION_ID: #{cookie_session_id}"
    end
  end

  context 'Edit Email Preferences' do
    scenario '1. Click Login / Register > Login / Register' do
      atg_login_register_page = atg_app_center_catalog_page.goto_login
      pending "***1. Click Login / Register > Login / Register (URL: #{atg_login_register_page.current_url})"
    end

    scenario "2. Login with an existing account (Email: #{Account::EMAIL_EXIST_EMPTY_CONST})" do
      atg_my_profile_page = atg_login_register_page.login(Account::EMAIL_EXIST_EMPTY_CONST, General::PASSWORD_CONST)
    end

    scenario '3. Go to My Profile > Account Information ' do
      atg_my_profile_page.goto_account_information
      pending "***3. Go to My Profile > Account Information (URL: #{atg_my_profile_page.current_url})"
    end

    scenario '4. Change the email preferences (LearningPath = \'Opt out\', Leapfrog = \'Opt out\')' do
      atg_my_profile_page.edit_email_preferences('unchecked', 'unchecked')
      email_preferences = atg_my_profile_page.email_preferences
    end

    scenario '5. Verify LearningPath status is \'Opt out\'' do
      expect(email_preferences[:learning_path_optin]).to eq('Opt out')
    end

    scenario '6. Verify Leapfrog status is \'Opt out\'' do
      expect(email_preferences[:leapfrog_optin]).to eq('Opt out')
    end

    scenario '7. Change the email preferences (LearningPath = \'Opt in\', Leapfrog = \'Opt in\')' do
      atg_my_profile_page.edit_email_preferences
      email_preferences = atg_my_profile_page.email_preferences
    end

    scenario '8. Verify LearningPath status is \'Opt in\'' do
      expect(email_preferences[:learning_path_optin]).to eq('Opt in')
    end

    scenario '9. Verify Leapfrog status is \'Opt in\'' do
      expect(email_preferences[:leapfrog_optin]).to eq('Opt in')
    end
  end
end
