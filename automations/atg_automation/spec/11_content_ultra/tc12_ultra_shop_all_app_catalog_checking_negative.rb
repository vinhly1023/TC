require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_ultra_english_page'

=begin
LeapPad Ultra Content: Verify apps that are not supported for current locale or LPAD3 platform shouldn't displayed
=end

describe "LeapPad Ultra - Shop All App negative checking - Env: #{General::ENV_CONST} - Locale: #{General::LOCALE_CONST.upcase}" do
  context 'Verify titles that are not supported for current locale or LPAD3 device will be not displayed' do
    next unless app_exist?

    titles_list = Connection.my_sql_connection(UltraAppCenterContent::CONST_ULTRA_QUERY_SEARCH_NEGATIVE_TITLE)
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

      it "#{count += 1}. Product ID = '#{e_product[:prod_number]}' - Name = '#{e_product[:short_name]}'" do
        a_product = ultra_atg_app_center_page.product_not_exist?(product_html1, e_product[:prod_number])
        a_product = ultra_atg_app_center_page.product_not_exist?(product_html2, e_product[:prod_number]) if a_product
        a_product = a_product ? 'Not display' : 'Display'

        expect(a_product).to eq('Not display')
      end
    end
  end
end
