require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_cabo_french_page'

=begin
French Cabo Content: Verify Products that don't match the Category or Locale or LeapPad3 platform should not display
=end

describe "CABO French - Category negative checking - Env: #{General::ENV_CONST} - Locale: #{General::LOCALE_CONST.upcase}" do
  next unless app_exist?
  fr_cabo_atg_app_center_page = AtgAppCenterCaboFrenchPage.new
  tc_num = 0

  category_list = Connection.my_sql_connection(CaboAppCenterContent::CONST_CABO_QUERY_CATEGORY_CATALOG_DRIVE)
  category_list.each do |category|
    category_name = Title.french_to_english(category['name'], 'contenttype')
    category_href = category['href']

    # Get all titles that do not belong to the current Locale or Category
    titles = Connection.my_sql_connection(CaboAppCenterContent::CONST_CABO_FRENCH_QUERY_CATEGORY_CATALOG_NEGATIVE_TITLE % category_name)
    titles_count = titles.count

    context "TC#{tc_num += 1}: Category = '#{category['name']}' - Total SKUs = #{titles_count}" do
      next unless app_available?(titles_count, "There are no apps available for Category: #{category_name}")

      product_html = nil
      before :all do
        fr_cabo_atg_app_center_page.load(CaboAppCenterContent::CONST_CABO_FILTER_URL % category_href)
        product_html = fr_cabo_atg_app_center_page.catalog_html_content
      end

      count = 0
      titles.each do |title|
        e_product = fr_cabo_atg_app_center_page.expected_catalog_product_info title

        it "#{count += 1}. Product ID = '#{e_product[:prod_number]}' - Name = '#{e_product[:short_name]}' - Category = '#{e_product[:content_type]}'" do
          a_product = fr_cabo_atg_app_center_page.product_not_exist?(product_html, e_product[:prod_number]) ? 'Not display' : 'Display'
          expect(a_product).to eq('Not display')
        end
      end
    end
  end
end
