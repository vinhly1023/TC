require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_cabo_english_page'

=begin
English Cabo Content: Verify that Apps that don't support for current Locale or LPAD3 platform are not displayed
=end

describe "CABO English - Search negative checking - Env: #{General::ENV_CONST} - Locale: #{General::LOCALE_CONST.upcase}" do
  context "Verify that Apps that don't support for current Locale or LPAD3 platform are not displayed: #{CaboAppCenterContent::CONST_CABO_SEARCH_URL}" do
    next unless app_exist?

    titles_list = Connection.my_sql_connection(CaboAppCenterContent::CONST_CABO_QUERY_SEARCH_NEGATIVE_TITLE)
    titles_count = titles_list.count

    next unless app_available? titles_count

    cabo_atg_app_center_page = AtgAppCenterCaboEnglishPage.new
    count = 0

    titles_list.each do |title|
      e_product = cabo_atg_app_center_page.expected_catalog_product_info title
      a_product = ''

      before :all do
        cabo_atg_app_center_page.load(CaboAppCenterContent::CONST_CABO_SEARCH_URL % e_product[:prod_number])
        product_html = cabo_atg_app_center_page.catalog_html_content
        a_product = cabo_atg_app_center_page.product_not_exist?(product_html, e_product[:prod_number]) ? 'Not display' : 'Display'
      end

      it "#{count += 1}. Product ID = '#{e_product[:prod_number]}' - Name = '#{e_product[:short_name]}'" do
        expect(a_product).to eq('Not display')
      end
    end
  end
end
