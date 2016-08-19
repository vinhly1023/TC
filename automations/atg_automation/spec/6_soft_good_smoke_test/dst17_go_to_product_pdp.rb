require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_catalog_page'
require 'atg_login_register_page'
require 'atg_product_detail_page'

=begin
  Verify user can add product to cart successfully from Wishlist page
=end

atg_app_center_catalog_page = AtgAppCenterCatalogPage.new
atg_product_pdp_page = AtgProductDetailPage.new
cookie_session_id = nil

# Product info
prod_info = smoke_atg_data('web_product1', General::LOCALE_CONST)

feature 'DST17 - Catalog - Go to product PDP', js: true do
  before :all do
    cookie_session_id = atg_app_center_catalog_page.load
    atg_login_register_page = atg_app_center_catalog_page.goto_login
    atg_login_register_page.login(Account::EMAIL_EXIST_EMPTY_CONST, General::PASSWORD_CONST)
  end

  context 'Print Session ID' do
    scenario '' do
      pending "***SESSION_ID: #{cookie_session_id}"
    end
  end

  context 'Open Product Detail page' do
    scenario '1. Go to App Center page' do
      atg_app_center_catalog_page.load
      pending "***1. Go to App Center page (URL: #{atg_app_center_catalog_page.current_url})"
    end

    scenario "2. Search App (Product ID = #{prod_info[:prod_id]})" do
      atg_app_center_catalog_page.search_app prod_info[:prod_id]
    end

    scenario '3. Open the Product Detail page' do
      pdp_page = atg_app_center_catalog_page.go_pdp prod_info[:prod_id]
      pending "***3. Open the Product Detail page (URL: #{pdp_page.current_url})"
    end

    scenario '4. Verify Product Detail page displays correctly' do
      expect(atg_product_pdp_page.pdp_displays?(prod_info[:prod_id])).to eq(true)
    end
  end
end
