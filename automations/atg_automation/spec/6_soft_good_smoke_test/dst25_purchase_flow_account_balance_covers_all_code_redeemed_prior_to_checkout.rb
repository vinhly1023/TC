require File.expand_path('../../spec_helper', __FILE__)

=begin
  Verify that user can check out successfully with an existing account by using Redeem Code
=end

require 'atg_app_center_catalog_page'
require 'atg_app_center_checkout_page'
require 'atg_login_register_page'
require 'atg_my_profile_page'
require 'mail_home_page'
require 'mail_detail_page'

atg_app_center_catalog_page = AtgAppCenterCatalogPage.new
atg_app_center_catalog_page = AtgAppCenterCatalogPage.new
atg_checkout_page = AtgAppCenterCheckOutPage.new
atg_review_page = AtgCheckOutReviewPage.new
mail_home_page = HomePageMail.new
atg_login_register_page = nil
atg_my_profile_page = nil
atg_confirmation_page = nil
mail_detail_page = nil

# Account information
env = General::ENV_CONST
locale = General::LOCALE_CONST
email = Account::EMAIL_EXIST_BALANCE_CONST
password = General::PASSWORD_CONST

# Product checkout info
currency = Title.locale_to_currency locale
ab_before_redeem = ab_after_redeem = ab_after_place_order = ab_on_confirmation_page = ''
product_info = smoke_atg_data('web_product4', General::LOCALE_CONST)
pin = {}
overview_info = {}
payment_method = ''
has_available_app = true
redeem_status = true

feature 'DST25 - Checkout - Purchase Flow - Account Balance covers all - Code redeemed prior to checkout', js: true do
  next unless pin_available?(env, locale)

  check_status_url_and_print_session atg_app_center_catalog_page

  com_server

  context 'Login to an existing account' do
    scenario '1. Go to Login/Register page' do
      atg_login_register_page = atg_app_center_catalog_page.goto_login
    end

    scenario "2. Login to an existing account (Email: #{email})" do
      atg_my_profile_page = atg_login_register_page.login(email, password)
    end

    scenario '3. Delete all existing items in Cart page' do
      if atg_app_center_catalog_page.cart_item_number > 0
        atg_checkout_page = atg_app_center_catalog_page.go_to_cart_page
        atg_checkout_page.clean_cart_page
      end
    end
  end

  context 'Redeem Value Card' do
    before :each do
      skip 'Blocked: Error while redeeming Value Card. Please re-check!' unless redeem_status
    end

    scenario '1. Get existing Account Balance before redeem' do
      atg_my_profile_page.mouse_hover_my_account_link
      ab_before_redeem = atg_my_profile_page.account_balance_under_my_profile
      pending "***1. Account Balance before redeem (#{ab_before_redeem})"
    end

    scenario '2. Click on Redeem Code link' do
      atg_my_profile_page.click_redeem_code_link
    end

    scenario '3. Redeem a Value Code' do
      pin = atg_my_profile_page.redeem_code(env, locale)

      if pin.nil?
        redeem_status = false
        fail 'Error while redeeming Value Code. Please re-check!'
      end

      pending "***3. Redeem a value code: '#{pin}'"
    end

    scenario '4. Get Account Balance after redeem' do
      atg_my_profile_page.mouse_hover_my_account_link
      ab_after_redeem = atg_my_profile_page.account_balance_under_my_profile
      pending "***4. Account Balance after redeem (#{ab_after_redeem})"
    end

    scenario '5. Verify Account Balance is changed correctly' do
      expect(Title.cal_account_balance(ab_before_redeem, pin['amount'], locale)).to eq(ab_after_redeem)
    end
  end

  context 'Add App to Cart and go to Checkout page' do
    before :each do
      skip 'Blocked: Fail to redeem Value Code' unless redeem_status
      skip 'Blocked: The price of selected app is greater than account balance' unless has_available_app
    end

    scenario '1. Go to App Center page' do
      atg_app_center_catalog_page.load
      pending "***1. Go to App Center page (URL: #{atg_app_center_catalog_page.current_url})"
    end

    scenario "2. Search App (Product ID = #{product_info[:prod_id]})" do
      if Title.price_to_float(ab_after_redeem) < Title.price_to_float(product_info[:price])
        has_available_app = false
        fail 'The price of selected app is greater than account balance'
      end

      atg_app_center_catalog_page.search_app product_info[:prod_id]
    end

    scenario '3. Add App to Cart' do
      atg_app_center_catalog_page.add_app_to_cart product_info[:prod_id]
    end

    scenario '4. Go to Check Out page' do
      atg_checkout_page = atg_app_center_catalog_page.go_to_cart_page
    end
  end

  context 'Click Check Out button and verify Payment page is skipped' do
    before :each do
      skip 'Blocked: Fail to redeem Value Code' unless redeem_status
      skip 'Blocked: The price of selected app is greater than account balance' unless has_available_app
    end

    scenario '1. Click on Check Out button' do
      atg_checkout_page.go_to_payment
    end

    scenario '2. Verify Payment page is skipped' do
      expect(atg_review_page.review_page_exist?).to eq(true)
    end

    scenario '3. Go to Review page' do
      atg_confirmation_page = atg_review_page.place_order
    end
  end

  context 'Verify information on Confirmation page' do
    before :each do
      skip 'Blocked: Fail to redeem Value Code' unless redeem_status
      skip 'Blocked: The price of selected app is greater than account balance' unless has_available_app
    end

    scenario 'Go to Confirmation page' do
      ab_on_confirmation_page = atg_confirmation_page.account_balance.split(currency)[1]
      overview_info = atg_confirmation_page.order_overview_info
      atg_confirmation_page.record_order_id(email, overview_info[:order_id])
    end

    scenario '1. Verify complete order message' do
      expect(overview_info[:complete]).to match(ProductInformation::ORDER_COMPLETE_MESSAGE_CONST)
    end

    scenario '2. Verify Order detail info' do
      expect(overview_info[:details]).to include('Order Details Digital Download Items Price')
    end

    scenario '3. Verify Order total should be 0.00' do
      order_total = atg_confirmation_page.order_total_cost_txt.text
      expect(order_total).to include('0.00')
    end

    scenario '4. Verify My Download Credits in the My Account Dropdown displays accurate' do
      # Work around on PROD env, the My Account menu does not show
      atg_confirmation_page.show_all_account_menus
      ab_after_place_order = Title.price_to_float(atg_confirmation_page.account_balance_under_my_profile)
      expect(ab_after_place_order).to eq(Title.price_to_float(ab_after_redeem) - Title.price_to_float(ab_on_confirmation_page))
    end

    scenario "5. Verify Payment method is 'Account Balance'" do
      payment_method = "Account Balance #{currency}#{ab_on_confirmation_page}"
      expect(overview_info[:details]).to include("Payment Method #{payment_method}")
    end
  end

  context 'Verify information on Email page' do
    before :each do
      skip 'Blocked: Fail to redeem Value Code' unless redeem_status
      skip 'Blocked: The price of selected app is greater than account balance' unless has_available_app
    end

    scenario '1. Go to Email page' do
      mail_detail_page = mail_home_page.go_to_mail_detail email
    end

    scenario '2. Verify Order number' do
      expect(mail_detail_page.order_number_txt.text).to include(overview_info[:order_id])
    end

    scenario '3. Verify Payment method' do
      expect(mail_detail_page.payment_method_txt.text).to eq(payment_method)
    end
  end
end
