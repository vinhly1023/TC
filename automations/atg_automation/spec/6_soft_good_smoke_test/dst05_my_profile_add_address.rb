require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_catalog_page'
require 'atg_login_register_page'
require 'atg_my_profile_page'

=begin
Verify that user can add a new address into account at Account Management page
=end

locale = General::LOCALE_CONST
if locale == 'IE' || locale == 'ROW'
  feature 'DST05 - Account Management - My profile - Add Address', js: true do
    scenario 'Skip adding Address on IE, ROW locales (Unsupported locale)' do
    end
  end
else
  atg_app_center_catalog_page = AtgAppCenterCatalogPage.new
  atg_login_register_page = nil
  atg_my_profile_page = nil
  cookie_session_id = nil

  feature 'DST05 - Account Management - My profile - Add Address', js: true do
    before :all do
      cookie_session_id = atg_app_center_catalog_page.load
    end

    context 'Print Session ID' do
      scenario '' do
        pending "***SESSION_ID: #{cookie_session_id}"
      end
    end

    context 'Add new Address to account' do
      scenario '1. Go to Login/Register page' do
        atg_login_register_page = atg_app_center_catalog_page.goto_login
        pending "***1. Go to Login/Register page (URL: #{atg_login_register_page.current_url})"
      end

      scenario "2. Register new account (Email: #{Account::EMAIL_GUEST_CONST})" do
        atg_my_profile_page = atg_login_register_page.register(
          General::FIRST_NAME_CONST,
          General::LAST_NAME_CONST,
          Account::EMAIL_GUEST_CONST,
          General::PASSWORD_CONST,
          General::PASSWORD_CONST
        )
      end

      scenario '3. Verify My Profile page displays' do
        expect(atg_my_profile_page.my_profile_page_exist?).to eq(true)
      end

      scenario '4. Go to My Profile > Account Information ' do
        atg_my_profile_page.goto_account_information
        pending "***4. Go to My Profile > Account Information (URL: #{atg_my_profile_page.current_url})"
      end

      scenario '5. Add new address information' do
        address = {
          first_name:BillingAddress::FIRST_NAME_CONST,
          last_name:BillingAddress::LAST_NAME_CONST,
          street: BillingAddress::STREET_CONST,
          city: BillingAddress::CITY_CONST,
          state: BillingAddress::STATE_CONST,
          postal: BillingAddress::POSTAL_CONST,
          phone_number: BillingAddress::PHONE_NUMBER_CONST
        }

        atg_my_profile_page.add_new_address address
      end

      scenario "6. Verify Address information (Address: #{BillingAddress::EX_ADDRESS_INFO})" do
        expect(atg_my_profile_page.address_info).to eq(BillingAddress::EX_ADDRESS_INFO)
      end
    end

    after :all do
      atg_my_profile_page.delete_all_addresses
    end
  end
end