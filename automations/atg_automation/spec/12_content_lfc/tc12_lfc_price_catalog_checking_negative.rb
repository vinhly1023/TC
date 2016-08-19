require File.expand_path('../../spec_helper', __FILE__)
require 'atg_app_center_lfc_english_page'

=begin
English LFC Content: Verify Products that don't match the Price or Locale should not display
=end

describe "LFC English - Price Catalog Negative - Env: #{General::ENV_CONST} - Locale: #{General::LOCALE_CONST.upcase}" do
  next unless app_exist?
  atg_app_center_page = AtgAppCenterLFCEnglishPage.new
  tc_num = 0

  price_list = Connection.my_sql_connection(AppCenterContent::CONST_QUERY_PRICE_CATALOG_DRIVE)
  price_list.each do |pr|
    price_name = pr['name']
    price_href = pr['href']

    # Get price range: $0 - $25 => price_from = 0, price_to = 25
    ar_price = Title.price_range(price_name)
    price_from = ar_price[:price_from]
    price_to = ar_price[:price_to]

    titles = Connection.my_sql_connection(AppCenterContent::CONST_QUERY_PRICE_CATALOG_NEGATIVE_TITLE % [price_from, price_to])
    titles_count = titles.count

    context "TC#{tc_num += 1}: Price = '#{price_name}' - Total SKUs = #{titles_count}" do
      next unless app_available?(titles_count, "There are no apps available for Price: from #{price_from} to #{price_to}")

      product_html = nil
      before :all do
        atg_app_center_page.load(AppCenterContent::CONST_FILTER_URL % price_href)
        product_html = atg_app_center_page.catalog_html_content
      end

      count = 0
      titles.each do |title|
        e_product = atg_app_center_page.expected_catalog_product_info title

        it "#{count += 1}. Product ID = '#{e_product[:prod_number]}' - Name = '#{e_product[:short_name]}' - Price = '#{e_product[:price]}'" do
          a_product = atg_app_center_page.product_not_exist?(product_html, e_product[:prod_number]) ? 'Not display' : 'Display'
          expect(a_product).to eq('Not display')
        end
      end
    end
  end
end
