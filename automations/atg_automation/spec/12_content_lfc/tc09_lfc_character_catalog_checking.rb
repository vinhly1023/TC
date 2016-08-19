require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_lfc_english_page'

=begin
English LFC Content: Verify that Products that match with Character and Locale should display
=end

describe "LFC English - Character catalog checking - Env: #{General::ENV_CONST} - Locale: #{General::LOCALE_CONST.upcase}" do
  next unless app_exist?

  atg_app_center_page = AtgAppCenterLFCEnglishPage.new
  tc_num = 0

  character_list = Connection.my_sql_connection(AppCenterContent::CONST_QUERY_CHARACTER_CATALOG_DRIVE)
  character_list.each do |ch|
    character_name = ch['name']
    character_href = ch['href']
    titles = Connection.my_sql_connection(AppCenterContent::CONST_QUERY_CHARACTER_CATALOG_TITLE % character_name)
    titles_count = titles.count

    context "TC#{tc_num += 1}: Character = '#{character_name}' - Total SKUs = #{titles_count}" do
      next unless app_available?(titles_count, "There are no apps available for Character: #{character_name}")

      product_html = nil
      before :all do
        atg_app_center_page.load(AppCenterContent::CONST_FILTER_URL % character_href)
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
