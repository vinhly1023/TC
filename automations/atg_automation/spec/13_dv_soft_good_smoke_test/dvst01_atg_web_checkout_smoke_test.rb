require File.expand_path('../../spec_helper', __FILE__)

=begin
  Device stores check-out smoke test
=end

require 'atg_app_center_catalog_page'
require 'atg_dv_app_center_page'
require 'atg_dv_check_out_page'
require 'atg_dv_check_out_review_page'
require 'atg_dv_check_out_confirmation_page'
require 'atg_dv_my_account_page'
require 'mail_home_page'
require 'mail_detail_page'

env = General::ENV_CONST
locale = General::LOCALE_CONST

# Account information
first_name = General::FIRST_NAME_CONST
last_name = General::LAST_NAME_CONST
email = Account::EMAIL_GUEST_CONST
password = General::PASSWORD_CONST

# Check out information
device_store = Data::DEVICE_STORE_CONST
payment_method = Data::PAYMENT_TYPE_CONST
location = ProductInformation::ACC_LOCATION_CONST
order_completed_msg = ProductInformation::MSG_ORDER_COMPLETED_CONST
order_number_title = ProductInformation::ORDER_NUMBER_TITLE_CONST
sub_total_title = ProductInformation::SUB_TOTAL_TITLE_CONST
purchase_total_title = ProductInformation::PURCHASE_TOTAL_TITLE_CONST
account_balance_title = ProductInformation::AB_TITLE_CONST
tax = ProductInformation::TAX_TITLE_CONST

if ['LFC', 'Galaxy S4', 'iPhone 6'].include?(device_store)
  url = Title.url_mapping(URL::ATG_DV_APP_CENTER_URL % [env.downcase, General::LOCATION_URL_CONST])
else
  url = Title.url_mapping(URL::ATG_DV_APP_CENTER_URL % [env.downcase, General::LOCATION_URL_CONST] + "emailAddress=#{email}")
end

AtgDvAppCenterPage.set_url url
atg_dv_app_center_page = AtgDvAppCenterPage.new
atg_dv_review_page = AtgDvCheckOutReviewPage.new
atg_dv_my_account_page = AtgDvMyAccountPage.new
mail_home_page = HomePageMail.new
atg_dv_check_out_page = nil
atg_dv_confirmation_page = nil
cookie_session_id = ''

# Checkout info
order_review_info = {}
order_confirmation_info = {}
order_email_info = {}
checkout_status = true

if payment_method == 'CC + Balance'
  product_info = locale.upcase.include?('FR') ? smoke_atg_data('device_product2/french', locale) : smoke_atg_data('device_product2/english', locale)
else # Account Balance, Credit Card
  product_info = locale.upcase.include?('FR') ? smoke_atg_data('device_product1/french', locale) : smoke_atg_data('device_product1/english', locale)
end

describe "ATG - Checkout Smoke Test - #{device_store} - #{payment_method} - #{env}", js: true do
  next unless device_locale_payment_method_compatible?(device_store, payment_method, locale)

  if payment_method == 'Account Balance' || payment_method == 'CC + Balance'
    next unless pin_available?(env, locale)
  end

  context 'Pre-Condition: Register new account and claim to devices' do
    create_account_and_claim_devices_via_webservice(ServicesInfo::CONST_CALLER_ID, first_name, last_name, email, password, location)
  end

  context "Checkout product with #{payment_method}" do
    before :each do
      skip 'BLOCKED: Error while checking out app' unless checkout_status
    end

    scenario '1. Go to App Center Home page' do
      cookie_session_id = atg_dv_app_center_page.load
      pending "***1. Go to Device Store App Center page (URL: #{url})"
    end

    scenario '' do
      pending "***SESSION ID: #{cookie_session_id}"
    end

    scenario "2. Add App to Cart (Product ID: #{product_info[:prod_id]} - Title: #{product_info[:catalog_title]})" do
      atg_dv_app_center_page.dv_search_and_add_app_to_cart(product_info[:prod_id], device_store)
    end

    scenario '3. Go to Check Out page' do
      atg_dv_check_out_page = atg_dv_app_center_page.dv_go_to_check_out_page device_store
      pending "***3. Go to Check Out page (URL: #{atg_dv_check_out_page.current_url})"
    end

    scenario '4. Go to Payment page' do
      atg_dv_payment_page = atg_dv_check_out_page.dv_go_to_payment_page(email, password, device_store)
      pending "***4. Go to Payment page (URL: #{atg_dv_payment_page.current_url})"
    end

    dv_check_out_method(payment_method, device_store)

    scenario '6. Get order information on Review page' do
      checkout_status = atg_dv_review_page.play_order_displayed? device_store
      fail 'Fails to check out App. Please re-check!' unless checkout_status

      order_review_info = atg_dv_review_page.dv_order_review_info device_store
    end

    scenario '7. Click on Place Order button' do
      # Click on Place Order button
      atg_dv_confirmation_page = atg_dv_review_page.dv_place_order device_store

      # Get Order information on Confirmation page
      order_confirmation_info = atg_dv_confirmation_page.dv_order_confirmation_info device_store
    end

    scenario '8. Get Order number' do
      pending "***8. Get Order number (#{order_confirmation_info[:order_id]})"
    end
  end

  context 'Verify information on Confirmation page' do
    before :each do
      skip 'BLOCKED: Error while checking out app' unless checkout_status
    end

    scenario "1. Verify complete order message (#{order_completed_msg})" do
      expect(order_confirmation_info[:message]).to match(order_completed_msg)
    end

    scenario '2. Verify Order Sub total' do
      expect(order_confirmation_info[:order_detail][:sub_total]).to eq(order_review_info[:sub_total])
      pending "***2. Verify Order Sub Total (#{order_review_info[:sub_total]})"
    end

    scenario '3. Verify Order Tax' do
      expect(order_confirmation_info[:order_detail][:tax]).to include(order_review_info[:tax])
      pending "***3. Verify Order Tax (#{order_review_info[:tax]})"
    end

    scenario '4. Verify Order Total' do
      expect(order_confirmation_info[:order_detail][:order_total]).to eq(order_review_info[:order_total])
      pending "***4. Verify Order Total (#{order_review_info[:order_total]})"
    end

    unless payment_method == 'Credit Card'
      scenario '5. Verify Account Balance' do
        expect(order_confirmation_info[:order_detail][:account_balance]).to eq(order_review_info[:account_balance])
        pending "***5. Verify Account Balance (#{order_review_info[:account_balance]})"
      end
    end
  end

  context 'Verify order number displays on My Account page' do
    before :each do
      skip 'BLOCKED: Error while checking out app' unless checkout_status
    end

    scenario '1. Go to My Account page' do
      atg_dv_confirmation_page.dv_go_to_my_account(device_store, password)
      pending "***1. Go to My Account page (URL: #{atg_dv_my_account_page.current_url})"
    end

    scenario '2. Verify Order number' do
      expect(atg_dv_my_account_page.dv_order_number_exists?(order_confirmation_info[:order_id])).to eq(true)
      pending "***2. Verify Order number (#{order_confirmation_info[:order_id]})"
    end
  end

  context 'Verify information on Email page' do
    before :each do
      skip 'BLOCKED: Error while checking out app' unless checkout_status
    end

    scenario '1. Go to Email page (URL: https://www.guerrillamail.com/inbox)' do
      mail_detail_page = mail_home_page.go_to_mail_detail email
      order_email_info = mail_detail_page.order_email_info
    end

    scenario '2. Verify Order number' do
      expect(order_email_info[:order_number]).to eq("#{order_number_title} #{order_confirmation_info[:order_id]}")
      pending "***2. Verify Order number (#{order_confirmation_info[:order_id]})"
    end

    scenario '3. Verify Order Sub total' do
      expect(order_email_info[:order_sub_total]).to eq("#{sub_total_title} #{order_confirmation_info[:order_detail][:sub_total]}")
      pending "***3. Verify Order Sub total (#{order_confirmation_info[:order_detail][:sub_total]})"
    end

    scenario '4. Verify Tax' do
      if order_email_info[:tax] == ''
        expect(order_email_info[:tax]).to eq(order_confirmation_info[:order_detail][:tax])
      else
        expect(order_email_info[:tax]).to eq("#{tax} #{order_confirmation_info[:order_detail][:tax]}")
      end

      pending "***4. Verify Tax (#{order_confirmation_info[:order_detail][:tax]})"
    end

    scenario '5. Verify Purchase Total' do
      expect(order_email_info[:order_total]).to eq("#{purchase_total_title} #{order_confirmation_info[:order_detail][:order_total]}")
      pending "***5. Verify Purchase Total (#{order_confirmation_info[:order_detail][:order_total]})"
    end

    unless payment_method == 'Credit Card'
      scenario '6. Verify Account Balance' do
        expect(order_email_info[:account_balance]).to eq("#{account_balance_title} #{order_confirmation_info[:order_detail][:account_balance]}")
        pending "***6. Verify Account Balance (#{order_confirmation_info[:order_detail][:account_balance]})"
      end
    end
  end
end
