require 'lib/generate'
require 'lib/localesweep'
require 'connection'
require 'date'
require 'rails'
require 'json'
require 'automation_common'

$atg_xml_data = Nokogiri::XML(File.read $LOAD_PATH.detect { |path| path.index('data.xml') } || 'TEMPORARY DATA FILE IS MISSING. PLEASE RECHECK!')
$atg_configuration_data = ATGConfiguration.atg_configuration_data

def get_xml_data(path)
  $atg_xml_data.search(path).text
end

class General
  CONST_PROJECT_PATH = File.expand_path('..', File.dirname(__FILE__))

  FIRST_NAME_CONST = 'ltrc'
  LAST_NAME_CONST = 'vn'
  PASSWORD_CONST = '123456'
  NEW_PASSWORD_CONST = '987654321'

  WEB_DRIVER_CONST = get_xml_data('//information/webdriver')

  TEST_SUITE_CONST = get_xml_data('//testsuite').presence || '0'
  ENV_CONST = get_xml_data('//env').upcase.presence || 'UAT2'
  COM_SERVER_CONST = get_xml_data('//com_server').strip
  LANGUAGE_CONST = get_xml_data('//language').upcase.presence || 'EN'
  LOCALE_CONST = get_xml_data('//locale').upcase.presence || 'US'
  LOCALE_DOWNCASE_CONST = LOCALE_CONST.downcase
  LOCATION_CONST = LANGUAGE_CONST.downcase + '_' + LOCALE_CONST

  release_date = get_xml_data('//releasedate').upcase
  if release_date == 'ALL'
    CONST_RELEASE_DATE_SQL = ''
    CONST_RELEASE_DATE_EXIST_SQL = ''
  else
    CONST_RELEASE_DATE_SQL = "golivedate in ('#{release_date.gsub(';', "','")}') and"
    CONST_RELEASE_DATE_EXIST_SQL = "where golivedate in ('#{release_date.gsub(';', "','")}')"
  end

  if LOCALE_CONST.include?('FR_')
    LOCATION_URL_CONST = LOCALE_CONST.tr('_', '-').gsub('FR-ROW', 'FR-OF').downcase # E.g. if locale = 'FR_ROW' => 'FR-OF'
  else
    LOCATION_URL_CONST = 'en-' + LOCALE_DOWNCASE_CONST
  end

  case LOCALE_CONST
  when 'US'
    COUNTRY_CONST = 'USA'
  when 'CA'
    COUNTRY_CONST = 'Canada'
  else
    COUNTRY_CONST = General::LOCALE_CONST
  end

  # Leapfrog URL
  if COM_SERVER_CONST.blank?
    CONST_LF_URL = "http://#{ENV_CONST.downcase}-www.leapfrog.com"
  else
    CONST_LF_URL = "http://#{COM_SERVER_CONST}"
  end

  CONST_GROUP_BY = 'group by prodnumber, longname'
  CONST_CONCAT_GROUP = 'group_concat(pricetier) as \'prices_total\', group_concat(filesize) as \'filesizes_total\''
  CONST_SELECTED_FIELDS = 'sku, prodnumber, shortname, longname, agefrommonths, agetomonths, pricetier, contenttype, curriculum, skills, format, lfchar, platformcompatibility, group_concat(pricetier) as \'prices_total\''
end

class Data
  DATA_DRIVEN_CONST = get_xml_data '//data_driven_csv'
  DEVICE_STORE_CONST = get_xml_data '//device_store'
  PAYMENT_TYPE_CONST = get_xml_data '//payment_type'
end

class Account
  # CSC account info
  CSC_USERNAME_CONST = 'service'
  CSC_PASSWORD_CONST = 'welcome1'

  # Vindicia account info
  VIN_USERNAME_CONST = $atg_configuration_data[:vin_acc][:vin_username]
  VIN_PASSWORD_CONST = $atg_configuration_data[:vin_acc][:vin_password]

  # LeapFrog Account
  downcase_env = General::ENV_CONST.downcase
  EMAIL_EXIST_FULL_CONST = get_xml_data '//accfull'
  EMAIL_EXIST_EMPTY_CONST = get_xml_data '//accempty'
  EMAIL_EXIST_BALANCE_CONST = get_xml_data '//accbalance'
  EMAIL_GUEST_CONST = Generate.email('atg', downcase_env, General::LOCALE_DOWNCASE_CONST)
  EMAIL_GUEST_FULL_CONST = Generate.email('atg', downcase_env, "#{General::LOCALE_DOWNCASE_CONST}_full")
  EMAIL_GUEST_EMPTY_CONST = Generate.email('atg', downcase_env, "#{General::LOCALE_DOWNCASE_CONST}_empty")
  EMAIL_BALANCE_CONST = Generate.email('atg', downcase_env, "#{General::LOCALE_DOWNCASE_CONST}_balance")
  EMAIL_NEW_CSC_CONST = Generate.email('csc', downcase_env, General::LOCALE_DOWNCASE_CONST)
  EMAIL_EXP_CREDIT_CARD_CONST = 'ltrc_atg_qa_exp_credit_card@sharklasers.com'
end

class CreditCard
  # Get Credit Card information from atg_credit table
  credit_card = Connection.my_sql_connection('SELECT * FROM atg_credit LIMIT 1').first

  CARD_NUMBER_CONST = credit_card['card_number']
  CARD_TYPE_CONST = credit_card['card_type']
  CARD_CODE_CONST = CARD_NUMBER_CONST[-4..-1] # this get 4 latest digits Ex.'1128' #'4113'
  CARD_TEXT_CONST = "#{CARD_TYPE_CONST} X- #{CARD_CODE_CONST}" # 'Visa X- 4113'
  NAME_ON_CARD_CONST = 'ltrc vn'
  SECURITY_CARD_CONST = '123'
  EXPIRED_MONTH_CONST = '01'
  EXP_MONTH_NAME_CONST = General::LOCALE_CONST.include?('FR') ? 'Janvier' : 'January'
  EXPIRED_YEAR_CONST = '2018'
  EX_PAYMENT_INFO_CONST = "#{CARD_TYPE_CONST} XXXXXXXXXXXX#{CARD_CODE_CONST} Exp. #{EXPIRED_MONTH_CONST}/#{EXPIRED_YEAR_CONST[-2..-1]}"
end

class BillingAddress
  # Get Credit Card information from atg_credit table
  address = Connection.my_sql_connection(
    <<-INTERPOLATED_SQL
        SELECT * FROM atg_address
        WHERE locale = '#{General::LOCALE_CONST}'
        ORDER BY RAND()
        LIMIT 1
  INTERPOLATED_SQL
  ).first

  FIRST_NAME_CONST = 'ltrc'
  LAST_NAME_CONST = 'vn'
  BAD_ADDRESS_CONST = 'bad_address'

   if address
     STREET_CONST = address['address1']
     CITY_CONST = address['city']
     STATE_CONST = address['state']
     POSTAL_CONST = address['postal']
     PHONE_NUMBER_CONST = address['phone_number']
     EX_ADDRESS_INFO = "ltrc vn #{address['address1']} #{address['city']}, #{address['state']} #{address['postal']} #{address['phone_number']}"
     EX_BILLING_ADDRESS_INFO = "ltrc vn #{address['address1']} #{address['city']}, #{address['state']} #{address['postal']} #{address['phone_number']}"
   else
     STREET_CONST = ''
     CITY_CONST = ''
     STATE_CONST = ''
     POSTAL_CONST = ''
     PHONE_NUMBER_CONST = ''
     EX_ADDRESS_INFO = ''
     EX_BILLING_ADDRESS_INFO = ''
   end
end

class ProductInformation
  case General::LOCALE_CONST
  when 'US'
    SHIPPING_METHOD_CONST = '2nd Day Air'
    CURRENCY_CONST = '$'
  when 'CA'
    SHIPPING_METHOD_CONST = 'Expedited'
    CURRENCY_CONST = 'CAD'
  end

  ADDRESS_CONST = "#{BillingAddress::FIRST_NAME_CONST} #{BillingAddress::LAST_NAME_CONST} #{BillingAddress::STREET_CONST} #{BillingAddress::CITY_CONST}, #{BillingAddress::STATE_CONST} #{BillingAddress::POSTAL_CONST} #{BillingAddress::PHONE_NUMBER_CONST}"
  ORDER_COMPLETE_MESSAGE_CONST = 'Thank you. Your order has been completed. Your order confirmation number is .* Print'
  ORDER_SUMMARY_TEXT_CONST = "Order Summary Bill To #{CreditCard::NAME_ON_CARD_CONST} #{BillingAddress::STREET_CONST} #{BillingAddress::CITY_CONST}, #{BillingAddress::STATE_CONST} #{BillingAddress::POSTAL_CONST} #{BillingAddress::PHONE_NUMBER_CONST} %s"

  if General::LOCALE_CONST.include?('FR')
    ACC_LOCATION_CONST = 'fr_FR'
    MSG_ORDER_COMPLETED_CONST = 'Merci. Votre commande est complète.'
    ORDER_NUMBER_TITLE_CONST = 'N° DE COMMANDE :'
    SUB_TOTAL_TITLE_CONST = 'Sous-total :'
    PURCHASE_TOTAL_TITLE_CONST = 'Total achats :'
    AB_TITLE_CONST = 'Solde du compte'
    TAX_TITLE_CONST = 'Taxe :'
  else
    ACC_LOCATION_CONST = 'en_US'
    MSG_ORDER_COMPLETED_CONST = 'Thank you. Your order has been completed.'
    ORDER_NUMBER_TITLE_CONST = 'ORDER NUMBER:'
    SUB_TOTAL_TITLE_CONST = 'Order subtotal:'
    PURCHASE_TOTAL_TITLE_CONST = 'Purchase Total:'
    AB_TITLE_CONST = 'Account Balance'
    TAX_TITLE_CONST = 'Tax:'
  end
end

class PayPalInfo
  paypal_acc = $atg_configuration_data[:paypal_account]

  case General::LOCALE_CONST
  when 'US'
    CONST_P_EMAIL = paypal_acc[:p_us_acc][0]
    CONST_P_PASSWORD = paypal_acc[:p_us_acc][1]
  when 'CA'
    CONST_P_EMAIL = paypal_acc[:p_ca_acc][0]
    CONST_P_PASSWORD = paypal_acc[:p_ca_acc][1]
  when 'UK'
    CONST_P_EMAIL = paypal_acc[:p_uk_acc][0]
    CONST_P_PASSWORD = paypal_acc[:p_uk_acc][1]
  when 'IE'
    CONST_P_EMAIL = paypal_acc[:p_ie_acc][0]
    CONST_P_PASSWORD = paypal_acc[:p_ie_acc][1]
  when 'AU'
    CONST_P_EMAIL = paypal_acc[:p_au_acc][0]
    CONST_P_PASSWORD = paypal_acc[:p_au_acc][1]
  when 'ROW'
    CONST_P_EMAIL = paypal_acc[:p_row_acc][0]
    CONST_P_PASSWORD = paypal_acc[:p_row_acc][1]
  end
end

class URL
  # ATG Digital Web urls
  ATG_APP_CENTER_URL = Title.url_mapping "#{General::CONST_LF_URL}/#{General::LOCATION_URL_CONST.downcase}/app-center/c"
  ATG_APP_CENTER_ALL_APPS_URL = ATG_APP_CENTER_URL + '?No=0&Nrpp=2000'
  PDP_WEB_URL = Title.url_mapping "#{General::CONST_LF_URL}/#{General::LOCATION_URL_CONST.downcase}/app-center/p"
  PDP_LFC_URL = Title.url_mapping "#{General::CONST_LF_URL}/#{General::LOCATION_URL_CONST.downcase}/app-center-lfc/p"
  PDP_CABO_URL = Title.url_mapping "#{General::CONST_LF_URL}/#{General::LOCATION_URL_CONST.downcase}/app-center-lpad3e/p"
  PDP_ULTRA_URL = Title.url_mapping "#{General::CONST_LF_URL}/#{General::LOCATION_URL_CONST.downcase}/app-center-dv/p"

  # ATG Device Store App Center urls
  device_store_info = JSON.parse(File.read("#{General::CONST_PROJECT_PATH}/data/device_store_urls.json"))[Data::DEVICE_STORE_CONST]
  ATG_DV_APP_CENTER_URL = device_store_info.nil? ? '' : device_store_info['url']

  # Vindicia url
  VIN_CONST = 'https://secure.prodtest.sj.vindicia.com/login/secure/index.html'

  # Get approriate csc url on UAT or UAT2
  case General::ENV_CONST
  when 'UAT'
    CSC_CONST = 'http://emrlatgcsc01.leapfrog.com:7007/agent/login.jsp'
  when 'UAT2'
    CSC_CONST = 'http://emrlatgcsc02.leapfrog.com:7007/agent/login.jsp'
  else
    CSC_CONST = '#'
  end
end

class TableName
  if General::LANGUAGE_CONST == 'EN'
    CONST_MOAS_TABLE = 'atg_moas'
  else
    CONST_MOAS_TABLE = 'atg_moas_fr'
  end

  case General::TEST_SUITE_CONST
  when 'English ATG Web Content'
    CONST_FILTER_TABLE = 'atg_filter_list'
  when 'English ATG LFC Content', 'French ATG LFC Content'
    CONST_FILTER_TABLE = 'atg_lfc_filter_list'
  when 'English ATG Cabo Content'
    CONST_FILTER_TABLE = 'atg_cabo_filter_list'
  when 'French ATG Cabo Content'
    CONST_FILTER_TABLE = 'atg_cabo_filter_list'
  when 'English ATG LeapPad Ultra Content'
    CONST_FILTER_TABLE = 'atg_ultra_filter_list'
  else
    CONST_FILTER_TABLE = ''
  end
end

# ATG Digital Web and LFC Content
class AppCenterContent
  if General::TEST_SUITE_CONST == 'English ATG LFC Content' || General::TEST_SUITE_CONST == 'French ATG LFC Content'
    ac_path = 'app-center-lfc'
    ac_search_path = 'app-center-lfc'
    ac_quickview_search_path = 'app-center-lfc'
    ac_catalog_param = '?Endeca_user_segments=UsrSeg_50_SGSite&'
    ac_search_param = '_/N-1z141rr?Endeca_user_segments=UsrSeg_50_SGSite&'
  else
    ac_path = 'app-center'
    ac_search_path = 'store'
    ac_quickview_search_path = 'app-center'
    ac_catalog_param = '?'
    ac_search_param = '_/N-1z141rr?'
  end

  CONST_CHECKOUT_URL = Title.url_mapping "#{General::CONST_LF_URL}/en-#{General::LOCALE_DOWNCASE_CONST}/#{ac_path}/checkout/"
  CONST_LOGIN_URL = Title.url_mapping "#{General::CONST_LF_URL}/en-#{General::LOCALE_DOWNCASE_CONST}/#{ac_path}/profile/login.jsp?"
  CONST_SEARCH_URL = Title.url_mapping "#{General::CONST_LF_URL}/en-#{General::LOCALE_DOWNCASE_CONST}/#{ac_search_path}/search/#{ac_search_param}Ntt=%s&Nty=1"
  CONST_SEARCH_FRENCH_URL = Title.url_mapping "#{General::CONST_LF_URL}/#{General::LOCALE_DOWNCASE_CONST}/#{ac_search_path}/search/#{ac_search_param}Ntt=%s&Nty=1"
  CONST_QUICK_VIEW_SEARCH_URL = Title.url_mapping "#{General::CONST_LF_URL}/en-#{General::LOCALE_DOWNCASE_CONST}/#{ac_quickview_search_path}/search/#{ac_search_param}Ntt=%s&Nty=1"
  CONST_QUICK_VIEW_SEARCH_FRENCH_URL = Title.url_mapping "#{General::CONST_LF_URL}/#{General::LOCALE_DOWNCASE_CONST}/#{ac_quickview_search_path}/search/#{ac_search_param}Ntt=%s&Nty=1"
  CONST_CHARACTER_URL = Title.url_mapping "#{General::CONST_LF_URL}%s#{ac_catalog_param}No=0&Nrpp=2000&Ns=P_NewUntil%%7C1&showMoreIds=3"
  CONST_FILTER_URL = Title.url_mapping "#{General::CONST_LF_URL}%s#{ac_catalog_param}No=0&Nrpp=2000&Ns=P_NewUntil%%7C1"
  CONST_FILTER_URL2 = Title.url_mapping "#{General::CONST_LF_URL}%s#{ac_catalog_param}No=1000&Nrpp=1000&Ns=P_NewUntil%%7C1"
  CONT_PDP_URL = Title.url_mapping "#{General::CONST_LF_URL}%s"

  # Getting price tier based on locale
  CONST_PRICE_TIER = Connection.my_sql_connection("select * from atg_pricetier where locale like '#{General::LOCALE_CONST}%';")

  # SQL query for Search
  CONST_QUERY_CHECK_APP_EXIST = "select * from #{TableName::CONST_MOAS_TABLE} #{General::CONST_RELEASE_DATE_EXIST_SQL}"
  CONST_QUERY_SEARCH_TITLE = "select *, #{General::CONST_CONCAT_GROUP} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} #{General::LOCALE_CONST} = 'x' #{General::CONST_GROUP_BY}"
  CONST_QUERY_SEARCH_NEGATIVE_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} #{General::LOCALE_CONST} = '' #{General::CONST_GROUP_BY}"

  # SQL query for New Arrivals
  CONST_QUERY_NEW_DRIVE = "select name, href from #{TableName::CONST_FILTER_TABLE} where locale = '#{General::LOCALE_CONST}' and type = 'New'"

  # SQL query for Skill
  CONST_QUERY_SKILL_CATALOG_DRIVE = "select name, href from #{TableName::CONST_FILTER_TABLE} where locale = '#{General::LOCALE_CONST}' and type = 'Skills'"
  CONST_QUERY_SKILL_CATALOG_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} #{General::LOCALE_CONST} = 'x' and skills like '%%%s%%' #{General::CONST_GROUP_BY}"
  CONST_QUERY_SKILL_CATALOG_NEGATIVE_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} (#{General::LOCALE_CONST} = '' or skills not like '%%%s%%') #{General::CONST_GROUP_BY}"

  # SQL query for Age
  CONST_QUERY_AGE_CATALOG_DRIVE = "select name, href from #{TableName::CONST_FILTER_TABLE} where locale = '#{General::LOCALE_CONST}' and type = 'Age'"
  CONST_QUERY_AGE_CATALOG_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} #{General::LOCALE_CONST} = 'x' and agefrommonths/12 <= %s and agetomonths/12 >= %s #{General::CONST_GROUP_BY}"
  CONST_QUERY_AGE_CATALOG_NEGATIVE_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} (#{General::LOCALE_CONST} = '' or agefrommonths/12 > %s or agetomonths/12 < %s) #{General::CONST_GROUP_BY}"

  # SQL query for Product
  CONST_QUERY_PRODUCT_CATALOG_DRIVE = "select name, href from #{TableName::CONST_FILTER_TABLE} where locale = '#{General::LOCALE_CONST}' and type = 'Product'"
  CONST_QUERY_PRODUCT_CATALOG_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} #{General::LOCALE_CONST} = 'x' and platformcompatibility like '%%%s%%' #{General::CONST_GROUP_BY}"
  CONST_QUERY_PRODUCT_CATALOG_NEGATIVE_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} (#{General::LOCALE_CONST} = '' or platformcompatibility not like '%%%s%%') #{General::CONST_GROUP_BY}"

  # SQL query for Character
  CONST_QUERY_CHARACTER_CATALOG_DRIVE = "select name, href from #{TableName::CONST_FILTER_TABLE} where locale = '#{General::LOCALE_CONST}' and type = 'Character'"
  CONST_QUERY_CHARACTER_CATALOG_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} #{General::LOCALE_CONST} = 'x' and concat(',',lfchar,',') like '%%,%s,%%' and trim(prodnumber) <> '' #{General::CONST_GROUP_BY}"
  CONST_QUERY_CHARACTER_CATALOG_NEGATIVE_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} (#{General::LOCALE_CONST} = '' or concat(',',lfchar,',') not like '%%,%s,%%') and trim(prodnumber) <> '' #{General::CONST_GROUP_BY}"

  # SQL query for Price
  CONST_PRICE = "sum((select price from atg_pricetier where tier = left(pricetier, locate('-', pricetier) - 2) and locale like '#{General::LOCALE_CONST}')) as 'price'"
  CONST_QUERY_PRICE_CATALOG_DRIVE = "select name, href from #{TableName::CONST_FILTER_TABLE} where locale = '#{General::LOCALE_CONST}' and type = 'Price'"
  CONST_QUERY_PRICE_CATALOG_TITLE = "select #{General::CONST_SELECTED_FIELDS}, #{CONST_PRICE} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} #{General::LOCALE_CONST} = 'x' #{General::CONST_GROUP_BY} having (price >= %s and price <= %s)"
  CONST_QUERY_PRICE_CATALOG_NEGATIVE_TITLE = <<-INTERPOLATED_SQL
    select #{General::CONST_SELECTED_FIELDS}, #{CONST_PRICE} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} #{General::LOCALE_CONST} = '' or pricetier = '' #{General::CONST_GROUP_BY}
    union all
    select #{General::CONST_SELECTED_FIELDS}, #{CONST_PRICE} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} #{General::LOCALE_CONST} = 'x' #{General::CONST_GROUP_BY} having (price < %s or price > %s)
  INTERPOLATED_SQL

  # SQL query for Type/Format
  CONST_QUERY_TYPE_CATALOG_DRIVE = "select name, href from #{TableName::CONST_FILTER_TABLE} where locale = '#{General::LOCALE_CONST}' and type = 'Type'"
  CONST_QUERY_TYPE_CATALOG_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} #{General::LOCALE_CONST} = 'x' and format = '%s' #{General::CONST_GROUP_BY}"
  CONST_QUERY_TYPE_CATALOG_NEGATIVE_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} (#{General::LOCALE_CONST} = '' or format != '%s') #{General::CONST_GROUP_BY}"

  # SQL query for platform compatibility
  CONST_QUERY_CATEGORY_CATALOG_DRIVE = "select name, href from #{TableName::CONST_FILTER_TABLE} where locale = '#{General::LOCALE_CONST}' and type = 'Category'"
  CONST_QUERY_CATEGORY_CATALOG_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} #{General::LOCALE_CONST} = 'x' and contenttype in ('%s', '%s') #{General::CONST_GROUP_BY}"
  CONST_QUERY_CATEGORY_CATALOG_NEGATIVE_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} (#{General::LOCALE_CONST} = '' or contenttype not in ('%s', '%s')) #{General::CONST_GROUP_BY}"

  # SQL query for YMAL
  CONST_QUERY_GET_YMAL_INFO = "select sku, prodnumber, longname, platformcompatibility, us, ca, uk, ie, au, row from #{TableName::CONST_MOAS_TABLE} where prodnumber = '%s' and #{General::LOCALE_CONST} = 'x' #{General::CONST_GROUP_BY}"

  # SQL query for promotion codes
  if General::ENV_CONST == 'PROD'
    CONST_QUERY_PROMOTION_CODES_DRIVE = 'select * from atg_promotions where env = \'PROD\''
  else
    CONST_QUERY_PROMOTION_CODES_DRIVE = 'select * from atg_promotions where env = \'QA\''
  end
end

# ATG Cabo English/French Content
class CaboAppCenterContent
  CONST_CABO_SEARCH_URL = Title.url_mapping "#{General::CONST_LF_URL}/#{General::LOCATION_URL_CONST}/app-center-lpad3e/search/_/N-1z141rr?Ntt=%s&Nty=1"
  CONST_CABO_FILTER_URL = Title.url_mapping "#{General::CONST_LF_URL}%s?No=0&Nrpp=2000&Ns=P_NewUntil%%7C1"
  CONST_CABO_SHOP_ALL_APP_URL1 = Title.url_mapping "#{General::CONST_LF_URL}/#{General::LOCATION_URL_CONST}/app-center-lpad3e/c?No=0&Nrpp=2000&Ns=P_NewUntil%7C1"
  CONST_CABO_SHOP_ALL_APP_URL2 = Title.url_mapping "#{General::CONST_LF_URL}/#{General::LOCATION_URL_CONST}/app-center-lpad3e/c?No=1000&Nrpp=1000&Ns=P_NewUntil%7C1"

  # SQL query for Searching
  CONST_CABO_QUERY_SEARCH_TITLE = "select *, #{General::CONST_CONCAT_GROUP} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} #{General::LOCALE_CONST} = 'x' and platformcompatibility like '%%LeapPad3%%' #{General::CONST_GROUP_BY}"
  CONST_CABO_QUERY_SEARCH_NEGATIVE_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} (platformcompatibility not like '%%LeapPad3%%' or #{General::LOCALE_CONST} != 'x') #{General::CONST_GROUP_BY}"

  # SQL query for New Arrivals
  CONST_CABO_QUERY_NEW_DRIVE = "select name, href from #{TableName::CONST_FILTER_TABLE} where locale = '#{General::LOCALE_CONST}' and type = 'New'"

  # SQL query for Skill Catalog
  CONST_CABO_QUERY_SKILL_CATALOG_DRIVE = "select name, href from #{TableName::CONST_FILTER_TABLE} where locale = '#{General::LOCALE_CONST}' and type = 'Skills'"
  CONST_CABO_QUERY_SKILL_CATALOG_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} #{General::LOCALE_CONST} = 'x' and platformcompatibility like '%%LeapPad3%%' and skills like \"%%%s%%\" #{General::CONST_GROUP_BY}"
  CONST_CABO_QUERY_SKILL_CATALOG_NEGATIVE_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} (platformcompatibility not like '%%LeapPad3%%' or #{General::LOCALE_CONST} = '' or skills not like \"%%%s%%\") #{General::CONST_GROUP_BY}"

  # SQL query for Age Catalog
  CONST_CABO_QUERY_AGE_CATALOG_DRIVE = "select name, href from #{TableName::CONST_FILTER_TABLE} where locale = '#{General::LOCALE_CONST}' and type = 'Age'"
  CONST_CABO_QUERY_AGE_CATALOG_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} #{General::LOCALE_CONST} = 'x' and platformcompatibility like '%%LeapPad3%%' and agefrommonths/12 <= %s and agetomonths/12 >= %s #{General::CONST_GROUP_BY}"
  CONST_CABO_QUERY_AGE_CATALOG_NEGATIVE_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} (platformcompatibility not like '%%LeapPad3%%' or #{General::LOCALE_CONST} = '' or agefrommonths/12 > %s or agetomonths/12 < %s) #{General::CONST_GROUP_BY}"

  # SQL query for Character Catalog
  CONST_CABO_QUERY_CHARACTER_CATALOG_DRIVE = "select name, href from #{TableName::CONST_FILTER_TABLE} where locale = '#{General::LOCALE_CONST}' and type = 'Character'"
  CONST_CABO_QUERY_CHARACTER_CATALOG_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} #{General::LOCALE_CONST} = 'x' and platformcompatibility like '%%LeapPad3%%' and concat(',',lfchar,',') like \"%%,%s,%%\" and trim(prodnumber) <> '' #{General::CONST_GROUP_BY}"
  CONST_CABO_QUERY_CHARACTER_CATALOG_NEGATIVE_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} (platformcompatibility not like '%%LeapPad3%%' or #{General::LOCALE_CONST} = '' or concat(',',lfchar,',') not like \"%%,%s,%%\") and trim(prodnumber) <> '' #{General::CONST_GROUP_BY}"
  CONST_CABO_FRENCH_QUERY_CHARACTER_CATALOG_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} #{General::LOCALE_CONST} = 'x' and platformcompatibility like '%%LeapPad3%%' and concat(';',lfchar,';') like \"%%;%s|%%\" and trim(prodnumber) <> '' #{General::CONST_GROUP_BY}"
  CONST_CABO_FRENCH_QUERY_CHARACTER_CATALOG_NEGATIVE_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} (platformcompatibility not like '%%LeapPad3%%' or #{General::LOCALE_CONST} = '' or concat(';',lfchar,';') not like \"%%;%s|%%\") and trim(prodnumber) <> '' #{General::CONST_GROUP_BY}"

  # SQL query for Content/Type - Cabo (Category)
  CONST_CABO_QUERY_CATEGORY_CATALOG_DRIVE = "select name, href from #{TableName::CONST_FILTER_TABLE} where locale = '#{General::LOCALE_CONST}' and type = 'Category'"
  CONST_CABO_QUERY_CATEGORY_CATALOG_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} #{General::LOCALE_CONST} = 'x' and platformcompatibility like '%%LeapPad3%%' and contenttype in ('%s', '%s') #{General::CONST_GROUP_BY}"
  CONST_CABO_QUERY_CATEGORY_CATALOG_NEGATIVE_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} (platformcompatibility not like '%%LeapPad3%%' or #{General::LOCALE_CONST} = '' or contenttype not in ('%s', '%s')) #{General::CONST_GROUP_BY}"
  CONST_CABO_FRENCH_QUERY_CATEGORY_CATALOG_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} #{General::LOCALE_CONST} = 'x' and platformcompatibility like '%%LeapPad3%%' and contenttype = \"%s\" #{General::CONST_GROUP_BY}"
  CONST_CABO_FRENCH_QUERY_CATEGORY_CATALOG_NEGATIVE_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} (platformcompatibility not like '%%LeapPad3%%' or #{General::LOCALE_CONST} = '' or contenttype != \"%s\") #{General::CONST_GROUP_BY}"

  # SQL query for YMAL
  CONST_CABO_QUERY_GET_YMAL_INFO = "select sku, prodnumber, longname, platformcompatibility, us, ca, uk, ie, au, row from #{TableName::CONST_MOAS_TABLE} where prodnumber = '%s' and #{General::LOCALE_CONST} = 'x' and platformcompatibility like '%%LeapPad3%%' #{General::CONST_GROUP_BY}"
end

# ATG LeapPad Ultra Content
class UltraAppCenterContent
  CONST_ULTRA_SEARCH_URL = Title.url_mapping "#{General::CONST_LF_URL}/#{General::LOCATION_URL_CONST}/app-center-dv/search/_/N-1z141rr?Ntt=%s&Nty=1"
  CONST_ULTRA_FILTER_URL = Title.url_mapping "#{General::CONST_LF_URL}%s?No=0&Nrpp=2000&Ns=P_NewUntil%%7C1"
  CONST_ULTRA_SHOP_ALL_APP_URL1 = Title.url_mapping "#{General::CONST_LF_URL}/#{General::LOCATION_URL_CONST}/app-center-dv/c?No=0&Nrpp=2000&Ns=P_NewUntil%7C1"
  CONST_ULTRA_SHOP_ALL_APP_URL2 = Title.url_mapping "#{General::CONST_LF_URL}/#{General::LOCATION_URL_CONST}/app-center-dv/c?No=1000&Nrpp=1000&Ns=P_NewUntil%7C1"

  # SQL query for Searching
  CONST_ULTRA_QUERY_SEARCH_TITLE = "select *, #{General::CONST_CONCAT_GROUP} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} #{General::LOCALE_CONST} = 'x' and platformcompatibility like '%%LeapPad Ultra%%' #{General::CONST_GROUP_BY}"
  CONST_ULTRA_QUERY_SEARCH_NEGATIVE_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} (platformcompatibility not like '%%LeapPad Ultra%%' or #{General::LOCALE_CONST} != 'x') #{General::CONST_GROUP_BY}"

  # SQL query for New Arrivals
  CONST_ULTRA_QUERY_NEW_DRIVE = "select name, href from #{TableName::CONST_FILTER_TABLE} where locale = '#{General::LOCALE_CONST}' and type = 'New'"

  # SQL query for Skill Catalog
  CONST_ULTRA_QUERY_SKILL_CATALOG_DRIVE = "select name, href from #{TableName::CONST_FILTER_TABLE} where locale = '#{General::LOCALE_CONST}' and type = 'Skills'"
  CONST_ULTRA_QUERY_SKILL_CATALOG_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} #{General::LOCALE_CONST} = 'x' and platformcompatibility like '%%LeapPad Ultra%%' and skills like \"%%%s%%\" #{General::CONST_GROUP_BY}"
  CONST_ULTRA_QUERY_SKILL_CATALOG_NEGATIVE_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} (platformcompatibility not like '%%LeapPad Ultra%%' or #{General::LOCALE_CONST} = '' or skills not like \"%%%s%%\") #{General::CONST_GROUP_BY}"

  # SQL query for Age Catalog
  CONST_ULTRA_QUERY_AGE_CATALOG_DRIVE = "select name, href from #{TableName::CONST_FILTER_TABLE} where locale = '#{General::LOCALE_CONST}' and type = 'Age'"
  CONST_ULTRA_QUERY_AGE_CATALOG_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} #{General::LOCALE_CONST} = 'x' and platformcompatibility like '%%LeapPad Ultra%%' and agefrommonths/12 <= %s and agetomonths/12 >= %s #{General::CONST_GROUP_BY}"
  CONST_ULTRA_QUERY_AGE_CATALOG_NEGATIVE_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} (platformcompatibility not like '%%LeapPad Ultra%%' or #{General::LOCALE_CONST} = '' or agefrommonths/12 > %s or agetomonths/12 < %s) #{General::CONST_GROUP_BY}"

  # SQL query for Character Catalog
  CONST_ULTRA_QUERY_CHARACTER_CATALOG_DRIVE = "select name, href from #{TableName::CONST_FILTER_TABLE} where locale = '#{General::LOCALE_CONST}' and type = 'Character'"
  CONST_ULTRA_QUERY_CHARACTER_CATALOG_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} #{General::LOCALE_CONST} = 'x' and platformcompatibility like '%%LeapPad Ultra%%' and concat(',',lfchar,',') like \"%%,%s,%%\" and trim(prodnumber) <> '' #{General::CONST_GROUP_BY}"
  CONST_ULTRA_QUERY_CHARACTER_CATALOG_NEGATIVE_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} (platformcompatibility not like '%%LeapPad Ultra%%' or #{General::LOCALE_CONST} = '' or concat(',',lfchar,',') not like \"%%,%s,%%\") and trim(prodnumber) <> '' #{General::CONST_GROUP_BY}"

  # SQL query for Content/Type - Cabo (Category)
  CONST_ULTRA_QUERY_CATEGORY_CATALOG_DRIVE = "select name, href from #{TableName::CONST_FILTER_TABLE} where locale = '#{General::LOCALE_CONST}' and type = 'Category'"
  CONST_ULTRA_QUERY_CATEGORY_CATALOG_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} #{General::LOCALE_CONST} = 'x' and platformcompatibility like '%%LeapPad Ultra%%' and contenttype in ('%s', '%s') #{General::CONST_GROUP_BY}"
  CONST_ULTRA_QUERY_CATEGORY_CATALOG_NEGATIVE_TITLE = "select #{General::CONST_SELECTED_FIELDS} from #{TableName::CONST_MOAS_TABLE} where #{General::CONST_RELEASE_DATE_SQL} (platformcompatibility not like '%%LeapPad Ultra%%' or #{General::LOCALE_CONST} = '' or contenttype not in ('%s', '%s')) #{General::CONST_GROUP_BY}"
end

class AppCenterAccount
  # ATG configuration data
  acc_account = $atg_configuration_data[:ac_account]
  EMPTY_ACC = acc_account[:empty_acc]
  CREDIT_ACC = acc_account[:credit_acc]
  BALANCE_ACC = acc_account[:balance_acc]
  CREDIT_BALANCE_ACC = acc_account[:credit_balance_acc]

  # Leapfrog accounts
  leapfrog_account = $atg_configuration_data[:leapfrog_account]
  case General::ENV_CONST
  when 'DEV'
    LEAPFROG_ACC = leapfrog_account[:dev_acc].split('/')
  when 'DEV2'
    LEAPFROG_ACC = leapfrog_account[:dev2_acc].split('/')
  when 'STAGING'
    LEAPFROG_ACC = leapfrog_account[:staging_acc].split('/')
  when 'UAT'
    LEAPFROG_ACC = leapfrog_account[:uat_acc].split('/')
  when 'UAT2'
    LEAPFROG_ACC = leapfrog_account[:uat2_acc].split('/')
  when 'PREVIEW'
    LEAPFROG_ACC = leapfrog_account[:preview_acc].split('/')
  when 'PROD'
    LEAPFROG_ACC = leapfrog_account[:prod_acc].split('/')
  else
    LEAPFROG_ACC = []
  end
end

class ServicesInfo
  CONST_PROJECT_PATH = File.expand_path('..', File.dirname(__FILE__))
  CONST_CALLER_ID = '755e6f29-b7c8-4b98-8739-a1a7096f879e'

  if General::ENV_CONST == 'PROD'
    CONST_INMON_URL = 'http://evplcis.leapfrog.com:8080/inmon/services/'
    CONST_GAME_LOG_UPLOAD_ENDPOINT = 'http://devicelog.leapfrog.com/upca/device_log_upload'
    CONST_REST_ENDPOINT = 'http://evplcis.leapfrog.com:8080/inmon/resting/v1'
  elsif General::ENV_CONST == 'PREVIEW' || General::ENV_CONST == 'STAGING'
    CONST_INMON_URL = 'http://evslcis2.leapfrog.com:8080/inmon/services/'
    CONST_REST_ENDPOINT = 'http://evslcis2.leapfrog.com:8080/inmon/resting/v1'
    CONST_GAME_LOG_UPLOAD_ENDPOINT = 'http://qa-devicelog.leapfrog.com/upca/device_log_upload'
  else # QA, UAT, UAT2
    CONST_INMON_URL = 'http://emqlcis.leapfrog.com:8080/inmon/services/'
    CONST_GAME_LOG_UPLOAD_ENDPOINT = 'http://qa-devicelog.leapfrog.com/upca/device_log_upload'
    CONST_REST_ENDPOINT = 'http://emqlcis.leapfrog.com:8080/inmon/resting/v1'
  end

  CONST_GAME_LOG_UPLOAD_NAMESPACE = 'http://services.leapfrog.com/inmon/device/logs/upload/'

  inmon_endpoints = JSON.parse(File.read("#{File.expand_path('../..', File.dirname(__FILE__))}/lib/inmon_endpoints.json"), symbolize_names: true)
  inmon_endpoints.each_key { |k| inmon_endpoints[k][:endpoint] = CONST_INMON_URL + inmon_endpoints[k][:endpoint] }

  CONST_INMON_ENDPOINTS = inmon_endpoints

  CONST_CREATE_PARENT = '/parent'
  CONST_FETCH_DEVICE = '/devices/%s'
  CONST_UPDATE_BOGOTA = '/devices/%s/users'
  CONST_OWNER_BOGOTA = '/devices/%s/owner'
end

class ConstMessage
  PRE_CONDITION_FAIL = 'Blocked: Pre-condition failed'
end

class TimeOut
  READ_TIMEOUT_CONST = 260 # for page load
  WAIT_CONTROL_CONST = 45 # for control
  WAIT_SMALL_CONST = 2
  WAIT_MID_CONST = 5
  WAIT_BIG_CONST = 40 # for ajax
  WAIT_EMAIL = 60 # time to wait email from server
end