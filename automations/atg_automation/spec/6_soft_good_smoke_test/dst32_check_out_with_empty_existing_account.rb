require File.expand_path('../../spec_helper', __FILE__)

=begin
  Verify user can not checkout successfully with an empty existing account
=end

require 'atg_app_center_catalog_page'
require 'atg_login_register_page'
require 'atg_app_center_checkout_page'
require 'atg_app_center_cart_page'

atg_app_center_catalog_page = AtgAppCenterCatalogPage.new
atg_app_center_cart_page = AtgAppCenterCartPage.new
prod_info = smoke_atg_data('web_product1', General::LOCALE_CONST)

# Account information
email = Account::EMAIL_EXIST_EMPTY_CONST
password = General::PASSWORD_CONST

feature 'DT32: Check out with an empty existing account - ENV', js: true do
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

    scenario '3. Log out' do
      atg_app_center_cart_page.logout
    end
  end

  context 'Check out product' do
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
      pending("***4. Go to App Center Cart page #{atg_app_center_cart_page.current_url}")
    end

    scenario '5. Login to an existing account' do
      atg_app_center_cart_page.login_account_at_checkout_page(email, password)
    end
  end

  context 'Verify user can not check out' do
    scenario "Verify 'No products linked to your account' error displays" do
      expect(atg_app_center_cart_page.checkout_error_txt.text).to include('Whoops! No products linked to your account work with this item. This app works with')
    end

    scenario 'Click on \'Check out\' button' do
      atg_app_center_cart_page.checkout_btn.click
    end

    scenario "Verify 'Checkout Error' pop-up displays" do
      expect(atg_app_center_cart_page.has_check_out_error_popup?).to eq(true)
    end

    scenario 'Go back to Cart page' do
      atg_app_center_cart_page.back_to_cart_lnk.click
    end
  end

  after :all do
    atg_app_center_cart_page.clean_cart_page
  end
end
