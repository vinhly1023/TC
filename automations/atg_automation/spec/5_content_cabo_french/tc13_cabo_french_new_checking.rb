require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_cabo_french_page'

=begin
French Cabo Content: Check product information on New Arrivals page
=end

describe "CABO French - New Arrivals Checking - Env: #{General::ENV_CONST} - Locale: #{General::LOCALE_CONST}" do
  titles_list = Connection.my_sql_connection(CaboAppCenterContent::CONST_CABO_QUERY_SEARCH_TITLE)
  titles_count = titles_list.count

  next unless app_available? titles_count

  fr_cabo_atg_app_center_page = AtgAppCenterCaboFrenchPage.new
  product_html = nil

  before :all do
    new_href = Connection.my_sql_connection(CaboAppCenterContent::CONST_CABO_QUERY_NEW_DRIVE).first['href']
    fr_cabo_atg_app_center_page.load(AppCenterContent::CONST_FILTER_URL % new_href)
    product_html = fr_cabo_atg_app_center_page.catalog_html_content
  end

  tc_num = 0
  titles_list.each do |title|
    e_product = fr_cabo_atg_app_center_page.expected_catalog_product_info title
    a_product, product_info = {}, {}

    context "#{tc_num += 1}. Product ID = #{e_product[:prod_number]} - Name = '#{e_product[:short_name]}'" do
      skip_flag = false

      before :each do
        skip ConstMessage::PRE_CONDITION_FAIL if product_info.empty? && skip_flag
      end

      it 'Get product information on New page' do
        skip_flag = true
        product_info = fr_cabo_atg_app_center_page.catalog_product_info(product_html, e_product[:prod_number])

        fail "***Product SKU = #{e_product[:sku]} is missing" if product_info.empty?

        skip_flag = false
        a_product = fr_cabo_atg_app_center_page.actual_catalog_product_info product_info
      end

      it "Verify Long name is '#{e_product[:long_name]}'" do
        expect(a_product[:long_name]).to eq(e_product[:long_name])
      end

      it "Verify Content/Type is '#{e_product[:content_type]}'" do
        expect(a_product[:content_type]).to eq(e_product[:content_type])
      end

      it "Verify Curriculum is '#{e_product[:curriculum]}'" do
        expect(a_product[:curriculum]).to eq(e_product[:curriculum])
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
