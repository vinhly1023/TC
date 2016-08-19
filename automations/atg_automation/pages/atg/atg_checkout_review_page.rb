require 'pages/atg/atg_common_page'
require 'pages/atg/atg_checkout_confirmation_page'

class AtgCheckOutReviewPage < AtgCommonPage
  set_url_matcher(%r{.*\/checkout\/review})

  element :place_order_btn, :xpath, "//*[@id='commitOrder']/input[@type='submit']"
  element :error_message, :xpath, "//*[@id='errorMessage']/div/div"
  element :sale_tax_txt, :xpath, ".//div[contains(text(), 'Sales Tax')]/../div[@class='cartRight']"
  element :account_balance_txt, :xpath, "//*[@id='orderSummary']//div[@class='price-type text-success']/div[@class='cartRight']"

  def review_page_exist?(wait_time = TimeOut::WAIT_BIG_CONST)
    displayed?(wait_time)
  end

  def place_order
    wait_for_place_order_btn
    place_order_btn.click

    return error_message.text if has_error_message?(wait: TimeOut::WAIT_MID_CONST)
    AtgCheckOutConfirmationPage.new
  end

  def sale_tax
    wait_for_ajax
    has_sale_tax_txt?(wait: TimeOut::WAIT_SMALL_CONST) ? '%.2f' % sale_tax_txt.text.gsub(/[^\d,\.]/, '').to_f : 0.0
  end

  def account_balance
    has_account_balance_txt? ? account_balance_txt.text.gsub(/[^\d,\.]/, '') : ''
  end
end
