require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_catalog_page'
require 'atg_login_register_page'
require 'atg_my_profile_page'
require 'atg_app_center_cart_page'

=begin
  Verify user can remove an item from Dropdown Cart
=end

atg_app_center_catalog_page = AtgAppCenterCatalogPage.new
atg_app_center_cart_page = AtgAppCenterCartPage.new
cookie_session_id = nil

# Product info
item_num1 = item_num2 = 0
product_info = smoke_atg_data('web_product1', General::LOCALE_CONST)

# Account information
email = Account::EMAIL_EXIST_EMPTY_CONST
password = General::PASSWORD_CONST

feature 'DST27 - Cart - Remove Item from Drop down cart - ENV', js: true do
  before :all do
    # Login to LF Account
    cookie_session_id = atg_app_center_catalog_page.load
    atg_login_page = atg_app_center_catalog_page.goto_login
    atg_login_page.login(email, password)

    # Delete all items in Cart page
    if atg_app_center_catalog_page.cart_item_number > 0
      atg_app_center_catalog_page.go_to_cart_page
      atg_app_center_cart_page.clean_cart_page
    end
  end

  context 'Print Session ID' do
    scenario '' do
      pending "***SESSION_ID: #{cookie_session_id}"
    end
  end

  context 'Add an item to the cart from the App Center Catalog Page' do
    scenario '1. Go to App Center page' do
      atg_app_center_catalog_page.load
      pending "***1. Go to App Center page (URL: #{atg_app_center_catalog_page.current_url})"
    end

    scenario '2. Get the number of added items in cart' do
      item_num1 = atg_app_center_catalog_page.cart_item_number
      pending "***2. Number of added items in Cart is #{item_num1}"
    end

    scenario "3. Search App (Product ID = #{product_info[:prod_id]})" do
      atg_app_center_catalog_page.search_app product_info[:prod_id]
    end

    scenario '4. Add App to Cart' do
      atg_app_center_catalog_page.add_app_to_cart product_info[:prod_id]
    end
  end

  context 'Verify item is added to Cart' do
    scenario '1. Get the number of added item in Cart page' do
      item_num2 = atg_app_center_catalog_page.cart_item_number
      pending "***1. Number of added item in Cart is #{item_num2}"
    end

    scenario '2. Verify the number of Cart items next to \'My Cart\' link is increased 1' do
      expect(item_num2).to eq(item_num1 + 1)
    end
  end

  context 'Hover over the App Center Cart and click Remove Item from the pop-up menu' do
    scenario '1. Hover over the App Center Cart' do
      atg_app_center_catalog_page.hover_app_center_cart
    end

    scenario '2. Verify the remove from cart pop-up displays' do
      expect(atg_app_center_catalog_page.app_center_cart_dropdown_displays?).to eq(true)
    end

    scenario "3. Hover over the 'x' in the menu" do
      atg_app_center_catalog_page.hover_the_x_in_the_menu
    end

    scenario '4. Click Remove Item from the pop-up menu' do
      atg_app_center_catalog_page.remove_item_app_center_dropdown_cart
    end
  end

  context 'Verify the item removed no longer be found in the cart' do
    scenario '1. Hover over the App Center Cart' do
      atg_app_center_catalog_page.hover_app_center_cart
    end

    scenario '2. Verify the item removed no longer be found in the cart' do
      expect(atg_app_center_catalog_page.app_center_cart_dropdown_displays?).to eq(false)
    end
  end
end
