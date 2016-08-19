require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_catalog_page'
require 'atg_login_register_page'
require 'atg_my_profile_page'
require 'atg_product_detail_page'
require 'atg_wishlist_page'

=begin
  Verify user can remove an item from Wishlist Dropdown
=end

atg_app_center_catalog_page = AtgAppCenterCatalogPage.new
atg_product_pdp_page = AtgProductDetailPage.new
atg_wishlist_page = nil
cookie_session_id = nil

# Product info
prod_info = smoke_atg_data('web_product1', General::LOCALE_CONST)
item_num1 = item_num2 = item_num3 = 0

feature 'DST18 - Wishlist - Remove Item from Wishlist DropDown', js: true do
  before :all do
    # Login to LF Account
    cookie_session_id = atg_app_center_catalog_page.load
    atg_login_page = atg_app_center_catalog_page.goto_login
    atg_my_profile_page = atg_login_page.login(Account::EMAIL_EXIST_EMPTY_CONST, General::PASSWORD_CONST)

    # Delete all Wishlist items
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

  context 'Add Product to Wishlist from PDP' do
    scenario '1. Go to App Center page' do
      atg_app_center_catalog_page.load
      pending "***1. Go to AppCenter page (URL: #{atg_app_center_catalog_page.current_url})"
    end

    scenario '2. Get the number of added items in Wishlist' do
      item_num1 = atg_app_center_catalog_page.wishlist_item_number
      pending "***2. Number of added items in Wishlist is #{item_num1}"
    end

    scenario "3. Search App (Product ID = #{prod_info[:prod_id]})" do
      atg_app_center_catalog_page.search_app prod_info[:prod_id]
    end

    scenario '4. Open the Product Detail page' do
      pdp_page = atg_app_center_catalog_page.go_pdp prod_info[:prod_id]
      pending "***4. Open the Product Detail page (URL: #{pdp_page.current_url})"
    end

    scenario "5. Click on 'Add to Wishlist' link from PDP page" do
      atg_product_pdp_page.add_to_wishlist
    end
  end

  context 'Remove items from Wishlist Dropdown' do
    scenario '1. Get the number of added item in Wishlist page' do
      item_num2 = atg_app_center_catalog_page.wishlist_item_number
      pending "***1. Number of added item in Wishlist is #{item_num2}"
    end

    scenario '2. Verify the number of Wishlist items next to \'My Wishlist\' link is increased 1' do
      expect(item_num2).to eq(item_num1 + 1)
    end

    scenario '3. Hover over the menu item \'My Wishlist ()\' and click on the \'x\' to remove' do
      atg_app_center_catalog_page.remove_item_from_wishlist_dropdown prod_info[:prod_id]
    end

    scenario '4. Verify the Dropdown from Wishlist header link says your wishlist is empty.' do
      expect(atg_app_center_catalog_page.wishlish_header_text).to eq('Your LeapFrog Wishlist is empty.')
    end

    scenario '5. Get the number of added item in Wishlist page after removing' do
      item_num3 = atg_app_center_catalog_page.wishlist_item_number
      pending "***5. Number of added item in Wishlist is #{item_num3}"
    end

    scenario '6. Verify the number of Wishlist items next to \'My Wishlist\' link is decreased 1' do
      expect(item_num3).to eq(item_num1)
    end
  end

  after :all do
    atg_app_center_catalog_page.goto_my_wishlist
    atg_wishlist_page.clean_wishlist_page
  end
end
