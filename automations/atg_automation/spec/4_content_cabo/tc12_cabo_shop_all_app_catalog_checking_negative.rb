require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_cabo_english_page'

=begin
English Cabo Content: Verify apps that are not supported for current locale or LPAD3 platform shouldn't displayed
=end

describe "CABO English - Shop All App negative checking - Env: #{General::ENV_CONST} - Locale: #{General::LOCALE_CONST.upcase}" do
  context 'Verify titles that are not supported for current locale or LPAD3 device will be not displayed' do
    next unless app_exist?

    titles_list = Connection.my_sql_connection(CaboAppCenterContent::CONST_CABO_QUERY_SEARCH_NEGATIVE_TITLE)
    titles_count = titles_list.count

    next unless app_available? titles_count

    count = 0
    cabo_atg_app_center_page = AtgAppCenterCaboEnglishPage.new
    product_html1 = product_html2 = nil

    before :all do
      cabo_atg_app_center_page.load(CaboAppCenterContent::CONST_CABO_SHOP_ALL_APP_URL1)
      product_html1 = cabo_atg_app_center_page.catalog_html_content

      cabo_atg_app_center_page.load(CaboAppCenterContent::CONST_CABO_SHOP_ALL_APP_URL2)
      product_html2 = cabo_atg_app_center_page.catalog_html_content
    end

    titles_list.each do |title|
      e_product = cabo_atg_app_center_page.expected_catalog_product_info title

      it "#{count += 1}. Product ID = '#{e_product[:prod_number]}' - Name = '#{e_product[:short_name]}'" do
        a_product = cabo_atg_app_center_page.product_not_exist?(product_html1, e_product[:prod_number])
        a_product = cabo_atg_app_center_page.product_not_exist?(product_html2, e_product[:prod_number]) if a_product
        a_product = a_product ? 'Not display' : 'Display'

        expect(a_product).to eq('Not display')
      end
    end
  end
end
