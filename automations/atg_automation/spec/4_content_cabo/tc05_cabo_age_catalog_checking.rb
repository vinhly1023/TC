require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_cabo_english_page'

=begin
English Cabo Content: English Cabo Content: Verify that Products that match with Age range, Locale and LeapPad3 platform should display
=end

describe "CABO English - Age catalog checking - Env: #{General::ENV_CONST} - Locale: #{General::LOCALE_CONST.upcase}" do
  next unless app_exist?

  cabo_atg_app_center_page = AtgAppCenterCaboEnglishPage.new
  tc_num = 0

  age_list = Connection.my_sql_connection(CaboAppCenterContent::CONST_CABO_QUERY_AGE_CATALOG_DRIVE)
  age_list.each do |age|
    age_name = age['name']
    age_href = age['href']

    # Get age number from age name: (e.g. age_name = '5 years' => age_number = 5)
    age_number = age_name.gsub('years', '').strip
    age_number = age_name.gsub('+ years', '').strip if (age_name == '7+ years')

    # Get all titles that belong to current locale and include age_name
    titles = Connection.my_sql_connection(CaboAppCenterContent::CONST_CABO_QUERY_AGE_CATALOG_TITLE % [age_number, age_number])
    titles_count = titles.count

    context "TC#{tc_num += 1}: Age = '#{age_name}' - Total SKUs = #{titles_count}" do
      next unless app_available?(titles_count, "There are no apps available for Age: #{age_name}")

      product_html = nil
      before :all do
        cabo_atg_app_center_page.load(CaboAppCenterContent::CONST_CABO_FILTER_URL % age_href)
        product_html = cabo_atg_app_center_page.catalog_html_content
      end

      count = 0
      titles.each do |title|
        e_product = cabo_atg_app_center_page.expected_catalog_product_info title

        it "#{count += 1}. Product ID = '#{e_product[:prod_number]}' - Name = '#{e_product[:short_name]}' - Age = '#{e_product[:age]}'" do
            product_info = cabo_atg_app_center_page.catalog_product_info(product_html, e_product[:prod_number])

            fail "***Title #{e_product[:prod_number]} is missing" if product_info.empty?

            a_product = cabo_atg_app_center_page.actual_catalog_product_info product_info
            expect(a_product[:age]).to eq(e_product[:age])
        end
      end
    end
  end
end
