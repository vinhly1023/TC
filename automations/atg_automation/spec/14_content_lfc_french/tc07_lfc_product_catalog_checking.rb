require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_lfc_french_page'

=begin
French LFC Content: Verify that Products that match with Product Type and Locale should display
=end

describe "LFC French - Product catalog checking - Env: #{General::ENV_CONST} - Locale: #{General::LOCALE_CONST}" do
  next unless app_exist?

  atg_app_center_page = AtgAppCenterLFCFrenchPage.new
  tc_num = 0

  product_list = Connection.my_sql_connection(AppCenterContent::CONST_QUERY_PRODUCT_CATALOG_DRIVE)
  product_list.each do |category|
    product_name = Title.french_to_english(category['name'], 'platform')
    product_title = product_name.gsub('LeapFrog Epic', 'Epic')
    product_href = category['href']

    titles = Connection.my_sql_connection(AppCenterContent::CONST_QUERY_PRODUCT_CATALOG_TITLE % product_title)
    titles_count = titles.count

    context "TC#{tc_num += 1}: Product = '#{category['name']}' - Total SKUs = #{titles_count}" do
      next unless app_available?(titles_count, "There are no apps available for Product: #{product_name}")

      product_html1 = product_html2 = nil
      before :all do
        atg_app_center_page.load(AppCenterContent::CONST_FILTER_URL % product_href)
        product_html1 = atg_app_center_page.catalog_html_content

        atg_app_center_page.load(AppCenterContent::CONST_FILTER_URL2 % product_href)
        product_html2 = atg_app_center_page.catalog_html_content
      end

      count = 0
      titles.each do |title|
        e_product = atg_app_center_page.expected_catalog_product_info title

        it "#{count += 1}. Product ID = '#{e_product[:prod_number]}' - Name = '#{e_product[:short_name]}'" do
          a_product = atg_app_center_page.product_not_exist?(product_html1, e_product[:prod_number])
          a_product = atg_app_center_page.product_not_exist?(product_html2, e_product[:prod_number]) if a_product
          a_product = a_product ? 'Not display' : 'Display'
          expect(a_product).to eq('Display')
        end
      end
    end
  end
end
