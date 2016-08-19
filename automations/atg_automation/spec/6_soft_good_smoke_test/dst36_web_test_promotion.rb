require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_catalog_page'
require 'atg_app_center_cart_page'

=begin
  Verify that user can check out successfully when redeem Code at Check Out
=end

atg_app_center_catalog_page = AtgAppCenterCatalogPage.new
atg_app_center_cart_page = AtgAppCenterCartPage.new

feature 'Web - Test Promotion', js: true do
  promotion_codes = Connection.my_sql_connection(AppCenterContent::CONST_QUERY_PROMOTION_CODES_DRIVE)
  if promotion_codes.count.zero?
    skip "PENDING: Please import the Promotion Codes before running test case (ENV = #{General::ENV_CONST})"
    next
  end

  # Print Session ID
  check_status_url_and_print_session atg_app_center_catalog_page

  # Print COM Server
  com_server

  promotion_codes.each do |promotion_code|
    promo_name = promotion_code['promo_name']
    prod_ids = promotion_code['prod_ids'].split(',').map(&:strip)

    context "Promotion code #{promo_name}" do
      cart_empty = false

      before :each do
        skip 'BLOCKED: App Center Cart page is empty' if cart_empty
      end

      prod_ids.each do |prod_id|
        search_url = AppCenterContent::CONST_SEARCH_URL % prod_id

        it "Add Prod ID = #{prod_id} to Cart (URL: #{search_url})" do
          atg_app_center_catalog_page.load search_url
          fail "FAIL: Couldn't find any results for #{prod_id}" unless atg_app_center_catalog_page.search_result? prod_id
          atg_app_center_catalog_page.add_app_to_cart_from_search_page false
        end
      end

      it 'Go to App Center Cart page' do
        atg_app_center_catalog_page.go_to_cart_page
        if atg_app_center_cart_page.cart_empty?
          cart_empty = true
          fail 'FAIL: App Center Cart page is empty'
        end
      end

      it 'Enter the promo and click Apply Button' do
        atg_app_center_cart_page.promote_code promo_name
      end

      it "Verification of Success: 'Promotion code #{promo_name} applied.'" do
        expect(atg_app_center_cart_page.promote_response).to include("Promotion code #{promo_name} applied.")
      end

      after :all do
        TestDriverManager.delete_cookies
      end
    end
  end
end
