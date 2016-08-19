require 'pages/atg_dv/atg_dv_common_page'
require 'pages/atg_dv/atg_dv_check_out_page'

class AtgDvAppCenterPage < AtgDvCommonPage
  element :catalog_div_css, '.container.no-pad.ng-scope'
  elements :product_div_css, '.container.no-pad.ng-scope>.row.row-results .col-xs-12.col-sm-4>div'
  element :txt_search_device, '#formSearch .form-control'
  element :btn_search_device, '#formSearch #btnSearch'
  element :txt_search_lfc, '#navSearch #search'
  element :btn_search_lfc, '#navSearch .btn.btn-search'

  def load
    visit url
    visit url unless has_catalog_div_css?(wait: TimeOut::WAIT_CONTROL_CONST)
    TestDriverManager.session_id
  end

  def dv_search_and_add_app_to_cart(product_id, device_store)
    if device_store.include? 'LFC'
      txt_search_lfc.set product_id
      btn_search_lfc.click
      page.find(:css, "##{product_id} .btn.btn-add-to-cart.btn-block.ng-isolate-scope", wait: TimeOut::WAIT_MID_CONST).click
    else
      txt_search_device.set product_id
      btn_search_device.click
      page.find(:css, "##{product_id} .btn.btn-block.btn-primary.ng-isolate-scope", wait: TimeOut::WAIT_MID_CONST).click
    end

    sleep TimeOut::WAIT_MID_CONST
  end
end
