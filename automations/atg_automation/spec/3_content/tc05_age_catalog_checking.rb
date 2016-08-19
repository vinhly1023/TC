require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_web_english_page'

=begin
English Web Content: Verify that Products that match with Age range and Locale should display
=end

describe "LFC Age catalog checking - Env: #{General::ENV_CONST} - Locale: #{General::LOCALE_CONST.upcase}" do
  next unless app_exist?
  atg_app_center_page = AtgAppCenterWebEnglishPage.new
  tc_num = 0

  age_list = Connection.my_sql_connection(AppCenterContent::CONST_QUERY_AGE_CATALOG_DRIVE)
  age_list.each do |ag|
    age_name = ag['name']
    age_number = age_name.gsub('years', '').strip
    age_href = ag['href']
    titles = Connection.my_sql_connection(AppCenterContent::CONST_QUERY_AGE_CATALOG_TITLE % [age_number, age_number])
    titles_count = titles.count

    context "TC#{tc_num += 1}: Age = '#{age_name}' - Total Apps = #{titles_count}" do
      next unless app_available?(titles_count, "There are no apps belong to Age: #{age_number}")

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
          product_info = atg_app_center_page.catalog_product_info(product_html1, e_product[:prod_number])
          product_info = atg_app_center_page.catalog_product_info(product_html2, e_product[:prod_number]) if product_info.empty?

          fail "Title #{e_product[:prod_number]} is missing" if product_info.empty?

          a_product = atg_app_center_page.actual_catalog_product_info product_info
          expect(a_product[:age]).to eq(e_product[:age])
        end
      end
    end
  end
end
