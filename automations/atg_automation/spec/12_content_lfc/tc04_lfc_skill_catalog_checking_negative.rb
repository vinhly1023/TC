require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_lfc_english_page'

=begin
English LFC Content: Verify Products that don't match the Skill or Locale should not display
=end

describe "LFC English - Skill Catalog Negative checking - Env: #{General::ENV_CONST} - Locale: #{General::LOCALE_CONST.upcase}" do
  next unless app_exist?
  atg_app_center_page = AtgAppCenterLFCEnglishPage.new
  tc_num = 0

  skills_list = Connection.my_sql_connection(AppCenterContent::CONST_QUERY_SKILL_CATALOG_DRIVE)
  skills_list.each do |sk|
    skill_name = sk['name']
    skill_href = sk['href']
    titles = Connection.my_sql_connection(AppCenterContent::CONST_QUERY_SKILL_CATALOG_NEGATIVE_TITLE % skill_name)
    titles_count = titles.count

    context "TC#{tc_num += 1}: Skills = '#{skill_name}' - Total SKUs = #{titles_count}" do
      next unless app_available?(titles_count, "There are no apps available for Skill: #{skill_name}")

      product_html = nil
      before :all do
        atg_app_center_page.load(AppCenterContent::CONST_FILTER_URL % skill_href)
        product_html = atg_app_center_page.catalog_html_content
      end

      count = 0
      titles.each do |title|
        e_product = atg_app_center_page.expected_catalog_product_info title

        it "#{count += 1}. Product ID = '#{e_product[:prod_number]}' - Name = '#{e_product[:short_name]}'" do
          a_product = atg_app_center_page.product_not_exist?(product_html, e_product[:prod_number]) ? 'Not display' : 'Display'
          expect(a_product).to eq('Not display')
        end
      end
    end
  end
end
