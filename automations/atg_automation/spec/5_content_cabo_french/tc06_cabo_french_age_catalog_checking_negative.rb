require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_cabo_french_page'

=begin
French Cabo Content: Verify Products that don't match the Age range or Locale or LeapPad3 platform should not display
=end

describe "CABO French - Age negative checking - Env: #{General::ENV_CONST} - Locale: #{General::LOCALE_CONST.upcase}" do
  next unless app_exist?
  fr_cabo_atg_app_center_page = AtgAppCenterCaboFrenchPage.new
  tc_num = 0

  age_list = Connection.my_sql_connection(CaboAppCenterContent::CONST_CABO_QUERY_AGE_CATALOG_DRIVE)
  age_list.each do |age|
    age_name = age['name']
    age_href = age['href']

    # Get age number from age name: (e.g. age_name = '5 years' => age_number = 5)
    age_number = (age_name == '7 ans et plus') ? age_name.gsub('ans et plus', '').strip : age_name.gsub('ans', '').strip

    # Get all products that do not belong to current locale or current Age
    titles = Connection.my_sql_connection(CaboAppCenterContent::CONST_CABO_QUERY_AGE_CATALOG_NEGATIVE_TITLE % [age_number, age_number])
    titles_count = titles.count

    context "TC#{tc_num += 1}: Age = '#{age_name}' - Total SKUs = #{titles_count}" do
      next unless app_available?(titles_count, "There are no apps available for Age: #{age_name}")

      product_html = nil
      before :all do
        fr_cabo_atg_app_center_page.load(CaboAppCenterContent::CONST_CABO_FILTER_URL % age_href)
        product_html = fr_cabo_atg_app_center_page.catalog_html_content
      end

      count = 0
      titles.each do |title|
        e_product = fr_cabo_atg_app_center_page.expected_catalog_product_info title

        it "#{count += 1}. Product ID = '#{e_product[:prod_number]}' - Name = '#{e_product[:short_name]}' - Age = '#{e_product[:age]}'" do
          a_product = fr_cabo_atg_app_center_page.product_not_exist?(product_html, e_product[:prod_number]) ? 'Not display' : 'Display'
          expect(a_product).to eq('Not display')
        end
      end
    end
  end
end
