require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_catalog_page'
require 'atg_login_register_page'
require 'atg_quick_view_overlay_page'
require 'atg_wishlist_page'

=begin
  Verify user can add product to cart successfully from QuickView overlay
=end

# initial variables
atg_app_center_catalog_page = AtgAppCenterCatalogPage.new
atg_quick_view_overlay_page = AtgQuickViewOverlayPage.new
atg_wishlist_page = nil
cookie_session_id = nil

# Product info
prod_info = smoke_atg_data('web_product1', General::LOCALE_CONST)
wishlist_info = wishlist_dropdown_info = {}
item_num1 = item_num2 = 0

feature 'DST16A - Catalog - Add to Wishlist from Quick View', js: true do
  before :all do
    # Login to LF account
    cookie_session_id = atg_app_center_catalog_page.load
    atg_login_register_page = atg_app_center_catalog_page.goto_login
    atg_my_profile_page = atg_login_register_page.login(Account::EMAIL_EXIST_EMPTY_CONST, General::PASSWORD_CONST)

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

  context 'Add Product to Wishlist from Quick View overlay' do
    scenario '1. Go to App Center page' do
      AtgAppCenterCatalogPage.set_url URL::ATG_APP_CENTER_ALL_APPS_URL
      atg_app_center_catalog_page.load
      pending "***1. Go to App Center page (URL: #{atg_app_center_catalog_page.current_url})"
    end

    scenario 'Get the number of added items in Wishlist page' do
      item_num1 = atg_app_center_catalog_page.wishlist_item_number
      pending "***Number of added items in Wishlist is #{item_num1}"
    end

    scenario "2. Open Quick View overlay (ID = #{prod_info[:prod_id]})" do
      atg_app_center_catalog_page.open_quick_view_by_prod_id prod_info[:prod_id]
    end

    scenario '3. Verify Quick view overlay displays' do
      expect(atg_quick_view_overlay_page.quick_view_overlay_displayed?).to eq(true)
    end

    scenario "4. Click on 'Add to wish list' link on Quick View overlay" do
      atg_quick_view_overlay_page.add_to_wishlist
    end

    scenario '5. Go to Wishlist page' do
      atg_wishlist_page = atg_app_center_catalog_page.goto_my_wishlist
      pending "***5. Go to Wishlist page (URL: #{atg_wishlist_page.current_url})"
    end

    scenario '6. Verify Wishlist page displays' do
      expect(atg_wishlist_page.wishlist_page_existed?).to eq(true)
    end
  end

  context 'Verify Product information on WishList page' do
    scenario '1. Get Quick List information' do
      info = atg_wishlist_page.product_info_in_wishlist
      wishlist_info = info.find { |e| e[:prod_id].include?(prod_info[:prod_id]) }
    end

    scenario "2. Verify Product ID in Wishlist page(ID = #{prod_info[:prod_id]})" do
      expect(wishlist_info[:prod_id]).to eq(prod_info[:prod_id])
    end

    scenario "3. Verify Product Title in Wishlist page (Wishlist Title = #{prod_info[:wishlist_title]})" do
      expect(wishlist_info[:title]).to include(prod_info[:wishlist_title])
    end

    scenario "4. Verify Product Price in Wishlist page (#{prod_info[:price]})" do
        expect(wishlist_info[:price]).to eq(prod_info[:price])
    end
  end

  context 'Verify Product information under Wishlist Dropdown' do
    scenario 'Get the number of added item in Wishlist page' do
      item_num2 = atg_app_center_catalog_page.wishlist_item_number
      pending "***Number of added item in Wishlist is #{item_num2}"
    end

    scenario '1. Verify the number of item in Wishlist (next to \'My Wishlist\') link is increased 1' do
      expect(item_num2).to eq(item_num1 + 1)
    end

    scenario '2. Get Product information under Wishlist dropdown' do
      wishlist_dropdown_info = atg_app_center_catalog_page.product_info_under_wishlist_dropdown prod_info[:prod_id]
      pending "***Product information under Wishlist dropdown (ID: #{wishlist_dropdown_info[:prod_id]} - Title: #{wishlist_dropdown_info[:title]})"
    end

    scenario "3. Verify Product ID under Wishlist dropdown (ID = #{prod_info[:prod_id]})" do
      expect(wishlist_dropdown_info[:prod_id]).to eq(prod_info[:prod_id])
    end

    scenario "4. Verify Product Title under Wishlist dropdown (Title = #{prod_info[:wishlist_title]})" do
      expect(wishlist_dropdown_info[:title]).to include(prod_info[:wishlist_title])
    end

    scenario "5. Verify Product Price under Wishlist dropdown (Price = #{prod_info[:price]})" do
      expect(wishlist_dropdown_info[:price]).to eq(prod_info[:price])
    end
  end

  after :all do
    atg_wishlist_page.clean_wishlist_page
  end
end
