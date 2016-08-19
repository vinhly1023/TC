require File.expand_path('../../spec_helper', __FILE__)

=begin
  Verify user can check out multiple apps successfully
=end

env = General::ENV_CONST
locale = General::LOCALE_CONST

if locale == 'IE' || locale == 'ROW'
  feature 'DT34: Check out with multi apps by using Credit card', js: true do
    scenario 'Skip check-out with Credit Card on IE, ROW locales (Unsupported locale)' do
    end
  end
elsif env == 'PROD'
  feature 'DT34: Check out with multi apps by using Credit card' do
    scenario 'Skip check-out with Credit Card on Production env' do
    end
  end
else
  require 'atg_app_center_catalog_page'
  require 'atg_app_center_cart_page'
  require 'atg_login_register_page'
  require 'atg_my_profile_page'
  require 'mail_home_page'
  require 'mail_detail_page'

  atg_app_center_catalog_page = AtgAppCenterCatalogPage.new
  atg_app_center_cart_page = AtgAppCenterCartPage.new
  atg_app_center_checkout_page = AtgAppCenterCheckOutPage.new
  atg_checkout_page = nil
  atg_review_page = nil
  atg_confirmation_page = nil
  mail_home_page = HomePageMail.new
  mail_detail_page = nil

  # Account information
  email = Account::EMAIL_EXIST_FULL_CONST
  password = General::PASSWORD_CONST

  # Product checkout info
  currency = Title.locale_to_currency locale
  prod_info1 = smoke_atg_data('web_product1', General::LOCALE_CONST)
  prod_info2 = smoke_atg_data('web_product2', General::LOCALE_CONST)
  overview_info = {}
  total_price = ''
  order_total_price = ''
  payment_method = ''

  feature 'DT34: Check out with multi apps by using Credit card', js: true do
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

    context 'Check out multi products' do
      scenario '1. Go to App Center page' do
        atg_app_center_catalog_page.load
        pending "***1. Go to App Center page (URL: #{atg_app_center_catalog_page.current_url})"
      end

      scenario "2. Search 1st App (Product ID = #{prod_info1[:prod_id]})" do
        atg_app_center_catalog_page.search_app prod_info1[:prod_id]
      end

      scenario '3. Add the 1st App to Cart' do
        atg_app_center_catalog_page.add_app_to_cart prod_info1[:prod_id]
      end

      scenario "4. Search 2nd App (Product ID = #{prod_info2[:prod_id]})" do
        atg_app_center_catalog_page.search_app prod_info2[:prod_id]
      end

      scenario '5. Add the 2nd App to Cart' do
        atg_app_center_catalog_page.add_app_to_cart prod_info2[:prod_id]
      end

      scenario '6. Go to App Center Cart page' do
        atg_checkout_page = atg_app_center_catalog_page.go_to_cart_page
        pending("***6. Go to App Center Cart page #{atg_checkout_page.current_url}")
      end

      scenario '7. Go to Payment page' do
        atg_checkout_page.go_to_payment
        pending("***7. Go to Payment page #{atg_checkout_page.current_url}")
      end

      scenario '8. Select an existing Credit card' do
        atg_review_page = atg_app_center_checkout_page.select_credit_card
      end

      scenario '9. Place order and go to Confirmation page' do
        atg_confirmation_page = atg_review_page.place_order
        overview_info = atg_confirmation_page.order_overview_info
        atg_confirmation_page.record_order_id(email, overview_info[:order_id])
      end
    end

    context 'Verify information on Confirmation page' do
      scenario '1. Verify complete order message' do
        expect(overview_info[:complete]).to match(ProductInformation::ORDER_COMPLETE_MESSAGE_CONST)
      end

      scenario '2. Verify Order detail info' do
        total_price = '%.2f' % (atg_confirmation_page.cal_total_price(prod_info1[:price]).to_f + atg_confirmation_page.cal_total_price(prod_info2[:price]).to_f)
        expect(overview_info[:details]).to include("Order Details Digital Download Items Price #{prod_info1[:cart_title]} #{prod_info1[:price]} #{prod_info2[:cart_title]} #{prod_info2[:price]} Order Subtotal: #{currency}#{total_price}")
      end

      scenario '3. Verify Order total' do
        order_total_price = atg_confirmation_page.calculate_order_total
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

    context 'Verify information on Email page' do
      scenario 'Go to Email page' do
        mail_detail_page = mail_home_page.go_to_mail_detail email
      end

      scenario '1. Verify order number' do
        expect(mail_detail_page.order_number).to eq("ORDER NUMBER: #{overview_info[:order_id]}")
      end

      scenario '2. Verify Order Sub total' do
        expect(mail_detail_page.order_sub_total).to eq("Order subtotal: #{currency}#{total_price}")
      end

      scenario '3. Verify Payment method info' do
        expect(mail_detail_page.payment_method).to eq(payment_method.gsub(/\s/, ''))
      end

      scenario '4. Verify Bill To info' do
        expect(mail_detail_page.bill_to_info).to eq(ProductInformation::ADDRESS_CONST)
      end
    end
  end
end