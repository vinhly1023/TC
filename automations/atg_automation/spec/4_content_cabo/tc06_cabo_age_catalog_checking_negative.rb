require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_cabo_english_page'

=begin
English Cabo Content: Verify Products that don't match the Age range or Locale or LeapPad3 platform should not display
=end

describe "CABO English - Age negative checking - Env: #{General::ENV_CONST} - Locale: #{General::LOCALE_CONST.upcase}" do
  next unless app_exist?
  cabo_atg_app_center_page = AtgAppCenterCaboEnglishPage.new
  tc_num = 0

  age_list = Connection.my_sql_connection(CaboAppCenterContent::CONST_CABO_QUERY_AGE_CATALOG_DRIVE)
  age_list.each do |age|
    age_name = age['name']
    age_href = age['href']

    age_number = age_name.gsub('years', '').strip
    age_number = age_name.gsub('+ years', '').strip if (age_name == '7+ years')

    # Get all products that do not belong to current locale or current Age
    titles = Connection.my_sql_connection(CaboAppCenterContent::CONST_CABO_QUERY_AGE_CATALOG_NEGATIVE_TITLE % [age_number, age_number])
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
          a_product = cabo_atg_app_center_page.product_not_exist?(product_html, e_product[:prod_number]) ? 'Not display' : 'Display'
          expect(a_product).to eq('Not display')
        end
      end
    end
  end
end
