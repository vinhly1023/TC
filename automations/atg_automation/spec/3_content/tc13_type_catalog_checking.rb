require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_web_english_page'

=begin
English Web Content: Verify that Products that match with Type/Format and Locale should display
=end

describe "Type/Format catalog checking - Env: #{General::ENV_CONST} - Locale: #{General::LOCALE_CONST.upcase}" do
  next unless app_exist?
  atg_app_center_page = AtgAppCenterWebEnglishPage.new
  tc_num = 0

  type_list = Connection.my_sql_connection(AppCenterContent::CONST_QUERY_TYPE_CATALOG_DRIVE)
  type_list.each do |sk|
    type_name = sk['name']
    type_href = sk['href']
    titles = Connection.my_sql_connection(AppCenterContent::CONST_QUERY_TYPE_CATALOG_TITLE % type_name)
    titles_count = titles.count

    context "TC#{tc_num += 1}: Type/Format = '#{type_name}' - Total Apps = #{titles_count}" do
      next unless app_available?(titles_count, "There are no apps belong to Type/Format: #{type_name}")

      product_html = nil
      before :all do
        atg_app_center_page.load(AppCenterContent::CONST_FILTER_URL % type_href)
        product_html = atg_app_center_page.catalog_html_content
      end

      count = 0
      titles.each do |title|
        e_product = atg_app_center_page.expected_catalog_product_info title

        it "#{count += 1}. Product ID = '#{e_product[:prod_number]}' - Name = '#{e_product[:short_name]}'" do
          a_product = atg_app_center_page.product_not_exist?(product_html, e_product[:prod_number]) ? 'Not display' : 'Display'
          expect(a_product).to eq('Display')
        end
      end
    end
  end
end
