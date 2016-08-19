require 'pages/atg_dv/atg_dv_common_page'
require 'pages/atg_dv/atg_dv_check_out_review_page'

class DeviceCreditCardSection < SitePrism::Section
  element :txt_device_card_name, '#accountHolderName'
  element :txt_device_card_number, '#creditCardNumber'
  element :txt_device_security_code, '#creditCardCvn'
end

class DeviceBillingAddressSection < SitePrism::Section
  element :txt_device_street, '#billingAddress1'
  element :txt_device_city, '#billingAddressCity'
  element :txt_device_zip_code, '#billingAddressPostalCode'
  element :txt_device_phone_number, '#billingAddressPhone'
end

class DeviceRedeemCodeSection < SitePrism::Section
  element :txt_device_input1, :xpath, ".//input[@name='uiRedeemCode1']"
  element :txt_device_input2, :xpath, ".//input[@name='uiRedeemCode2']"
  element :txt_device_input3, :xpath, ".//input[@name='uiRedeemCode3']"
  element :txt_device_input4, :xpath, ".//input[@name='uiRedeemCode4']"
end

class LFCRedeemCodeSection < SitePrism::Section
  element :txt_lfc_input1, :xpath, ".//input[@name='uiRedeemCode1']"
  element :txt_lfc_input2, :xpath, ".//input[@name='uiRedeemCode2']"
  element :txt_lfc_input3, :xpath, ".//input[@name='uiRedeemCode3']"
  element :txt_lfc_input4, :xpath, ".//input[@name='uiRedeemCode4']"
  element :btn_lfc_state, '.chzn-single.chzn-default'
  element :btn_lfc_redeem, :xpath, ".//div[@class='redeemForm1']//button[contains(text(),'Redeem') or contains(text(),'Utiliser')]"
end

class DeviceCodeAcceptedSection < SitePrism::Section
  element :btn_device_continue, :xpath, ".//a[text()='Continue' or text()='Continuer']"
end

class LFCCodeAcceptedSection < SitePrism::Section
  element :btn_lfc_continue, :xpath, ".//a[contains(text(),'Continue') or contains(text(),'Continuer')]"
end

class AtgDvCheckOutPaymentPage < AtgDvCommonPage
  section :dv_credit_card_section, DeviceCreditCardSection, '.row.form-narrow.hcenter'
  section :dv_billing_address_section, DeviceBillingAddressSection, '.row.form-narrow.hcenter'
  section :dv_redeem_code_section, DeviceRedeemCodeSection, '.redeemForm1'
  section :dv_code_accepted_section, DeviceCodeAcceptedSection, '.section-fluid'
  section :lfc_redeem_code_section, LFCRedeemCodeSection, '#paymentForm'
  section :lfc_code_accepted_section, LFCCodeAcceptedSection, '#valueCodeSuccessMessage'

  element :btn_device_use_this_credit_card, :xpath, ".//button[text()='Use this Credit Card' or text()='Utiliser cette carte de crédit']"
  element :btn_lfc_redeem_now, :xpath, ".//div[@ng-hide='showRedeemForm']/button[contains(text(),'Redeem') or contains(text(),'Utiliser')]"

  # .trigger('tap'): use for Lpad3, Leappad Platinum
  # .click(): use for LeapPad Ultra, Narnia
  def click_control(css_element)
    page.execute_script("$('#{css_element}').trigger('tap');")
    page.execute_script("$('#{css_element}').click();")
    sleep(1)
  end

  def dv_enter_credit_card(credit_card)
    dv_credit_card_section.txt_device_card_name.set credit_card[:card_name]
    dv_credit_card_section.txt_device_card_number.set credit_card[:card_number]

    click_control('.cc-exp-month button')
    find(:xpath, ".//*[@class='mobile-dropdown__list']/li[text()='#{credit_card[:exp_month]}']").click

    click_control('.cc-exp-year button')
    find(:xpath, ".//*[@class='mobile-dropdown__list']/li[text()='#{credit_card[:exp_year]}']").click

    dv_credit_card_section.txt_device_security_code.set credit_card[:security_code]
  end

  def drag_to_control(from_control, to_control)
    begin
      source = find(:css, from_control)
      target = find(:css, to_control)
      source.drag_to target
    rescue => ex
      ex.message
    end
  end

  def dv_enter_billing_address(billing_address)
    # Work-around issue: Fail to click element that is hidden by screen
    drag_to_control('#billingAddress1', '#creditCardNumber')

    dv_billing_address_section.txt_device_street.set billing_address[:street]
    dv_billing_address_section.txt_device_city.set billing_address[:city]

    if page.has_css?('.cc-us-state button', wait: TimeOut::WAIT_SMALL_CONST)
      click_control('.cc-us-state button')
      find(:xpath, ".//*[@class='mobile-dropdown__list']/li[2]").click
    end

    dv_billing_address_section.txt_device_zip_code.set billing_address[:postal]
    dv_billing_address_section.txt_device_phone_number.set billing_address[:phone_number]
  end

  def dv_add_credit_card(credit_card, billing_address)
    # Click on Add new Credit Card button
    click_control('.btn.btn-primary')

    dv_enter_credit_card credit_card
    dv_enter_billing_address billing_address

    # Click on Continue button
    find(:xpath, ".//button[text()='Continue' or text()='Continuer']").click
    has_btn_device_use_this_credit_card?(wait: TimeOut::WAIT_CONTROL_CONST)
  end

  def dv_select_credit_card
    click_control('.small-label>input')
    click_control('button.btn.btn-primary')
    AtgDvCheckOutReviewPage.new
  end

  def dv_code_type_by_locale
    case
    when current_url.include?('fr-fr')
      'FRV1'
    when current_url.include?('fr-of') || current_url.include?('en-oe')
      'OTHR'
    when current_url.include?('en-au')
      'AUV1'
    when current_url.include?('en-ie')
      'IRV1'
    when current_url.include?('en-gb')
      'UKV1'
    when current_url.include?('en-ca') || current_url.include?('fr-ca')
      'CAV1'
    else
      'USV1'
    end
  end

  def dv_redeem_code(env, code_type, device_store, repeat_time = 1)
    review_page = AtgDvCheckOutReviewPage.new

    repeat_time.times do
      pin = PinRedemption.get_pin_info(env, code_type, 'Available')
      return 'Please upload the PIN to redeem' if pin.blank?

      # Update PIN status to Used
      pin_number = pin['pin_number']
      PinRedemption.update_pin_status(env, code_type, pin_number, 'Used')

      if device_store.include? 'LFC'
        btn_lfc_redeem_now.click

        # Enter PIN values
        lfc_redeem_code_section.txt_lfc_input1.set pin_number[0..3]
        lfc_redeem_code_section.txt_lfc_input2.set pin_number[5..8]
        lfc_redeem_code_section.txt_lfc_input3.set pin_number[10..13]
        lfc_redeem_code_section.txt_lfc_input4.set pin_number[15..18]

        # Select State
        if page.has_css?('.chzn-single.chzn-default', wait: TimeOut::WAIT_SMALL_CONST)
          lfc_redeem_code_section.btn_lfc_state.click
          find(:xpath, "(.//ul[@class='chzn-results']/li)[1]").click
        end

        # Click on Redeem button
        lfc_redeem_code_section.btn_lfc_redeem.click
        sleep TimeOut::WAIT_MID_CONST

        return "The PIN: #{pin_number} has been redeemed or invalid" unless lfc_code_accepted_section.has_btn_lfc_continue?(wait: TimeOut::WAIT_BIG_CONST)

        # Click on Continue button on Code Accepted page
        lfc_code_accepted_section.btn_lfc_continue.click

        return pin_number if review_page.has_btn_lfc_place_order?(wait: TimeOut::WAIT_MID_CONST * 2) || repeat_time == 1
      else
        # Click on Redeem Now button
        click_control('.btn.btn-default.btn-sm.pull-right')

        # Enter PIN values
        dv_redeem_code_section.txt_device_input1.set pin_number[0..3]
        dv_redeem_code_section.txt_device_input2.set pin_number[5..8]
        dv_redeem_code_section.txt_device_input3.set pin_number[10..13]
        dv_redeem_code_section.txt_device_input4.set pin_number[15..18]

        # Select State
        if page.has_css?('.mobile-dropdown__button', wait: TimeOut::WAIT_SMALL_CONST)
          click_control('.mobile-dropdown__button')
          find(:xpath, "(.//*[@class='mobile-dropdown__list']/li)[1]").click
        end

        # Click on Redeem button
        click_control('.btn.btn-primary.pull-right.redeem__btn-submit')
        sleep TimeOut::WAIT_MID_CONST

        return "The PIN: #{pin_number} has been redeemed or invalid" unless dv_code_accepted_section.has_btn_device_continue?(wait: TimeOut::WAIT_BIG_CONST)

        # Click on Continue button on Code Accepted page
        dv_code_accepted_section.btn_device_continue.click

        return pin_number if review_page.has_btn_device_place_order?(wait: TimeOut::WAIT_MID_CONST * 2) || repeat_time == 1
      end
    end

    'Error while redeem code. Please re-check!'
  end
end
