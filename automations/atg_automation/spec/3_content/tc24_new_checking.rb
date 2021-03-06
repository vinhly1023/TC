require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_web_english_page'

=begin
English Web Content: Verify that the New flag matches the corresponding Product ID/SKU and nothing more
=end

describe "New Arrivals Checking - Env: #{General::ENV_CONST} - Locale: #{General::LOCALE_CONST}" do
  titles_list = Connection.my_sql_connection(AppCenterContent::CONST_QUERY_SEARCH_TITLE)
  titles_count = titles_list.count

  next unless app_available? titles_count

  atg_app_center_page = AtgAppCenterWebEnglishPage.new
  product_html = nil

  before :all do
    new_href = Connection.my_sql_connection(AppCenterContent::CONST_QUERY_NEW_DRIVE).first['href']
    atg_app_center_page.load(AppCenterContent::CONST_FILTER_URL % new_href)
    product_html = atg_app_center_page.catalog_html_content
  end

  tc_num = 0
  titles_list.each do |title|
    e_product = atg_app_center_page.expected_catalog_product_info title

    it "#{tc_num += 1}. Product ID = '#{e_product[:prod_number]}' - Name = '#{e_product[:short_name]}'" do
      a_product = atg_app_center_page.product_not_exist?(product_html, e_product[:prod_number]) ? 'Not display' : 'Display'
      expect(a_product).to eq('Display')
    end
  end
end
