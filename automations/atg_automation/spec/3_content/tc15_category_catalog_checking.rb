require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_web_english_page'

=begin
English Web Content: Verify that Products that match with Category/Content Type and Locale should display
=end

describe "Category checking - Env: #{General::ENV_CONST} - Locale: #{General::LOCALE_CONST.upcase}" do
  next unless app_exist?
  atg_app_center_page = AtgAppCenterWebEnglishPage.new
  tc_num = 0

  category_list = Connection.my_sql_connection(AppCenterContent::CONST_QUERY_CATEGORY_CATALOG_DRIVE)
  category_list.each do |category|
    category_name = category['name']
    category_href = category['href']
    titles = Connection.my_sql_connection(AppCenterContent::CONST_QUERY_CATEGORY_CATALOG_TITLE % [category_name, Title.content_type_mapping(category_name, 's2m')])
    titles_count = titles.count

    context "TC#{tc_num += 1}: Category = '#{category_name}' - Total Apps = #{titles_count}" do
      next unless app_available?(titles_count, "There are no apps belong to Category: #{category_name}")

      product_html = nil
      before :all do
        atg_app_center_page.load(AppCenterContent::CONST_FILTER_URL % category_href)
        product_html = atg_app_center_page.catalog_html_content
      end

      count = 0
      titles.each do |title|
        e_product = atg_app_center_page.expected_catalog_product_info title

        it "#{count += 1}. Product ID = '#{e_product[:prod_number]}' - Name = '#{e_product[:short_name]}'" do
          product_info = atg_app_center_page.catalog_product_info(product_html, e_product[:prod_number])

          fail "***Title #{e_product[:prod_number]} is missing" if product_info.empty?

          a_product = atg_app_center_page.actual_catalog_product_info product_info
          expect(a_product[:content_type]).to eq(e_product[:content_type])
        end
      end
    end
  end
end
