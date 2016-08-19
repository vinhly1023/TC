require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_cabo_french_page'

=begin
French Cabo Content: Verify that apps are not supported for current locale shouldn't displayed on New page
=end

describe "CABO French - New Arrivals Negative Checking - Env: #{General::ENV_CONST} - Locale: #{General::LOCALE_CONST}" do
  context "Verify that apps are not supported for current locale shouldn't displayed on New page" do
    titles_list = Connection.my_sql_connection(CaboAppCenterContent::CONST_CABO_QUERY_SEARCH_NEGATIVE_TITLE)
    titles_count = titles_list.count

    next unless app_available? titles_count

    fr_cabo_atg_app_center_page = AtgAppCenterCaboFrenchPage.new
    product_html = nil

    before :all do
      new_href = Connection.my_sql_connection(CaboAppCenterContent::CONST_CABO_QUERY_NEW_DRIVE).first['href']
      fr_cabo_atg_app_center_page.load(AppCenterContent::CONST_FILTER_URL % new_href)
      product_html = fr_cabo_atg_app_center_page.catalog_html_content
    end

    tc_num = 0
    titles_list.each do |title|
      e_product = fr_cabo_atg_app_center_page.expected_catalog_product_info title
      a_product = ''

      before :all do
        a_product = fr_cabo_atg_app_center_page.product_not_exist?(product_html, e_product[:prod_number]) ? 'Not display' : 'Display'
      end

      it "#{tc_num += 1}. Product ID = '#{e_product[:prod_number]}' - Name = '#{e_product[:short_name]}'" do
        expect(a_product).to eq('Not display')
      end
    end
  end
end
