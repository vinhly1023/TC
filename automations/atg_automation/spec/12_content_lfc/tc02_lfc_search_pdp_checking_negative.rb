require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_lfc_english_page'

=begin
English LFC Content: Verify that Apps that don't support for current Locale are not displayed
=end

describe "LFC English - Search negative checking - Env: #{General::ENV_CONST} - Locale: #{General::LOCALE_CONST.upcase}" do
  context "Verify that Apps that don't support for current Locale are not displayed: #{AppCenterContent::CONST_SEARCH_URL}" do
    next unless app_exist?

    titles_list = Connection.my_sql_connection(AppCenterContent::CONST_QUERY_SEARCH_NEGATIVE_TITLE)
    titles_count = titles_list.count

    next unless app_available? titles_count

    atg_app_center_page = AtgAppCenterLFCEnglishPage.new
    count = 0

    titles_list.each do |title|
      e_product = atg_app_center_page.expected_catalog_product_info title
      a_product = ''

      before :all do
        atg_app_center_page.load(AppCenterContent::CONST_SEARCH_URL % e_product[:prod_number])
        product_html = atg_app_center_page.catalog_html_content
        a_product = atg_app_center_page.product_not_exist?(product_html, e_product[:prod_number]) ? 'Not display' : 'Display'
      end

      it "#{count += 1}. Product ID = '#{e_product[:prod_number]}' - Name = '#{e_product[:short_name]}'" do
        expect(a_product).to eq('Not display')
      end
    end
  end
end
