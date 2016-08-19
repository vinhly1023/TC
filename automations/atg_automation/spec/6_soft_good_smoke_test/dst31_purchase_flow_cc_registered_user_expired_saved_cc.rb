require File.expand_path('../../spec_helper', __FILE__)

=begin
  Verify that user can't checkout with an account that has Expired Saved Credit Card
=end

env = General::ENV_CONST
locale = General::LOCALE_CONST

if locale == 'IE' || locale == 'ROW'
  feature 'DST31: Check out - Purchase Flow - Credit Card - Registered User - Expired Saved Credit Card', js: true do
    scenario 'Skip check-out with Credit Card on IE, ROW locales (Unsupported locale)' do
    end
  end
elsif env == 'PROD'
  feature 'DST31: Check out - Purchase Flow - Credit Card - Registered User - Expired Saved Credit Card' do
    scenario 'Skip check-out with Credit Card on Production env' do
    end
  end
else
  require 'atg_login_register_page'
  require 'atg_app_center_catalog_page'
  require 'atg_app_center_cart_page'
  require 'atg_app_center_checkout_page'
  require 'atg_checkout_payment_page'

  # initial variables
  atg_app_center_catalog_page = AtgAppCenterCatalogPage.new
  atg_app_center_cart_page = AtgAppCenterCartPage.new
  atg_checkout_payment_page = AtgCheckOutPaymentPage.new
  prod_info = smoke_atg_data('web_product1', General::LOCALE_CONST)

  # Account information
  email = Account::EMAIL_EXP_CREDIT_CARD_CONST
  password = General::PASSWORD_CONST

  feature 'DST31: Check out - Purchase Flow - Credit Card - Registered User - Expired Saved Credit Card', js: true do
    check_status_url_and_print_session atg_app_center_catalog_page

    context 'Pre-condition: Delete all items in Cart page' do
      scenario "1. Login to an existing account that has Credit Card (Email: #{email})" do
        atg_login_page = atg_app_center_catalog_page.goto_login
        atg_login_page.login(email, password)
      end

      scenario '2. Delete all items in Cart page' do
        if atg_app_center_catalog_page.cart_item_number > 0
          atg_app_center_catalog_page.go_to_cart_page
          atg_app_center_cart_page.clean_cart_page
        end
      end
    end

    context 'Check out product with an Expired Credit Card' do
      scenario '1. Go to App Center page' do
        atg_app_center_catalog_page.load
        pending "***1. Go to App Center page (URL: #{atg_app_center_catalog_page.current_url})"
      end

      scenario "2. Search App (Product ID = #{prod_info[:prod_id]})" do
        atg_app_center_catalog_page.search_app prod_info[:prod_id]
      end

      scenario '3. Add App to Cart' do
        atg_app_center_catalog_page.add_app_to_cart prod_info[:prod_id]
      end

      scenario '4. Go to App Center Cart page' do
        atg_app_center_cart_page = atg_app_center_catalog_page.go_to_cart_page
        pending "***4. Go to App Center Cart page (URL: #{atg_app_center_catalog_page.current_url})"
      end

      scenario '5. Go to Checkout to the payment page' do
        atg_checkout_payment_page = atg_app_center_cart_page.go_to_payment
        pending "***5. Go to Checkout to the payment page (URL: #{atg_checkout_payment_page.current_url})"
      end

      scenario '6. Fill in radio button of the saved credit card with an expired date' do
        atg_app_center_cart_page.select_credit_card
      end

      scenario '7. Verify Expired Credit Card Oops pop-up displays ' do
        expect(atg_checkout_payment_page.exp_credit_card_oops_popup_displays?).to eq(true)
      end

      scenario '8. Verify the text Expired Credit Card Oops pop-up' do
        expect(atg_checkout_payment_page.exp_credit_card_oops_text).to eq('Your credit card has expired. Please update your card information or select a different credit card.')
      end

      scenario '9. Close the Pop-up' do
        atg_checkout_payment_page.close_exp_credit_card_oops_popup
      end

      scenario '10. Verify User still stays on Payment page' do
        expect(atg_checkout_payment_page.payment_page_exist?).to eq(true)
      end
    end
  end
end
