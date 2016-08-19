require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_catalog_page'
require 'atg_login_register_page'
require 'atg_my_profile_page'
require 'atg_wishlist_page'
require 'atg_quick_view_overlay_page'
require 'mail_home_page'
require 'mail_detail_page'

=begin
  Verify Share this Wishlist feature works correctly
=end

atg_app_center_catalog_page = AtgAppCenterCatalogPage.new
atg_quick_view_overlay_page = AtgQuickViewOverlayPage.new
atg_product_pdp_page = AtgProductDetailPage.new
atg_wishlist_page = nil
mail_home_page = HomePageMail.new
mail_detail_page = nil
cookie_session_id = nil

# Product info
prod_info_1 = smoke_atg_data('web_product1', General::LOCALE_CONST)
prod_info_2 = smoke_atg_data('web_product2', General::LOCALE_CONST)
item_num1 = item_num2 = 0
wishlist_info = {}
wishlist1 = wishlist2 = {}

# Account information
receive_email = Generate.email('atg', General::ENV_CONST, General::LOCALE_CONST)
note = 'LF Automation: Share this Wishlist'

feature 'DST20 - Wishlist - Share this Wishlist', js: true do
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

  context 'Add 2 items into Wishlist' do
    scenario '1. Go to App Center page' do
      atg_app_center_catalog_page.load
      pending "***1. Go to App Center page (URL: #{atg_app_center_catalog_page.current_url})"
    end

    scenario 'Get the number of added items in Wishlist page' do
      item_num1 = atg_app_center_catalog_page.wishlist_item_number
      pending "***Number of added items in Wishlist is #{item_num1}"
    end

    scenario "2. Search 1st App (Product ID = #{prod_info_1[:prod_id]})" do
      atg_app_center_catalog_page.search_app prod_info_1[:prod_id]
    end

    scenario '3. Open the PDP page for 1st App' do
      atg_app_center_catalog_page.go_pdp prod_info_1[:prod_id]
    end

    scenario '4. Add 1st App to Wishlist' do
      atg_product_pdp_page.add_to_wishlist
    end

    scenario "5. Search 2nd App (Product ID = #{prod_info_2[:prod_id]})" do
      atg_app_center_catalog_page.search_app prod_info_2[:prod_id]
    end

    scenario '6. Open the PDP page for 2nd App' do
      atg_app_center_catalog_page.go_pdp prod_info_2[:prod_id]
    end

    scenario '7. Add 2nd App to Wishlist' do
      atg_product_pdp_page.add_to_wishlist
    end

    scenario 'Get the number of added items in Wishlist page' do
      item_num2 = atg_app_center_catalog_page.wishlist_item_number
      pending "***Number of added items in Wishlist is #{item_num2}"
    end

    scenario '8. Verify the number of item in Wishlist next to \'My Wishlist\' link is 2' do
      expect(item_num2).to eq(item_num1 + 2)
    end
  end

  context 'Go to Wishlist page and share all wishlist items' do
    scenario '1. Go to Wishlist page' do
      atg_wishlist_page = atg_app_center_catalog_page.goto_my_wishlist
      pending "***1. Go to Wishlist page (URL: #{atg_wishlist_page.current_url})"
    end

    scenario '2. Verify Wishlist page displays' do
      expect(atg_wishlist_page.wishlist_page_existed?).to eq(true)
    end

    scenario '3. Click on \'Share this Wishlist\' button' do
      atg_wishlist_page.click_share_this_wishlist_btn
    end

    scenario '4. Verify \'Email Your Wishlist\' pop-up displays' do
      expect(atg_wishlist_page.email_your_wishlist_popup_displays?).to eq(true)
    end

    scenario '5. Enter Email/Note and click on \'Share this Wishlist\' button' do
      atg_wishlist_page.share_wishlist receive_email, note
    end
  end

  context 'Check Share this Wishlish Email' do
    scenario "1. Go to \'Guerrillamail\' mail box - Email = '#{receive_email}'" do
      mail_detail_page = mail_home_page.go_to_mail_detail(receive_email, 3)
    end

    scenario '2. Get all shared Wishlist item from Email' do
      wishlist_info = mail_detail_page.shared_wishlist_info
      wishlist1 = wishlist_info.find { |e| e[:prod_id].include?(prod_info_1[:prod_id]) }
      wishlist2 = wishlist_info.find { |e| e[:prod_id].include?(prod_info_2[:prod_id]) }
    end

    scenario "3. Verify 1st item displays in Email with correct Product ID (ID = #{prod_info_1[:prod_id]})" do
      expect(wishlist1[:prod_id]).to eq(prod_info_1[:prod_id])
    end

    scenario "4. Verify 1st item displays in Email with correct Title (Title = #{prod_info_1[:wishlist_title]})" do
      expect(wishlist1[:title]).to include(prod_info_1[:wishlist_title])
    end

    scenario "5. Verify 2nd item displays in Email with correct Product ID (ID = #{prod_info_2[:prod_id]})" do
      expect(wishlist2[:prod_id]).to eq(prod_info_2[:prod_id])
    end

    scenario "6. Verify 2nd item displays in Email with correct Title (Title = #{prod_info_2[:wishlist_title]})" do
      expect(wishlist2[:title]).to include(prod_info_2[:wishlist_title])
    end
  end

  after :all do
    # Go to App Center page
    atg_app_center_catalog_page.load

    # Go to Wishlist and delete all items
    atg_app_center_catalog_page.goto_my_wishlist
    atg_wishlist_page.clean_wishlist_page
  end
end
