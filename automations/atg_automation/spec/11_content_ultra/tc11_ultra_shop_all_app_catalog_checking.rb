require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_ultra_english_page'

=begin
LeapPad Ultra Content: Fill by Shopp All App and check app information on Catalog page
=end

describe "LeapPad Ultra - Shop All App checking - Env: #{General::ENV_CONST} - Locale: #{General::LOCALE_CONST.upcase}" do
  next unless app_exist?

  titles_list = Connection.my_sql_connection(UltraAppCenterContent::CONST_ULTRA_QUERY_SEARCH_TITLE)
  titles_count = titles_list.count

  next unless app_available? titles_count

  ultra_atg_app_center_page = AtgAppCenterUltraEnglishPage.new
  product_html1 = product_html2 = nil

  before :all do
    ultra_atg_app_center_page.load(UltraAppCenterContent::CONST_ULTRA_SHOP_ALL_APP_URL1)
    product_html1 = ultra_atg_app_center_page.catalog_html_content

    ultra_atg_app_center_page.load(UltraAppCenterContent::CONST_ULTRA_SHOP_ALL_APP_URL2)
    product_html2 = ultra_atg_app_center_page.catalog_html_content
  end

  count = 0
  titles_list.each do |title|
    e_product = ultra_atg_app_center_page.expected_catalog_product_info title
    a_product, product_info = {}, {}

    context "#{count += 1}. Product ID = #{e_product[:prod_number]} - Name = '#{e_product[:short_name]}'" do
      skip_flag = false

      before :each do
        skip ConstMessage::PRE_CONDITION_FAIL if product_info.empty? && skip_flag
      end

      it 'Find and get title information' do
        skip_flag = true
        product_info = ultra_atg_app_center_page.catalog_product_info(product_html1, e_product[:prod_number])
        product_info = ultra_atg_app_center_page.catalog_product_info(product_html2, e_product[:prod_number]) if product_info.empty?

        fail "***Title #{e_product[:sku]} is missing" if product_info.empty?

        skip_flag = false
        a_product = ultra_atg_app_center_page.actual_catalog_product_info product_info
      end

      it "Verify Content/Type is '#{e_product[:content_type]}'" do
        expect(a_product[:content_type]).to eq(e_product[:content_type])
      end

      it "Verify Long name is '#{e_product[:long_name]}'" do
        expect(a_product[:long_name]).to eq(e_product[:long_name])
      end

      it "Verify Age is '#{e_product[:age]}'" do
        expect(a_product[:age]).to eq(e_product[:age])
      end

      it "Verify Price is '#{e_product[:price]}'" do
        expect(a_product[:price]).to eq(e_product[:price])
      end
    end
  end
end
