require 'site_prism'

class AtgDvPDPPage < SitePrism::Page
  element :btn_pdp_select, '.btn.btn-primary.quanta.ng-scope'
  element :btn_confirm_yes, '.col-xs-12.starter-popup-confirm__buttons.text-center > button.btn.btn-primary'
  element :pop_up_confirm, '.ui-component-popup-content.starter__popup-confirm'

  def click_select_button
    btn_pdp_select.click
  end

  def click_yes_on_confirm_pop_up
    btn_confirm_yes.click
  end

  def select_button_exist?
    has_btn_pdp_select?(wait: TimeOut::WAIT_MID_CONST)
  end

  def confirmation_pop_up_exist?
    has_pop_up_confirm?(wait: TimeOut::WAIT_MID_CONST)
  end
end
