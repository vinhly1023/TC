require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_catalog_page'
require 'atg_login_register_page'
require 'atg_product_detail_page'
require 'atg_app_center_cart_page'
require 'atg_wishlist_page'

=begin
  Verify user can add product to cart successfully from Wishlist overlay
=end

# initial variables
atg_app_center_catalog_page = AtgAppCenterCatalogPage.new
atg_product_pdp_page = AtgProductDetailPage.new
atg_app_center_cart_page = AtgAppCenterCartPage.new
atg_wishlist_page = nil
cookie_session_id = nil

# Product info
prod_info = smoke_atg_data('web_product1', General::LOCALE_CONST)
cart_info = cart_dropdown_info = {}
item_num1 = item_num2 = 0

feature 'DST15 - Catalog - Add to Cart from Wish list', js: true do
  before :all do
    # Login to LF account
    cookie_session_id = atg_app_center_catalog_page.load
    atg_login_register_page = atg_app_center_catalog_page.goto_login
    atg_my_profile_page = atg_login_register_page.login(Account::EMAIL_EXIST_FULL_CONST, General::PASSWORD_CONST)

    # Delete all items in Cart page
    if atg_app_center_catalog_page.cart_item_number > 0
      atg_app_center_catalog_page.go_to_cart_page
      atg_app_center_cart_page.clean_cart_page
    end

    # Delete all items in Wishlist page
    if atg_app_center_catalog_page.wishlist_item_number > 0
      atg_wishlist_page = atg_my_profile_page.goto_my_wishlist
      atg_wishlist_page.clean_wishlist_page
    end
  end

  context 'Print Session ID' do
    scenario '' do
      pending "***SESSION_ID: #{cookie_session_id}"
    end
  end

  context 'Add Product to Wishlist from PDP page' do
    scenario '1. Go to App Center page' do
      atg_app_center_catalog_page.load
      pending "***1. Go to App Center page (URL: #{atg_app_center_catalog_page.current_url})"
    end

    scenario '2. Get the number of added items in Cart page' do
      item_num1 = atg_app_center_catalog_page.cart_item_number
      pending "***2. The number of added items in Cart is #{item_num1}"
    end

    scenario "3. Search App (Product ID = #{prod_info[:prod_id]})" do
      atg_app_center_catalog_page.search_app prod_info[:prod_id]
    end

    scenario '4. Open the Product Detail page' do
      atg_app_center_catalog_page.go_pdp prod_info[:prod_id]
    end
  end

  context 'Add Product to Cart from Wishlist page' do
    scenario "1. Click on 'Add to Wishlist' link from PDP page" do
      atg_product_pdp_page.add_to_wishlist
    end

    scenario '2. Go to Wishlist page' do
      atg_wishlist_page = atg_app_center_catalog_page.goto_my_wishlist
      pending "***1. Go to Wishlist page (URL: #{atg_wishlist_page.current_url})"
    end

    scenario '3. Verify Wishlist page displays' do
      expect(atg_wishlist_page.wishlist_page_existed?).to eq(true)
    end

    scenario '4. Click on \'Add to Cart\' button fron Wishlist page' do
      atg_wishlist_page.add_to_cart_from_wishlist
    end
  end

  context 'Verify Product information in Cart page' do
    scenario '1. Go to Cart page' do
      cart_page = atg_app_center_catalog_page.go_to_cart_page
      pending "***1. Go to Cart page (URL: #{cart_page.current_url})"
    end

    scenario '2. Get Product information in Cart page' do
      cart_info = atg_app_center_cart_page.product_info_in_cart prod_info[:prod_id]
      pending "***Get Product information in Cart page (ID: #{cart_info[:prod_id]} - Title: #{cart_info[:title]})"
    end

    scenario "3. Verify Product ID in Cart page (ID = #{prod_info[:prod_id]})" do
      expect(cart_info[:prod_id]).to eq(prod_info[:prod_id])
    end

    scenario "4. Verify Product Title in Cart page (Cart Title = #{prod_info[:cart_title]})" do
      expect(cart_info[:title]).to include(prod_info[:cart_title])
    end

    scenario "5. Verify Product Price in Cart page (Price = #{prod_info[:price]})" do
      expect(cart_info[:price]).to eq(prod_info[:price])
    end
  end

  context 'Verify Product information under Cart Dropdown' do
    scenario 'Get the number of added item in Cart page' do
      item_num2 = atg_app_center_catalog_page.cart_item_number
      pending "***The number of added items in Cart is #{item_num2}"
    end

    scenario '1. Verify the number of added items in Cart (next to \'App Center\' link) is increased 1' do
      expect(item_num2).to eq(item_num1 + 1)
    end

    scenario '2. Get Product information under Cart dropdown' do
      cart_dropdown_info = atg_app_center_catalog_page.product_info_under_cart_dropdown prod_info[:prod_id]
      pending "***Product information under Cart dropdown (ID: #{cart_dropdown_info[:prod_id]} - Title: #{cart_dropdown_info[:title]})"
    end

    scenario "3. Verify Product ID under Cart Dropdown (ID = #{prod_info[:prod_id]})" do
      expect(cart_dropdown_info[:prod_id]).to eq(prod_info[:prod_id])
    end

    scenario "4. Verify Product Title under Cart Dropdown (Cart Title = #{prod_info[:cart_title]})" do
      expect(cart_dropdown_info[:title]).to include(prod_info[:cart_title])
    end

    scenario "5. Verify Product Price under Cart Dropdown (Price = #{prod_info[:price]})" do
      expect(cart_dropdown_info[:price]).to eq(prod_info[:price])
    end
  end

  after :all do
    atg_app_center_cart_page.clean_cart_page
  end
end