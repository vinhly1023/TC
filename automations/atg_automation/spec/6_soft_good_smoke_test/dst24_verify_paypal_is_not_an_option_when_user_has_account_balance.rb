require File.expand_path('../../spec_helper', __FILE__)

=begin
  Verify Paypal is not an option when user has account balance
=end

env = General::ENV_CONST
locale = General::LOCALE_CONST

require 'atg_app_center_catalog_page'
require 'atg_login_register_page'
require 'atg_my_profile_page'

# initial variables
atg_app_center_catalog_page = AtgAppCenterCatalogPage.new
atg_my_profile_page = AtgMyProfilePage.new
atg_checkout_page = nil
atg_checkout_payment_page = nil

# Account information
email = Account::EMAIL_GUEST_CONST

# Checkout information
product_info = smoke_atg_data('web_product3', General::LOCALE_CONST)
account_balance = ''
pin = ''
has_available_app = true
redeem_status = true

feature 'DST24 - Verify Paypal is not an option when user has account balance', js: true do
  next unless pin_available?(env, locale)

  check_status_url_and_print_session atg_app_center_catalog_page

  context 'Precondition - Create new account and link to all devices' do
    context 'Create new account and link to all devices' do
      create_account_and_link_all_devices(
        General::FIRST_NAME_CONST,
        General::LAST_NAME_CONST,
        email,
        General::PASSWORD_CONST,
        General::PASSWORD_CONST
      )
    end
  end

  context 'Redeem value card' do
    scenario '1. Click on Redeem Code link' do
      atg_my_profile_page.mouse_hover_my_account_link
      atg_my_profile_page.click_redeem_code_link
    end

    scenario '2. Redeem a value code' do
      pin = atg_my_profile_page.redeem_code(env, locale)

      if pin.nil?
        redeem_status = false
        fail 'Error while redeem code. Please re-check!'
      end

      pending "***3. Redeem a value code: '#{pin}'"
    end
  end

  context 'Add to Cart from the App Center Catalog Page' do
    before :each do
      skip 'Error while redeem code. Please re-check!' unless redeem_status
      skip 'The price of selected app is less than account balance' unless has_available_app
    end

    scenario '1. Go to App Center home page' do
      atg_app_center_catalog_page.load
      pending("***1. Go to App Center home page (URL: #{atg_app_center_catalog_page.current_url})")
    end

    scenario '2. Get current account balance' do
      atg_app_center_catalog_page.mouse_hover_my_account_link
      account_balance = atg_app_center_catalog_page.account_balance_under_my_profile
    end

    scenario "3. Search App (Product ID = #{product_info[:prod_id]})" do
      if Title.price_to_float(account_balance) > Title.price_to_float(product_info[:price])
        has_available_app = false
        fail 'The price of selected app is less than account balance'
      end

      atg_app_center_catalog_page.search_app product_info[:prod_id]
    end

    scenario '4. Add App to Cart' do
      atg_app_center_catalog_page.add_app_to_cart product_info[:prod_id]
    end

    scenario '5. Go to App Center check out page' do
      atg_checkout_page = atg_app_center_catalog_page.go_to_cart_page
    end
  end

  context 'Verify PayPal button does not display on Payment page' do
    before :each do
      skip 'Error while redeem code. Please re-check!' unless redeem_status
      skip 'The price of selected app is less than account balance' unless has_available_app
    end

    scenario '1. Go to Payment page' do
      atg_checkout_payment_page = atg_checkout_page.go_to_payment
      pending("***1. Go to Payment page #{atg_checkout_payment_page.current_url}")
    end

    scenario "2. Verify the Account Balance amount is #{account_balance}" do
      acc_balance_in_payment = atg_checkout_payment_page.account_balance.text
      expect(acc_balance_in_payment).to include(account_balance)
    end

    scenario '3. Verify the cart total is greater Account Balance' do
      expect(Title.price_to_float(atg_checkout_payment_page.cart_total.text)).to be > Title.price_to_float(account_balance)
    end

    scenario '4. Verify PayPal button does not display on the Payment page' do
      expect(atg_checkout_payment_page.paypal_button_exist?).to eq(false)
    end
  end
end
