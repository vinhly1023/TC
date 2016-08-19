require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_lfc_french_page'

=begin
French LFC Content: Verify Products that don't match the Category/Content Type or Locale should not display
=end

describe "LFC French - Category Negative checking - Env: #{General::ENV_CONST} - Locale: #{General::LOCALE_CONST}" do
  next unless app_exist?
  atg_app_center_page = AtgAppCenterLFCFrenchPage.new
  tc_num = 0

  category_list = Connection.my_sql_connection(AppCenterContent::CONST_QUERY_CATEGORY_CATALOG_DRIVE)
  category_list.each do |category|
    category_name = Title.french_to_english(category['name'], 'category')
    category_href = category['href']

    titles = Connection.my_sql_connection(AppCenterContent::CONST_QUERY_CATEGORY_CATALOG_NEGATIVE_TITLE % [category_name, Title.content_type_mapping(category_name, 's2m')])
    titles_count = titles.count

    context "TC#{tc_num += 1}: Category = '#{category_name}' - Total SKUs = #{titles_count}" do
      next unless app_available?(titles_count, "There are no apps available for Category: #{category_name}")

      product_html = nil
      before :all do
        atg_app_center_page.load(AppCenterContent::CONST_FILTER_URL % category_href)
        product_html = atg_app_center_page.catalog_html_content
      end

      count = 0
      titles.each do |title|
        e_product = atg_app_center_page.expected_catalog_product_info title

        it "#{count += 1}. Product ID = '#{e_product[:prod_number]}' - Name = '#{e_product[:short_name]}' - Category = '#{e_product[:content_type]}'" do
          a_product = atg_app_center_page.product_not_exist?(product_html, e_product[:prod_number]) ? 'Not display' : 'Display'
          expect(a_product).to eq('Not display')
        end
      end
    end
  end
end
