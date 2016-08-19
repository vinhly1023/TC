require 'pages/atg_dv/atg_dv_common_page'

class AtgDvMyAccountPage < AtgDvCommonPage
  elements :lbl_device_order_numbers, '.orderNumber>a'

  def dv_order_number_exists?(order_id)
    lbl_device_order_numbers.each do |order|
      return true if order.text.strip == order_id
    end

    false
  rescue
    false
  end
end
