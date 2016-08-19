require File.expand_path('../../spec/spec_helper', __FILE__)
require 'atg_checkout_payment_page'
require 'atg_dv_check_out_payment_page'
require 'atg_dv_check_out_review_page'
require 'mail_detail_page'

def dv_check_out_method(payment_method, device_store)
  env = General::ENV_CONST.upcase == 'PROD' ? 'PROD' : 'QA'
  atg_dv_payment_page = AtgDvCheckOutPaymentPage.new
  review_page = AtgDvCheckOutReviewPage.new

  if payment_method.include?('Credit Card') || payment_method.include?('CC + Balance')
    credit_card = {
      card_number: CreditCard::CARD_NUMBER_CONST,
      cart_type: CreditCard::CARD_TYPE_CONST,
      card_name: CreditCard::NAME_ON_CARD_CONST,
      exp_month: CreditCard::EXP_MONTH_NAME_CONST,
      exp_year: CreditCard::EXPIRED_YEAR_CONST,
      security_code: CreditCard::SECURITY_CARD_CONST
    }

    billing_address = {
      first_name: BillingAddress::FIRST_NAME_CONST,
      last_name: BillingAddress::LAST_NAME_CONST,
      street: BillingAddress::STREET_CONST,
      city: BillingAddress::CITY_CONST,
      state: BillingAddress::STATE_CONST,
      postal: BillingAddress::POSTAL_CONST,
      phone_number: BillingAddress::PHONE_NUMBER_CONST
    }
  end

  case payment_method
  when 'Credit Card'
    scenario '5. Check out with Credit Card' do
      if device_store == 'LFC'
        AtgCheckOutPaymentPage.new.add_credit_card(credit_card, billing_address)
      else
        # Add new Credit Card
        atg_dv_payment_page.dv_add_credit_card(credit_card, billing_address)

        # Select the added Credit Card
        atg_dv_payment_page.dv_select_credit_card
      end

      pending "***5. Check out with Credit Card (Credit Card: #{credit_card[:card_number]})"
    end
  when 'Account Balance'
    scenario '5. Check out with Redeem Code' do
      code_type = atg_dv_payment_page.dv_code_type_by_locale
      pin = atg_dv_payment_page.dv_redeem_code(env, code_type, device_store, 12) # repeat maximum 12 times for FRV1: $5 * 12 = 60$
      pending "***5. Check out with Redeem Code (PIN: #{pin})"
    end
  else # Credit Card + Account Balance
    scenario '5. Check out with Credit Card + Account Balance' do
      # Redeem Code
      code_type = atg_dv_payment_page.dv_code_type_by_locale
      pin = atg_dv_payment_page.dv_redeem_code(env, code_type, device_store)

      # Add new Credit Card
      if device_store == 'LFC'
        AtgCheckOutPaymentPage.new.add_credit_card(credit_card, billing_address)
      else
        atg_dv_payment_page.dv_add_credit_card(credit_card, billing_address)
        atg_dv_payment_page.dv_select_credit_card unless review_page.has_btn_device_place_order?(wait: 10)
      end

      pending "***5. Check out with Credit Card + Account Balance (Credit Card: #{credit_card[:card_number]} - PIN: #{pin})"
    end
  end
end

# @platform is leappad, leappad2, leappad3, emerald, explorer2, leapreader, android1, leapup or leappadplatinum
def create_account_and_claim_devices_via_webservice(caller_id, first_name, last_name, email, password, location, platform = nil)
  cus_id = nil
  scenario "1. Register new account (Email:#{email})" do
    customer = CustomerManagement.register_customer(caller_id, first_name, last_name, email, email, password, location)

    3.times do
      if customer.class == Nokogiri::XML::Document
        break
      else
        `ipconfig /flushdns` unless RbConfig::CONFIG['host_os'].include? 'darwin'
        customer = CustomerManagement.register_customer(caller_id, first_name, last_name, email, email, password, location)
      end
    end

    search_res = CustomerManagement.search_for_customer(caller_id, email)
    cus_id = search_res.xpath('//customer/@id').text
    fail 'Failed registering new account even we tried in 3 times. Please check you network!' if cus_id.blank?
    expect(cus_id).not_to be_nil
  end

  scenario "2. Link account to #{platform ? platform : 'all'} device(s)" do
    if platform
      device_platforms = { "#{platform}" => platform }
    else
      device_platforms = {
        LeapPad: 'leappad',
        Val: 'leappad2',
        Cabo: 'leappad3',
        LeapterExplore: 'emerald',
        LeapterGS: 'explorer2',
        LeapReader: 'leapreader',
        Narnia: 'android1',
        Glasgow: 'leapup',
        Bogota: 'leappadplatinum'
      }
    end

    session_res = AuthenticationService.acquire_service_session(caller_id, email, password)
    session = session_res.xpath('//session').text

    register_child_res = ChildManagementService.register_child(caller_id, session, cus_id)
    child_id = register_child_res.xpath('//child/@id').text

    claim_all_devices(caller_id, session, cus_id, child_id, device_platforms)
  end
end

def device_locale_payment_method_compatible?(device_store, payment_method, locale)
  compatible_checkout_list = [
    ['LFC', 'Credit Card', 'US, CA, UK, AU, FR_FR, FR_CA'],
    ['LFC', 'Account Balance', 'ALL'],
    ['LFC', 'CC + Balance', 'US, CA, UK, AU, FR_FR, FR_CA'],
    ['LeapPad 3', 'Credit Card', 'US, CA, UK, AU, FR_FR, FR_CA'],
    ['LeapPad 3', 'Account Balance', 'ALL'],
    ['LeapPad 3', 'CC + Balance', 'US, CA, UK, AU, FR_FR, FR_CA'],
    ['LeapPad Ultra', 'Credit Card', 'US, CA, UK, AU'],
    ['LeapPad Ultra', 'Account Balance', 'US, CA, UK, IE, AU, ROW'],
    ['LeapPad Ultra', 'CC + Balance', 'US, CA, UK, AU'],
    ['LeapPad Platinum', 'Credit Card', 'US, CA, UK, AU'],
    ['LeapPad Platinum', 'Account Balance', 'US, CA, UK, IE, AU, ROW'],
    ['LeapPad Platinum', 'CC + Balance', 'US, CA, UK, AU'],
    ['Narnia', 'Credit Card', 'US, CA, UK, AU'],
    ['Narnia', 'Account Balance', 'US, CA, UK, IE, AU, ROW'],
    ['Narnia', 'CC + Balance', 'US, CA, UK, AU'],
    ['iPhone 6', 'Credit Card', 'US, CA, UK, AU'],
    ['iPhone 6', 'Account Balance', 'US, CA, UK, IE, AU, ROW'],
    ['iPhone 6', 'CC + Balance', 'US, CA, UK, AU'],
    ['Galaxy S4', 'Credit Card', 'US, CA, UK, AU'],
    ['Galaxy S4', 'Account Balance', 'US, CA, UK, IE, AU, ROW'],
    ['Galaxy S4', 'CC + Balance', 'US, CA, UK, AU'],
  ]

  temp = compatible_checkout_list.find{|x| x[0] == device_store && x[1] == payment_method }
  return true if temp && (temp[2] == 'ALL' || temp[2].include?(locale))

  skip "SKIP: Unsupported (Device = '#{device_store}' - Payment method = '#{payment_method}' - Locale = '#{locale}')"
  false
end
