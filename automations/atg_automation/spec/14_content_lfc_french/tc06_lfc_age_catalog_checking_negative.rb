require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_lfc_french_page'

=begin
French LFC Content: Verify Products that don't match the Age range or Locale should not display
=end

describe "LFC French - Age Catalog Negative - Env: #{General::ENV_CONST} - Locale: #{General::LOCALE_CONST}" do
  next unless app_exist?
  atg_app_center_page = AtgAppCenterLFCFrenchPage.new
  tc_num = 0

  age_list = Connection.my_sql_connection(AppCenterContent::CONST_QUERY_AGE_CATALOG_DRIVE)
  age_list.each do |age|
    age_name = age['name']
    age_number = age_name.gsub('ans', '').strip
    age_href = age['href']
    titles = Connection.my_sql_connection(AppCenterContent::CONST_QUERY_AGE_CATALOG_NEGATIVE_TITLE % [age_number, age_number])
    titles_count = titles.count

    context "TC#{tc_num += 1}: Age = '#{age_name}' - Total SKUs = #{titles_count}" do
      next unless app_available?(titles_count, "There are no apps available for Age: #{age_number}")

      product_html1 = product_html2 = nil
      before :all do
        atg_app_center_page.load(AppCenterContent::CONST_FILTER_URL % age_href)
        product_html1 = atg_app_center_page.catalog_html_content

        atg_app_center_page.load(AppCenterContent::CONST_FILTER_URL2 % age_href)
        product_html2 = atg_app_center_page.catalog_html_content
      end

      count = 0
      titles.each do |title|
        e_product = atg_app_center_page.expected_catalog_product_info title

        it "#{count += 1}. Product ID = '#{e_product[:prod_number]}' - Name = '#{e_product[:short_name]}' - Age = '#{e_product[:age]}'" do
          a_product = atg_app_center_page.product_not_exist?(product_html1, e_product[:prod_number])
          a_product = atg_app_center_page.product_not_exist?(product_html2, e_product[:prod_number]) if a_product
          a_product = a_product ? 'Not display' : 'Display'
          expect(a_product).to eq('Not display')
        end
      end
    end
  end
end
