require 'pages/atg/atg_common_page'

class AtgCheckOutConfirmationPage < AtgCommonPage
  element :order_complete_txt, '.row.raised.gold-border.text-center'
  element :order_details_txt, '#orderDetails'
  element :order_summary_txt, '#orderSummary'
  element :order_confirmation_number_txt, :xpath, "//*[contains(text(),'Your order confirmation number is')]"
  element :order_total_cost_txt, :xpath, "//*[@id='orderDetails']//*[contains(text(),'Order Total')]"
  element :account_balance_txt, '.price-type-bigger.text-success .cartRight'
  elements :cart_right_txt, '.price-type-bigger .cartRight'
  element :sale_tax_txt, :xpath, ".//div[contains(text(), 'Sales Tax')]/../div[@class='cartRight']"
  element :order_subtotal, '.price-type-bigger.orderSubTotalCart .cartRight'

  def record_order_id(email, order_id)
    # Update Order ID to tracking table
    query = "select * from atg_tracking where email = '#{email}'"
    rs_select_email = Connection.my_sql_connection query

    if rs_select_email.count == 0
      query = "insert into atg_tracking(firstname, lastname, email, country, order_id, created_at, updated_at) values ('#{General::FIRST_NAME_CONST}', '#{General::LAST_NAME_CONST}', '#{email}', '#{General::COUNTRY_CONST}', '#{order_id}', \'#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}\', \'#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}\')"
    else
      rs_select_order_id = Connection.my_sql_connection "select order_id from atg_tracking where email = '#{email}'"
      temp = ''
      rs_select_order_id.each do |row|
        if row['order_id'].nil?
          temp = order_id
        else
          temp = row['order_id'] + ', ' + order_id
        end

        break
      end

      query = "update atg_tracking set order_id = '#{temp}', updated_at = \'#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}\' where email = '#{email}'"
    end

    Connection.my_sql_connection query
  end

  def order_number
    order_number_message = order_confirmation_number_txt.text

    if General::ENV_CONST == 'PROD' # production
      idx = order_number_message.index('lfop')
    else
      idx = order_number_message.index('lfou')
    end

    return order_number_message[idx..-1].delete('.').strip if idx

    "Cannot get Order Id, please recheck. Actual message: #{order_number_message}"
  end

  def order_overview_info
    summary = has_order_summary_txt? ? order_summary_txt.text : ''
    order_id = order_number

    { complete: order_complete_txt.text,
      details: RspecEncode.encode_description(order_details_txt.text),
      summary: summary,
      order_id: order_id }
  end

  def calculate_order_total
    total = 0.00
    cart_right_txt.each do |crv|
      total += crv.text.gsub(/[^\d,\.]/, '').tr('(', '-').tr(')', '').gsub(/\s+/, '').tr('–', '-').to_f
    end

    '%.2f' % total.round(2)
  end

  def cal_total_price(price)
    '%.2f' % price.gsub(/[^\d,\.]/, '')
  end

  def account_balance
    has_account_balance_txt?(wait: TimeOut::WAIT_SMALL_CONST) ? account_balance_txt.text.strip.delete('()') : ''
  end

  def order_total
    order_total_cost_txt.text
  end

  def sale_tax
    has_sale_tax_txt?(wait: TimeOut::WAIT_SMALL_CONST) ? sale_tax_txt.text : ''
  end

  def sub_total
    order_subtotal.text
  end

  def payment_method?(method)
    page.has_xpath?(".//td[contains(text(), '#{method}')]", wait: TimeOut::WAIT_MID_CONST)
  end
end
