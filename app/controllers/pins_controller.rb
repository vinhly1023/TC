class PinsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def redeem_pin
    return flash.clear unless params[:commit]

    env = params[:env]
    return flash.now[:error] = 'You don\'t have permission to do this action.' if env != 'QA' && session[:user_role] == 3

    type = params[:type_pin]
    customer_management = CustomerManagement.new(env)
    pin_management = PINManagement.new(env)

    # LOOKUP_CUSTOMER_BY_USERNAME:
    customer_id = customer_management.get_customer_id(params[:email])

    if customer_id[0] == 'error' || customer_id.blank?
      flash.clear
      flash.now[:error] = 'The email address is incorrect. Please try again.'
      return render 'redeem_pin'
    end

    # FETCH_CUSTOMER: display customer information after redemption
    doc = customer_management.fetch_customer(customer_id)
    customer = Hash.from_xml(doc.at_xpath('//customer').to_s)
    @customerid = customer['customer']['id']
    @email = customer['customer']['email']
    @cust_type = customer['customer']['type']
    @lf_alias = customer['customer']['first_name'] + ' ' + customer['customer']['last_name']
    @locale = customer['customer']['locale']

    # REDEEM PINS
    @pin_arr = []
    status = nil
    pin_input_arr = params[:lf_pin].strip.split("\n").reject(&:empty?)

    pin_input_arr.each do |p|
      params_info = { env: params[:env], type_pin: params[:type_pin], pin: p, email: params[:email], locale: params[:locale] }
      rd = PublicActivity::Activity.new(key: 'pin.redeem', owner: User.current_user, parameters: params_info)
      rd.save

      pin = p.gsub(/-|\r/, '')

      # fetch pin attributes to PIN locale + status
      pin_info = pin_management.get_pin_information pin

      # Move to next if has_error
      if pin_info[:has_error] == 'error'
        @pin_arr.push(pin: p, status: pin_info[:message])
        next
      end

      # Get PIN locale
      locale = pin_info[:locale]

      # If PIN locale does not match with selected locale
      unless locale.split(';').include?(params[:locale])
        @pin_arr.push(pin: p, status: "Invalid locale: (#{locale})")
        next
      end

      locale = params[:locale]

      # If PIN is not available
      unless pin_info[:status] == 'AVAILABLE'
        @pin_arr.push(pin: p, status: pin_info[:status])
        next
      end

      amount = pin_info[:amount] + ' ' + pin_info[:currency]
      pin_type = pin_info[:type]

      case type
      when 'redeemGiftPackages'
        status = pin_management.redeem_gift_packages(customer_id, pin, locale)
      when 'redeemGiftValue'
        status = pin_management.redeem_gift_value(customer_id, pin, locale)
      when 'redeemValueCard'
        status = pin_management.redeem_value_card(customer_id, pin, locale)
      end

      # Check PIN redemption's status and push into array
      if status[0] == 'error'
        @pin_arr.push(pin: p, status: status[1])
      else
        @pin_arr.push(pin: p, status: "Success - #{amount} - #{pin_type}")
      end
    end

    flash.clear
    render 'show'
  rescue => e
    flash.now[:error] = "Error: #{e.message}"
    render 'redeem_pin'
  end

  def pin_status
    return flash.clear unless params[:commit]

    begin
      response_text = '<p class="alert alert-error">Please enter pins to check</p>'
      env = params[:env]
      pins = params[:lf_pin]
      pin_management = PINManagement.new env
      return render plain: response_text if pins.to_s.length <= 0
      arr_pin = pins.delete("\r").split("\n")
      return render plain: response_text if arr_pin.count < 0
      response_text = ''
      response_hash = {}

      Parallel.each(arr_pin, in_threads: 10) do |pin|
        pin_san = pin.to_s.strip.delete('-')
        next if pin_san.blank?
        status = pin_management.get_pin_status pin_san
        response_hash["#{pin}"] = "#{status}"
      end

      arr_pin.each do |pin|
        status = response_hash["#{pin}"]
        response_text << "<p>#{pin} = <span class=\"#{status.to_s.downcase}\">#{status}</span></p>"
      end

      render plain: response_text
    rescue => e
      render plain: e.message
    end
  end
end
