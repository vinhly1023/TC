require 'pages/atg_dv/atg_dv_common_page'
require 'pages/atg_dv/atg_dv_check_out_confirmation_page'

class AtgDvCheckOutReviewPage < AtgDvCommonPage
  element :btn_device_place_order, :xpath, "(.//button[text()='Place Order' or text()='Commander'])[1]"
  element :btn_lfc_place_order, '#commitOrderSubmitButton'
  element :lbl_lfc_account_balance, :xpath, "//*[@id='orderSummary']//div[@class='price-type text-success']/div[@class='cartRight']"
  element :lbl_lfc_sub_total, '.cartRight>strong'
  element :lbl_lfc_tax, :xpath, ".//div[contains(text(), 'Sales Tax') or contains(text(), 'Taxe de vente')]/../div[@class='cartRight']"
  element :lbl_lfc_order_total, :xpath, ".//h2[contains(text(), 'Order Total') or contains(text(), 'Total')]"

  def play_order_displayed?(device_store)
    return has_btn_lfc_place_order?(wait: TimeOut::WAIT_BIG_CONST / 2) if device_store.include? 'LFC'
    has_btn_device_place_order?(wait: TimeOut::WAIT_BIG_CONST / 2)
  end

  def dv_place_order(device_store)
    if device_store.include? 'LFC'
      btn_lfc_place_order.click
    else
      btn_device_place_order.click
    end

    sleep TimeOut::WAIT_MID_CONST * 2
    AtgDvCheckOutConfirmationPage.new
  end

  def dv_order_review_info(device_store)
    if device_store.include? 'LFC'
      sub_total = lbl_lfc_sub_total.text
      tax = has_lbl_lfc_tax?(TimeOut::WAIT_SMALL_CONST) ? lbl_lfc_tax.text : ''
      account_balance = has_lbl_lfc_account_balance?(TimeOut::WAIT_SMALL_CONST) ? lbl_lfc_account_balance.text : ''
      order_total = lbl_lfc_order_total.text.gsub('Order Total:', '').gsub('Total :', '').strip
    else
      sub_total = page.evaluate_script("$('#orderSubtotal').text();").delete("\n")
      tax = page.evaluate_script("$('#orderTax').text();").delete("\n")
      account_balance = page.evaluate_script("$('.orderAccountBalanceApplied .col-xs-4.col-sm-2.text-right').text();").delete("\n").gsub('-', '– ')
      order_total = page.evaluate_script("$('.col-xs-4.col-sm-2.text-right .orderTotalCart').text();").delete("\n")
    end

    {
      sub_total: sub_total,
      tax: tax,
      account_balance: account_balance,
      order_total: order_total
    }
  end
end
