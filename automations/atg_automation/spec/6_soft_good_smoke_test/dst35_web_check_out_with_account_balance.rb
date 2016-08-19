require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_catalog_page'
require 'atg_app_center_cart_page'
require 'atg_checkout_review_page'
require 'mail_home_page'
require 'mail_detail_page'

=begin
  Verify that user can check out successfully when redeem Code at Check Out
=end

atg_app_center_catalog_page = AtgAppCenterCatalogPage.new
atg_checkout_page = AtgAppCenterCartPage.new
atg_review_page = AtgCheckOutReviewPage.new
atg_checkout_payment_page = nil
atg_confirmation_page = nil
mail_home_page = HomePageMail.new
mail_detail_page = nil

# Account information
email = Account::EMAIL_GUEST_CONST

# Product checkout info
env = General::ENV_CONST
locale = General::LOCALE_CONST
currency = Title.locale_to_currency locale
prod_info = smoke_atg_data('web_product1', General::LOCALE_CONST)
overview_info = {}
pin = {}
payment_method = ''
redeem_pins = ''
ab_on_confirmation_page = ''

feature 'Web - Checkout with Account Balance', js: true do
  next unless pin_available?(env, locale)

  check_status_url_and_print_session atg_app_center_catalog_page

  com_server

  context 'Create new account and link to all devices' do
    create_account_and_link_all_devices(
      General::FIRST_NAME_CONST,
      General::LAST_NAME_CONST,
      email,
      General::PASSWORD_CONST,
      General::PASSWORD_CONST
    )
  end

  context 'Add Product to Cart page' do
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
  end

  context 'Check out with Redeem Value code' do
    before :each do
      skip 'Blocked: Error while redeem PINs' if redeem_pins == []
    end

    scenario '1. Go to App Center Cart page' do
      atg_checkout_page = atg_app_center_catalog_page.go_to_cart_page
    end

    scenario '2. Click on \'Check Out\' button to go to Payment page' do
      atg_checkout_payment_page = atg_checkout_page.go_to_payment
      pending "***2. Go to Payment page (URL:#{atg_checkout_payment_page.current_url})"
    end

    scenario '3. Redeem Code at Check Out Payment page' do
      redeem_pins = atg_checkout_payment_page.redeem_code(env, locale)

      fail 'Error while redeem PINs. Please re-check!' if redeem_pins == []
      pending "***3. Redeem Code at Check Out Payment page (#{redeem_pins})"
    end

    scenario '4. Click on \'Place Order\' button on Review page' do
      atg_confirmation_page = atg_review_page.place_order
    end
  end

  context 'Verify Checkout information on Confirmation page' do
    before :each do
      skip 'Blocked: Error while redeem PINs' if redeem_pins == []
    end

    scenario '1 Get Order information on Confirmation page' do
      ab_on_confirmation_page = atg_confirmation_page.account_balance.split(currency)[1]
      overview_info = atg_confirmation_page.order_overview_info
      atg_confirmation_page.record_order_id(email, overview_info[:order_id])

      pending "***1 Get Check Out information on Confirmation page (Order ID = #{overview_info[:order_id]})"
    end

    scenario '2. Verify Order Completed message' do
      expect(overview_info[:complete]).to match(ProductInformation::ORDER_COMPLETE_MESSAGE_CONST)
    end

    scenario '3. Verify Order Total should be 0.00' do
      order_total = atg_confirmation_page.order_total_cost_txt.text
      expect(order_total).to include('0.00')
    end

    scenario "4. Verify Payment method is 'Account Balance'" do
      payment_method = "Account Balance #{currency}#{ab_on_confirmation_page}"
      expect(overview_info[:details]).to include("Payment Method #{payment_method}")
    end
  end

  context 'Verify Order information on Email page' do
    before :each do
      skip 'Blocked: Error while redeem PINs' if redeem_pins == []
    end

    scenario '1. Go to Email page' do
      mail_detail_page = mail_home_page.go_to_mail_detail email
    end

    scenario '2. Verify Order number' do
      expect(mail_detail_page.order_number_txt.text).to include(overview_info[:order_id])
    end

    scenario '3. Verify Payment method is Account Balance' do
      expect(mail_detail_page.payment_method_txt.text).to eq(payment_method)
    end
  end
end
