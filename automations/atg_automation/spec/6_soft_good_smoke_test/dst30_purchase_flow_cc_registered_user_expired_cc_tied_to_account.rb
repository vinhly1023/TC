require File.expand_path('../../spec_helper', __FILE__)

=begin
  Verify that user can't checkout when entering a Credit Card with the expiration date in the past
=end

env = General::ENV_CONST
locale = General::LOCALE_CONST

if locale == 'IE' || locale == 'ROW'
  feature 'DST30: Check out - Purchase Flow - Credit Card - Registered User - Expired CC tied to account', js: true do
    scenario 'Skip check-out with Credit Card on IE, ROW locales (Unsupported locale)' do
    end
  end
elsif env == 'PROD'
  feature 'DST30: Check out - Purchase Flow - Credit Card - Registered User - Expired CC tied to account' do
    scenario 'Skip check-out with Credit Card on Production env' do
    end
  end
else
  require 'atg_app_center_catalog_page'
  require 'atg_login_register_page'

  # initial variables
  atg_app_center_catalog_page = AtgAppCenterCatalogPage.new
  atg_checkout_page = nil
  atg_checkout_payment_page = nil
  prod_info = smoke_atg_data('web_product1', General::LOCALE_CONST)

  # Account information
  first_name = General::FIRST_NAME_CONST
  last_name = General::LAST_NAME_CONST
  email = Account::EMAIL_GUEST_CONST
  password = General::PASSWORD_CONST

  feature 'DST30: Check out - Purchase Flow - Credit Card - Registered User - Expired CC tied to account', js: true do
    check_status_url_and_print_session atg_app_center_catalog_page

    context 'Create new account and link to all devices' do
      create_account_and_link_all_devices(first_name, last_name, email, password, password)
    end

    context 'Check out product with an Expired Credit Card' do
      scenario '1. Go to App Center page' do
        atg_app_center_catalog_page.load
        pending "***1. Go to App Center page (URL: #{atg_app_center_catalog_page.current_url})"
      end

      scenario "2. Search App (Product ID = #{prod_info[:prod_id]})" do
        atg_app_center_catalog_page.search_app prod_info[:prod_id]
      end

      scenario '3. Add to Cart from the App Center Catalog Page' do
        atg_app_center_catalog_page.add_app_to_cart prod_info[:prod_id]
      end

      scenario '4. Go to App Center Cart page' do
        atg_checkout_page = atg_app_center_catalog_page.go_to_cart_page
        pending "***3. Go to App Center Cart page (URL: #{atg_app_center_catalog_page.current_url})"
      end

      scenario '5. Proceed through Checkout to the payment page' do
        atg_checkout_payment_page = atg_checkout_page.go_to_payment
      end

      scenario '6. Select the card with the expiration date in the past and click Continue' do
        credit_card = {
          card_number: CreditCard::CARD_NUMBER_CONST,
          card_name: CreditCard::NAME_ON_CARD_CONST,
          exp_month: CreditCard::EXP_MONTH_NAME_CONST,
          exp_year: '2016',
          security_code: CreditCard::SECURITY_CARD_CONST
        }

        billing_address = {
          street: BillingAddress::STREET_CONST,
          city: BillingAddress::CITY_CONST,
          state: BillingAddress::STATE_CONST,
          postal: BillingAddress::POSTAL_CONST,
          phone_number: BillingAddress::PHONE_NUMBER_CONST
        }

        atg_checkout_payment_page.add_credit_card(credit_card, billing_address)
      end

      scenario '7. Verify \'Select a valid expiration date.\' error appears' do
        expect(atg_checkout_payment_page.invalid_exp_date_text).to eq('Select a valid expiration date.')
      end
    end
  end
end
