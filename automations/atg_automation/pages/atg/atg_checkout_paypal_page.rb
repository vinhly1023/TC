require 'pages/atg/atg_common_page'

class LoginPayPal < SitePrism::Section
  element :email_txt, '#login_email'
  element :password_txt, '#login_password'
  element :login_btn, '#submitLogin'
end

class AtgCheckOutPaypalPage < SitePrism::Page
  section :login_form, LoginPayPal, '#loginBox'

  element :pay_now_btn, '#continue'
  element :account_info, '.inset.confidential'

  def login_paypal_account(email, password)
    return false unless has_css?('#loginBox', wait: TimeOut::WAIT_BIG_CONST)

    # Enter PayPal Email
    login_form.email_txt.set email

    # Enter Password
    login_form.password_txt.set password

    # Click on Login button
    login_form.login_btn.click

    return account_info if has_pay_now_btn?(wait: TimeOut::WAIT_BIG_CONST)

    false
  end

  # Click on 'Pay Now' button on 'Review your information' page
  def pay_app
    pay_now_btn.click
  end
end
