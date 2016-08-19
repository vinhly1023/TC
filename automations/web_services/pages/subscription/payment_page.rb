require 'pages/subscription/common_page'

class BillingInfo < SitePrism::Section
  element :card_number_input, 'input[name="number"]'
  element :name_on_card_input, 'input[name="name"]'
  element :expiration_month_opt, 'select[name="ccExpMonth"]'
  element :expiration_year_opt, 'select[name="ccExpYear"]'
  element :security_code_input, 'input[name="cvc"]'
end

class BillingAddress < SitePrism::Section
  element :street_addr_input, 'input[name="address1"]'
  element :city_input, 'input[name="city"]'
  element :state_opt, 'select[name="state"]'
  element :zip_code_input, 'input[name="postalCode"]'
  element :phone_input, 'input[name="phone-number"]'
end

class PaymentPage < CommonPage
  set_url_matcher(%r{.*\/subscription\/payment.jsp})

  section :billing_info, BillingInfo, '.billing-info'
  section :billing_address, BillingAddress, '.billing-address'
  element :start_your_free_trial_btn, '.button.button_primary'

  def payment_page_exist?
    displayed?
  end

  def fill_billing_info(info)
    billing_info.card_number_input.set info[:card_number]
    billing_info.name_on_card_input.set info[:name_on_card]

    # display expiration month option
    page.execute_script("$('select[name=\"ccExpMonth\"]').css('display','block')")
    billing_info.expiration_month_opt.select info[:exp_month]

    # display expiration year option
    page.execute_script("$('select[name=\"ccExpYear\"]').css('display','block')")
    billing_info.expiration_year_opt.select info[:exp_year]

    billing_info.security_code_input.set info[:security_code]
  end

  def fill_address_info(info)
    billing_address.street_addr_input.set info[:address]
    billing_address.city_input.set info[:city]

    # display state option
    page.execute_script("$('select[name=\"state\"]').css('display','block')")
    billing_address.state_opt.find("option[label='#{info[:state]}']").select_option

    billing_address.state_opt.set info[:state]
    billing_address.zip_code_input.set info[:zip_code]
    billing_address.phone_input.set info[:phone]
  end

  def start_free_trial
    page.execute_script("$('.form__field.payment-tos-agreement>input').trigger('click')")
    start_your_free_trial_btn.click
  end
end
