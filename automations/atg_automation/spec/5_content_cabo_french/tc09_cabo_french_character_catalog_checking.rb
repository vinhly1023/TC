require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_cabo_french_page'

=begin
French Cabo Content: Verify that Products that match with Character, Locale and LeapPad3 platform should display
=end

describe "CABO French - Character catalog checking - Env: #{General::ENV_CONST} - Locale: #{General::LOCALE_CONST.upcase}" do
  next unless app_exist?

  fr_cabo_atg_app_center_page = AtgAppCenterCaboFrenchPage.new
  tc_num = 0

  characters_list = Connection.my_sql_connection(CaboAppCenterContent::CONST_CABO_QUERY_CHARACTER_CATALOG_DRIVE)
  characters_list.each do |character|
    character_name = character['name']
    character_href = character['href']

    # Get all titles that belong to current locale and include character_name
    titles = Connection.my_sql_connection(CaboAppCenterContent::CONST_CABO_FRENCH_QUERY_CHARACTER_CATALOG_TITLE % character_name)
    titles_count = titles.count

    context "TC#{tc_num += 1}: Character = '#{character_name}' - Total SKUs = #{titles_count}" do
      next unless app_available?(titles_count, "There are no apps available for Character: #{character_name}")

      product_html = nil
      before :all do
        fr_cabo_atg_app_center_page.load(CaboAppCenterContent::CONST_CABO_FILTER_URL % character_href)
        product_html = fr_cabo_atg_app_center_page.catalog_html_content
      end

      count = 0
      titles.each do |title|
        e_product = fr_cabo_atg_app_center_page.expected_catalog_product_info title

        it "#{count += 1}. Product ID = '#{e_product[:prod_number]}' - Name = '#{e_product[:short_name]}'" do
          a_product = fr_cabo_atg_app_center_page.product_not_exist?(product_html, e_product[:prod_number]) ? 'Not display' : 'Display'
          expect(a_product).to eq('Display')
        end
      end
    end
  end
end
