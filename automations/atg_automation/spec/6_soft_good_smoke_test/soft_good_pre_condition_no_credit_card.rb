require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_catalog_page'
require 'atg_login_register_page'
require 'atg_my_profile_page'

=begin
Pre-condition: Create a new account with full information (address, credit card, link to all device), a new account that use for testing with Acc Balance only and a new account with empty information
=end

atg_app_center_catalog_page = AtgAppCenterCatalogPage.new
atg_my_profile_page = AtgMyProfilePage.new
atg_login_register_page = nil
cookie_session_id = nil

# Account info
full_email = Account::EMAIL_GUEST_FULL_CONST
balance_email = Account::EMAIL_BALANCE_CONST
empty_email = Account::EMAIL_GUEST_EMPTY_CONST
password = General::PASSWORD_CONST

feature 'Pre condition - Create new accounts', js: true do
  before :all do
    cookie_session_id = atg_app_center_catalog_page.load
  end

  context 'Print Session ID' do
    scenario '' do
      pending "***SESSION_ID: #{cookie_session_id}"
    end
  end

  context 'Create new account with full information' do
    create_account_and_link_all_devices(
      General::FIRST_NAME_CONST,
      General::LAST_NAME_CONST,
      full_email,
      password,
      password
    )

    scenario "5. Go to 'Account information' page" do
      atg_my_profile_page.goto_account_information
    end

    scenario '6. Add new address information' do
      if General::LOCALE_CONST == 'IE' || General::LOCALE_CONST == 'ROW'
        pending '***Skip adding Address on IE, ROW locales (Unsupported)'
      else
        address = {
          first_name: BillingAddress::FIRST_NAME_CONST,
          last_name: BillingAddress::LAST_NAME_CONST,
          street: BillingAddress::STREET_CONST,
          city: BillingAddress::CITY_CONST,
          state: BillingAddress::STATE_CONST,
          postal: BillingAddress::POSTAL_CONST,
          phone_number: BillingAddress::PHONE_NUMBER_CONST
        }

        atg_my_profile_page.add_new_address address
        update_info_account(full_email, address[:street])
      end
    end

    scenario '7. Log out' do
      atg_my_profile_page.logout
    end
  end

  context 'Create new account with full information (Use for testing with Acc Balance only)' do
    before :all do
      atg_app_center_catalog_page.load
    end

    create_account_and_link_all_devices(
      General::FIRST_NAME_CONST,
      General::LAST_NAME_CONST,
      balance_email,
      password,
      password
    )

    scenario "5. Go to 'Account information' page" do
      atg_my_profile_page.goto_account_information
    end

    scenario '6. Add new address information' do
      if General::LOCALE_CONST == 'IE' || General::LOCALE_CONST == 'ROW'
        pending '***Skip adding Address on IE, ROW locales (Unsupported)'
      else
        address = {
          first_name: BillingAddress::FIRST_NAME_CONST,
          last_name: BillingAddress::LAST_NAME_CONST,
          street: BillingAddress::STREET_CONST,
          city: BillingAddress::CITY_CONST,
          state: BillingAddress::STATE_CONST,
          postal: BillingAddress::POSTAL_CONST,
          phone_number: BillingAddress::PHONE_NUMBER_CONST
        }

        atg_my_profile_page.add_new_address address
        update_info_account(balance_email, address[:street])
      end
    end

    scenario '7. Log out' do
      atg_my_profile_page.logout
    end
  end

  context 'Create new account with empty information' do
    before :all do
      atg_app_center_catalog_page.load
    end

    scenario '1. Go to register/login page' do
      atg_login_register_page = atg_app_center_catalog_page.goto_login
    end

    scenario '2. Register an account' do
      atg_my_profile_page = atg_login_register_page.register(
        General::FIRST_NAME_CONST,
        General::LAST_NAME_CONST,
        empty_email,
        password,
        password
      )
    end

    scenario '3. Verify My Profile page displays' do
      expect(atg_my_profile_page.my_profile_page_exist?).to eq(true)
    end
  end
end
