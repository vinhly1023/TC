require 'pages/atg/atg_common_page'
require 'pages/atg/atg_checkout_review_page'

class ExpCreditCardOopsPopup < SitePrism::Section
  element :oops_text, '#expiredCC>p'
  element :close_btn, '.close'
end

class AddCreditCardForm < SitePrism::Section
  # Credit Card
  element :card_number_input, '#vin_PaymentMethod_creditCard_account'
  element :name_on_card_input, '#vin_PaymentMethod_accountHolderName'
  element :expiration_month_opt, '#vin_PaymentMethod_creditCard_expirationDate_Month'
  element :expiration_year_opt, '#vin_PaymentMethod_creditCard_expirationDate_Year'
  element :security_code_input, '#vin_PaymentMethod_nameValues_cvn'
  element :use_shipping_address_chk, :xpath, "//*[@id='creditCardAddForm']//label[@for='useShippingAddress']"
  element :shipping_checked_chk, :xpath, "//*[@id='creditCardAddForm']//label[@for='useShippingAddress' and @class='checked']"
  element :use_shipping_address_as_billing_address, '#checkoutUseSavedShippedAddressCheckbox'
  element :use_shipping_address_acc_chk, :xpath, ".//*[@id='checkoutUseSavedShippedAddressCheckbox']"
  element :invalid_exp_date_msg, '#creditCardForm #ccDate'

  # Billing address
  element :bl_street_addr_input, :xpath, "(.//*[@id='vin_PaymentMethod_billingAddress_addr1'])[1]"
  element :bl_city_input, '#vin_PaymentMethod_billingAddress_city'
  element :bl_state_opt, '#stateSelect'
  element :bl_zip_code_input, '#vin_PaymentMethod_billingAddress_postalCode'
  element :bl_phone_input, '#vin_PaymentMethod_billingAddress_phone'
  element :continue_btn, '#billingContinue'
end

class RedeemCode < SitePrism::Section
  element :ui_redeem_input1, "input[name = 'uiRedeemCode1']"
  element :ui_redeem_input2, "input[name = 'uiRedeemCode2']"
  element :ui_redeem_input3, "input[name = 'uiRedeemCode3']"
  element :ui_redeem_input4, "input[name = 'uiRedeemCode4']"
  element :state_cbo, '.redeemForm1 .row.raised select'
  element :redeem_btn, :xpath, ".//*[@class='redeemForm1']//button[contains(text(),'Redeem')]"
  element :pin_redeemed_msg, :xpath, ".//div[contains(text(),'Sorry, this code has already been redeemed')]"
end

class RedeemSuccess < SitePrism::Section
  element :close_btn, '.btn.btn-yellow.pull-right'
end

class AtgCheckOutPaymentPage < AtgCommonPage
  set_url_matcher(%r{.*\/checkout\/payment.jsp})

  section :exp_credit_card_popup, ExpCreditCardOopsPopup, '#expiredCC'
  section :add_credit_card_form, AddCreditCardForm, '#paymentBilling'
  section :redeem_code_section, RedeemCode, '.redeemForms'
  section :redeem_success_section, RedeemSuccess, '#valueCodeSuccessMessage'

  element :redeem_btn, :xpath, "(.//div[@id='paymentForm']//button[contains(text(),'Redeem')])[1]"
  element :continue_btn, :xpath, "//*[@id='paymentBilling']//input[@value='Continue' and @data-target='#savedCreditCardButton']"
  element :exp_credit_card_oops_popup, '#expiredCC'
  element :account_balance, '.price-type .cartRight'
  element :cart_total, '.side-price-type .cartRight'
  element :paypal_btn, '#payPalLink>img'

  def payment_page_exist?
    displayed?
  end

  def paypal_button_exist?
    has_paypal_btn?(wait: TimeOut::WAIT_MID_CONST)
  end

  def click_continue_button
    continue_btn.click if has_continue_btn?(wait: TimeOut::WAIT_MID_CONST)
  end

  # Fill billing address on payment tab
  def fill_billing_address(billing_address)
    add_credit_card_form.bl_street_addr_input.set billing_address[:street]
    add_credit_card_form.bl_city_input.set billing_address[:city]

    # display state option
    if page.has_css?('.stateSelect', wait: TimeOut::WAIT_SMALL_CONST)
      page.execute_script("$('#stateSelect').css('display','block')")
      add_credit_card_form.bl_state_opt.find("option[value='#{billing_address[:state]}']").select_option
    end

    add_credit_card_form.bl_zip_code_input.set billing_address[:postal]
    add_credit_card_form.bl_phone_input.set billing_address[:phone_number]
  end

  #
  # Add credit card on payment tab
  # Return review tab
  #
  def add_credit_card(credit_card, billing_address = nil)
    add_credit_card_form.card_number_input.set credit_card[:card_number]
    add_credit_card_form.name_on_card_input.set credit_card[:card_name]

    # display expiration month option
    page.execute_script("$('#vin_PaymentMethod_creditCard_expirationDate_Month').css('display','block')")
    add_credit_card_form.expiration_month_opt.select credit_card[:exp_month]

    # display expiration year option
    page.execute_script("$('#vin_PaymentMethod_creditCard_expirationDate_Year').css('display','block')")
    add_credit_card_form.expiration_year_opt.select credit_card[:exp_year]

    add_credit_card_form.security_code_input.set credit_card[:security_code]

    if billing_address.nil?
      if add_credit_card_form.has_shipping_checked_chk?
        add_credit_card_form.use_shipping_address_chk.click
      else
        add_credit_card_form.use_shipping_address_as_billing_address.click
      end
    else
      fill_billing_address(billing_address)
    end

    # submit info
    add_credit_card_form.continue_btn.click

    AtgCheckOutReviewPage.new
  end

  def redeem_code(env, locale, repeat = 5)
    review_page = AtgCheckOutReviewPage.new
    pin_env = env == 'PROD' ? 'PROD' : 'QA'
    pin_type = Title.locale_to_code_type locale
    state = Title.locale_to_state locale
    used_pins = []

    repeat.times do
      # Get available PIN
      pin = PinRedemption.get_pin_info(pin_env, pin_type, 'Available')

      next if pin.blank?
      pin_number = pin['pin_number']

      # Click on Redeem button on Payment page
      redeem_btn.click if has_redeem_btn?(wait: TimeOut::WAIT_MID_CONST)

      # Enter PINs number
      redeem_code_section.ui_redeem_input1.set pin_number[0..3]
      redeem_code_section.ui_redeem_input2.set pin_number[5..8]
      redeem_code_section.ui_redeem_input3.set pin_number[10..13]
      redeem_code_section.ui_redeem_input4.set pin_number[15..18]

      # Select state
      unless state.blank?
        page.execute_script("$('.redeemForm1 .row.raised select').css('display','block')")
        redeem_code_section.state_cbo.select state
      end

      # Click on Redeem button
      redeem_code_section.redeem_btn.click

      # Update PIN status
      PinRedemption.update_pin_status(pin_env, pin_type, pin_number, 'Used')

      next if redeem_code_section.has_pin_redeemed_msg?(wait: TimeOut::WAIT_MID_CONST)

      if redeem_success_section.has_close_btn?(wait: TimeOut::WAIT_BIG_CONST)
        redeem_success_section.close_btn.click
        used_pins.push pin_number
      end

      return used_pins if review_page.has_place_order_btn?(wait: TimeOut::WAIT_MID_CONST * 2)
    end

    used_pins
  rescue
    []
  end

  def invalid_exp_date_text
    add_credit_card_form.invalid_exp_date_msg.text
  end

  def exp_credit_card_oops_popup_displays?
    has_exp_credit_card_oops_popup?(wait: TimeOut::WAIT_CONTROL_CONST)
  end

  def exp_credit_card_oops_text
    exp_credit_card_popup.oops_text.text
  end

  def close_exp_credit_card_oops_popup
    exp_credit_card_popup.close_btn.click
  end
end
