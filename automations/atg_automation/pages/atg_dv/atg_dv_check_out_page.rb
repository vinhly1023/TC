require 'pages/atg_dv/atg_dv_common_page'
require 'pages/atg_dv/atg_dv_check_out_payment_page'

class AtgDvCheckOutPage < AtgDvCommonPage
  element :txt_lfc_login_email, '#accountEmail'
  element :txt_lfc_login_password, '#accountPassword'
  element :btn_lfc_checkout_user_login, '#checkoutUserLogin'
  element :btn_lfc_check_out, :xpath, ".//form[@id='moveToPurchase']/button[text()='Check Out' or text()='Commander']"
  element :btn_lfc_buy_hang_on, :xpath, ".//a[contains(text(),'Buy') or contains(text(),'Acheter')]"

  element :txt_atg_login_email, '#atg_loginEmail'
  element :txt_atg_login_password, '#atg_loginPassword'
  element :btn_atg_login, :xpath, ".//button[text()='Log In' or text()='Connexion']"

  element :btn_device_continue, :xpath, ".//button[text()='Continue' or text()='Connexion' or text()='Continuer']"
  element :txt_device_login_password, '#atg_loginPassword'
  element :btn_device_check_out, :xpath, ".//form[@id='moveToPurchase']/button[text()='Check Out' or text()='Commander']"

  def dv_go_to_payment_page(email, password, device_store)
    if device_store.include? 'LFC'
      # Login 1st time
      dv_checkout_user_login email, password

      # Click on Checkout button
      btn_lfc_check_out.click

      # Click on hang on button
      btn_lfc_buy_hang_on.click if has_btn_lfc_buy_hang_on?(wait: TimeOut::WAIT_MID_CONST)

      # Login 2nd time to ATG
      dv_login_atg email, password
    elsif device_store.include?('iPhone 6') || device_store.include?('Galaxy S4')
      # Click on Checkout button
      btn_device_check_out.click

      # Login 1st time
      dv_login_atg email, password

      # Click on Checkout button
      btn_device_check_out.click if has_btn_device_check_out? wait: TimeOut::WAIT_MID_CONST

      # Login 2nd time to ATG
      dv_login_atg email, password
    else
      # Click on Checkout button
      btn_device_check_out.click

      # Enter password
      txt_device_login_password.set password

      # Click on Continue button
      btn_device_continue.click
    end

    sleep TimeOut::WAIT_MID_CONST
    AtgDvCheckOutPaymentPage.new
  end

  def dv_checkout_user_login(email, password)
    txt_lfc_login_email.set email
    txt_lfc_login_password.set password
    btn_lfc_checkout_user_login.click
    sleep TimeOut::WAIT_MID_CONST
  end

  def dv_login_atg(email, password)
    txt_atg_login_email.set email
    txt_atg_login_password.set password
    btn_atg_login.click
    sleep TimeOut::WAIT_MID_CONST
  end
end
