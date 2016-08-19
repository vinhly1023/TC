require File.expand_path('../../spec_helper', __FILE__)

=begin
  Verify that user can check out successfully with a new account by using Credit Card payment method
=end

env = General::ENV_CONST
locale = General::LOCALE_CONST

if locale == 'IE' || locale == 'ROW'
  feature 'DST22 - Checkout - Purchase Flow - Credit Card - Registered User - Add Card at checkout', js: true do
    scenario 'Skip check-out with Credit Card on IE, ROW locales (Unsupported locale)' do
    end
  end
elsif env == 'PROD'
  feature 'DST22 - Checkout - Purchase Flow - Credit Card - Registered User - Add Card at checkout' do
    scenario 'Skip check-out with Credit Card on Production env' do
    end
  end
else
  require 'atg_app_center_catalog_page'
  require 'atg_login_register_page'
  require 'mail_home_page'
  require 'mail_detail_page'

  # initial variables
  atg_app_center_catalog_page = AtgAppCenterCatalogPage.new
  mail_home_page = HomePageMail.new
  mail_detail_page = nil
  atg_checkout_page = nil
  atg_checkout_payment_page = nil
  atg_review_page = nil
  atg_confirmation_page = nil
  atg_my_profile_page = nil

  # Account information
  email = Account::EMAIL_GUEST_CONST

  # Product checkout info
  currency = Title.locale_to_currency locale
  product_info = smoke_atg_data('web_product1', General::LOCALE_CONST)
  overview_info = {}
  total_price = ''
  order_total_price = ''
  payment_method = ''

  feature 'DST22 - Checkout - Purchase Flow - Credit Card - Registered User - Add Card at checkout', js: true do
    check_status_url_and_print_session atg_app_center_catalog_page

    context 'Create new account and link to all device' do
      create_account_and_link_all_devices(
        General::FIRST_NAME_CONST,
        General::LAST_NAME_CONST,
        email,
        General::PASSWORD_CONST,
        General::PASSWORD_CONST
      )
    end

    context 'Check out product with Credit Card' do
      before :each do
        skip 'Place order fails' if atg_confirmation_page.is_a?(String)
      end

      scenario '1. Go to App Center page' do
        atg_app_center_catalog_page.load
        pending "***1. Go to App Center page (URL: #{atg_app_center_catalog_page.current_url})"
      end

      scenario "2. Search App (Product ID = #{product_info[:prod_id]})" do
        atg_app_center_catalog_page.search_app product_info[:prod_id]
      end

      scenario '3. Add App to Cart' do
        atg_app_center_catalog_page.add_app_to_cart product_info[:prod_id]
      end

      scenario '4. Go to Check Out page' do
        atg_checkout_page = atg_app_center_catalog_page.go_to_cart_page
        pending("***4. Go to Check Out page (URL: #{atg_checkout_page.current_url})")
      end

      scenario '5. Go to Payment page' do
        atg_checkout_payment_page = atg_checkout_page.go_to_payment
        pending("***5. Go to Payment page (URL:#{atg_checkout_payment_page.current_url})")
      end

      scenario "6. Enter Credit Card and Billing address (CC Number: #{CreditCard::CARD_NUMBER_CONST})" do
        credit_card = {
          card_number: CreditCard::CARD_NUMBER_CONST,
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

        atg_review_page = atg_checkout_payment_page.add_credit_card(credit_card, billing_address)
      end

      scenario '7. Place order and go to Confirmation page' do
        atg_confirmation_page = atg_review_page.place_order

        fail "Place order error: #{atg_confirmation_page}" if atg_confirmation_page.is_a?(String)

        overview_info = atg_confirmation_page.order_overview_info
        atg_confirmation_page.record_order_id(email, overview_info[:order_id])
      end

      scenario 'Order number =' do
        pending("***Order number = #{overview_info[:order_id]})")
      end
    end

    context 'Verify information on Confirmation page' do
      before :each do
        skip 'Place order fails' if atg_confirmation_page.is_a?(String)
      end

      scenario '1. Verify complete order message' do
        expect(overview_info[:complete]).to match(ProductInformation::ORDER_COMPLETE_MESSAGE_CONST)
      end

      scenario '2. Verify Order detail info' do
        total_price = atg_confirmation_page.cal_total_price(product_info[:price])
        order_total_price = atg_confirmation_page.calculate_order_total
        expect(overview_info[:details]).to include("Order Details Digital Download Items Price #{product_info[:cart_title]} #{product_info[:price]} Order Subtotal: #{currency}#{total_price}")
      end

      scenario '3. Verify Order total' do
        expect(overview_info[:details]).to include("Order Total: #{currency}#{order_total_price}")
      end

      scenario '4. Verify Payment method' do
        payment_method = "#{CreditCard::CARD_TEXT_CONST} #{currency}#{order_total_price}"
        expect(overview_info[:details]).to include("Payment Method #{payment_method}")
      end

      scenario '5. Verify Order summary info' do
        expect(overview_info[:summary]).to eq(ProductInformation::ORDER_SUMMARY_TEXT_CONST % email)
      end
    end

    context 'Verify order number displays on My Account page' do
      before :each do
        skip 'Place order fails' if atg_confirmation_page.is_a?(String)
      end

      scenario '1. Go to My Account page' do
        atg_my_profile_page = atg_confirmation_page.goto_my_account
        pending("***1. Go to My Account page (URL:#{atg_my_profile_page.current_url})")
      end

      scenario '2. Verify order number displays' do
        expect(atg_my_profile_page.order_number_exist?(overview_info[:order_id])).to eq(true)
      end
    end

    context 'Verify information on Email page' do
      before :each do
        skip 'Place order fails' if atg_confirmation_page.is_a?(String)
      end

      scenario 'Go to Email page' do
        mail_detail_page = mail_home_page.go_to_mail_detail email
      end

      scenario '1. Verify Order number' do
        expect(mail_detail_page.order_number).to eq("ORDER NUMBER: #{overview_info[:order_id]}")
      end

      scenario '2. Verify Order Sub total' do
        expect(mail_detail_page.order_sub_total).to eq("Order subtotal: #{currency}#{total_price}")
      end

      scenario '3. Verify Payment method' do
        expect(mail_detail_page.payment_method).to eq(payment_method.gsub(/\s/, ''))
      end

      scenario '4. Verify Bill To' do
        expect(mail_detail_page.bill_to_info).to eq(ProductInformation::ADDRESS_CONST)
      end
    end
  end
end
