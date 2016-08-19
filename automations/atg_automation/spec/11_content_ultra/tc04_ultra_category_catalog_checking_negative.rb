require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_ultra_english_page'

=begin
English LeapPad Ultra Content: Verify Products that don't match the Category or Locale or LeapPad Ultra platform should not display
=end

describe "LeapPad Ultra - Category negative checking - Env: #{General::ENV_CONST} - Locale: #{General::LOCALE_CONST.upcase}" do
  next unless app_exist?
  ultra_atg_app_center_page = AtgAppCenterUltraEnglishPage.new
  tc_num = 0

  category_list = Connection.my_sql_connection(UltraAppCenterContent::CONST_ULTRA_QUERY_CATEGORY_CATALOG_DRIVE)
  category_list.each do |category|
    category_name = category['name']
    category_href = category['href']

    titles = Connection.my_sql_connection(UltraAppCenterContent::CONST_ULTRA_QUERY_CATEGORY_CATALOG_NEGATIVE_TITLE % [category_name, Title.content_type_mapping(category_name, 's2m')])
    titles_count = titles.count

    context "TC#{tc_num += 1}: Category = '#{category_name}' - Total SKUs = #{titles_count}" do
      next unless app_available?(titles_count, "There are no apps available for Category: #{category_name}")

      product_html = nil
      before :all do
        ultra_atg_app_center_page.load(UltraAppCenterContent::CONST_ULTRA_FILTER_URL % category_href)
        product_html = ultra_atg_app_center_page.catalog_html_content
      end

      count = 0
      titles.each do |title|
        e_product = ultra_atg_app_center_page.expected_catalog_product_info title

        it "#{count += 1}. Product ID = '#{e_product[:prod_number]}' - Name = '#{e_product[:short_name]}' - Category = '#{e_product[:content_type]}'" do
          a_product = ultra_atg_app_center_page.product_not_exist?(product_html, e_product[:prod_number]) ? 'Not display' : 'Display'
          expect(a_product).to eq('Not display')
        end
      end
    end
  end
end
