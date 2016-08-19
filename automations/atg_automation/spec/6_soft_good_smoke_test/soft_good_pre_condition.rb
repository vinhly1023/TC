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

# Account info
full_email = Account::EMAIL_GUEST_FULL_CONST
balance_email = Account::EMAIL_BALANCE_CONST
empty_email = Account::EMAIL_GUEST_EMPTY_CONST
password = General::PASSWORD_CONST

feature 'Pre condition - Create new accounts', js: true do
  check_status_url_and_print_session atg_app_center_catalog_page

  context 'Create new account with full information' do
    create_account_and_link_all_devices(
      General::FIRST_NAME_CONST,
      General::LAST_NAME_CONST,
      full_email,
      password,
      password)

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

    scenario '7. Add new Credit Card and Billing Address' do
      if General::LOCALE_CONST == 'IE' || General::LOCALE_CONST == 'ROW'
        pending '***Skip adding Credit Card for IE, ROW locales (Unsupported)'
      elsif General::ENV_CONST == 'PROD'
        pending '***Skip adding Credit Card for Production environment (Unsupported)'
      else
        credit_card = {
          card_number: CreditCard::CARD_NUMBER_CONST,
          cart_type: CreditCard::CARD_TYPE_CONST,
          card_name: CreditCard::NAME_ON_CARD_CONST,
          exp_month: CreditCard::EXP_MONTH_NAME_CONST,
          exp_year: CreditCard::EXPIRED_YEAR_CONST,
          security_code: CreditCard::SECURITY_CARD_CONST
        }

        atg_my_profile_page.add_new_credit_card_with_new_billing(credit_card)
        update_info_account(full_email, nil, credit_card[:card_number])
      end
    end

    scenario '8. Log out' do
      atg_my_profile_page.logout
    end
  end

  context 'Create new account with full information (Use for testing with Acc Balance only)' do
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

    scenario '7. Add new Credit Card and Billing Address' do
      if General::LOCALE_CONST == 'IE' || General::LOCALE_CONST == 'ROW'
        pending '***Skip adding Credit Card for IE, ROW locales (Unsupported)'
      elsif General::ENV_CONST == 'PROD'
        pending '***Skip adding Credit Card for Production environment (Unsupported)'
      else
        credit_card = {
          card_number: CreditCard::CARD_NUMBER_CONST,
          cart_type: CreditCard::CARD_TYPE_CONST,
          card_name: CreditCard::NAME_ON_CARD_CONST,
          exp_month: CreditCard::EXP_MONTH_NAME_CONST,
          exp_year: CreditCard::EXPIRED_YEAR_CONST,
          security_code: CreditCard::SECURITY_CARD_CONST
        }

        atg_my_profile_page.add_new_credit_card_with_new_billing credit_card
        update_info_account(balance_email, nil, credit_card[:card_number])
      end
    end

    scenario '8. Log out' do
      atg_my_profile_page.logout
    end
  end

  context 'Create new account with empty information' do
    scenario '1. Go to register/login page' do
      atg_login_register_page = atg_app_center_catalog_page.goto_login
    end

    scenario '2. Register a new account' do
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
