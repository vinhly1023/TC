require File.expand_path('../../spec_helper', __FILE__)

=begin
  Verify User must pay remaining balance of the purchase (not covered by account balance) with a Credit card
  Total should equal the total amount minus the remainder of the account balance
=end

env = General::ENV_CONST
locale = General::LOCALE_CONST

if locale == 'IE' || locale == 'ROW'
  feature 'DST26 - Checkout - Purchase Flow - Account Balance + Saved CC', js: true do
    scenario 'Skip check-out with Credit Card on IE, ROW locales (Unsupported locale)' do
    end
  end
elsif env == 'PROD'
  feature 'DST26 - Checkout - Purchase Flow - Account Balance + Saved CC' do
    scenario 'Skip check-out with Credit Card on Production env' do
    end
  end
else
  require 'atg_app_center_catalog_page'
  require 'atg_login_register_page'

  # initial variables
  atg_app_center_catalog_page = AtgAppCenterCatalogPage.new
  atg_my_profile_page = AtgMyProfilePage.new
  atg_review_page = AtgCheckOutReviewPage.new
  atg_checkout_page = nil
  atg_confirmation_page = nil
  atg_checkout_payment_page = nil

  # Account information
  email = Account::EMAIL_GUEST_CONST

  # Checkout information
  order_id = ''
  product_info = smoke_atg_data('web_product3', General::LOCALE_CONST)
  redeem_pins = ''

  feature 'DST26 - Checkout - Purchase Flow - Account Balance + Saved CC', js: true do
    next unless pin_available?(env, locale)

    check_status_url_and_print_session atg_app_center_catalog_page

    context 'Create new account and link to all devices' do
      create_account_and_link_all_devices(
        General::FIRST_NAME_CONST,
        General::LAST_NAME_CONST,
        email,
        General::PASSWORD_CONST,
        General::PASSWORD_CONST
      )
    end

    context 'Add new Credit Card to Account' do
      scenario '1. Go to My Profile > Account Information ' do
        atg_my_profile_page.goto_account_information
      end

      scenario '2. Enter Credit Card and Billing Address' do
        credit_card = {
          card_number: CreditCard::CARD_NUMBER_CONST,
          cart_type: CreditCard::CARD_TYPE_CONST,
          card_name: CreditCard::NAME_ON_CARD_CONST,
          exp_month: CreditCard::EXP_MONTH_NAME_CONST,
          exp_year: CreditCard::EXPIRED_YEAR_CONST,
          security_code: CreditCard::SECURITY_CARD_CONST
        }

        billing_address = {
          street: BillingAddress::STREET_CONST,
          city: BillingAddress::CITY_CONST,
          state: BillingAddress::STATE_CONST,
          postal: BillingAddress::POSTAL_CONST,
          phone_number: BillingAddress::PHONE_NUMBER_CONST
        }

        atg_my_profile_page.add_new_credit_card_with_new_billing(credit_card, billing_address)
      end

      scenario "3. Verify Billing Address information (Address: #{BillingAddress::EX_BILLING_ADDRESS_INFO})" do
        expect(atg_my_profile_page.address_info).to eq(BillingAddress::EX_BILLING_ADDRESS_INFO)
      end

      scenario "4. Verify Payments information (Payment: #{CreditCard::EX_PAYMENT_INFO_CONST})" do
        expect(atg_my_profile_page.payment_info).to eq(CreditCard::EX_PAYMENT_INFO_CONST)
      end
    end

    context 'Add a product to Cart and go to Checkout page' do
      scenario '1. Go to App Center page' do
        atg_app_center_catalog_page.load
        pending "***1. Go to App Center page (URL: #{atg_app_center_catalog_page.current_url})"
      end

      scenario "2. Search App (Product ID = #{product_info[:prod_id]})" do
        atg_app_center_catalog_page.search_app product_info[:prod_id]
      end

      scenario '3. Add a digital item or items to the cart that so that the subtotal is greater than the user\'s account balance' do
        atg_app_center_catalog_page.add_app_to_cart product_info[:prod_id]
      end

      scenario '4. Go to App Center Cart page' do
        atg_checkout_page = atg_app_center_catalog_page.go_to_cart_page
      end
    end

    context 'Go to Payment page and enter Value code' do
      before :each do
        skip 'Blocked: Error while redeem code. Please re-check!' if redeem_pins == []
      end

      scenario '1. Click on \'Check Out\' button to go to Payment page' do
        atg_checkout_payment_page = atg_checkout_page.go_to_payment
        pending "***2. Go to Payment page (URL:#{atg_checkout_payment_page.current_url})"
      end

      scenario '2. Redeem Code at Check Out Payment page' do
        redeem_pins = atg_checkout_payment_page.redeem_code(env, locale, 1)

        fail 'Error while redeem PINs. Please re-check!' if redeem_pins == []
        pending "***2. Redeem Code at Check Out Payment page (#{redeem_pins})"
      end

      scenario '3. Click on Continue button to go to Review page' do
        atg_checkout_payment_page.click_continue_button
      end

      scenario '4. Place order and go to Confirmation page' do
        atg_confirmation_page = atg_review_page.place_order

        fail atg_confirmation_page if atg_confirmation_page.is_a?(String)

        order_id = atg_confirmation_page.order_number
        atg_confirmation_page.record_order_id(email, order_id)
      end

      scenario 'Order number' do
        pending("***Order number = #{order_id})")
      end
    end

    context 'Verify information on Confirmation page' do
      before :each do
        skip 'Blocked: Error while redeem code. Please re-check!' if redeem_pins == []
      end

      scenario '1. Verify Payment Method include Credit Card' do
        expect(atg_confirmation_page.payment_method?(CreditCard::CARD_TYPE_CONST)).to eq(true)
      end

      scenario '2. Verify Payment Method include Account Balance' do
        expect(atg_confirmation_page.payment_method?('Account Balance')).to eq(true)
      end

      scenario '3. Verify Total equal the total amount minus the remainder of the account balance' do
        order_total = Title.price_to_float(atg_confirmation_page.order_total)
        account_balance = Title.price_to_float(atg_confirmation_page.account_balance)
        sale_tax = Title.price_to_float(atg_confirmation_page.sale_tax)
        order_subtotal = Title.price_to_float(atg_confirmation_page.sub_total)

        expect(order_total).to eq(order_subtotal - account_balance + sale_tax)
      end
    end
  end
end
