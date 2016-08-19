require 'pages/atg/atg_common_page'
require 'pages/atg/atg_app_center_checkout_page'

class AtgAppCenterCatalogPage < AtgCommonPage
  set_url URL::ATG_APP_CENTER_URL

  element :btn_add_to_cart_on_search_page, :xpath, "(.//button[@class='btn btn-add-to-cart btn-block ng-isolate-scope'])[1]"
  element :txt_search, '#search'
  element :btn_search, '#navSearch .btn'

  def load(input_url = nil)
    visit input_url || url
    wait_for_ajax

    close_email_capture_popup
    close_welcome_popup
    close_cookie_privacy_popup

    TestDriverManager.session_id
  end

  def go_pdp(product_number)
    page.find(:css, ".resultList .product-row ##{product_number} p>a", wait: TimeOut::WAIT_MID_CONST).click
    wait_for_ajax

    # Make sure pdp page is loaded successfully
    page.has_css? '#productOverview', wait: TimeOut::WAIT_MID_CONST

    close_welcome_popup

    AtgAppCenterCatalogPage.new
  end

  def add_app_to_cart_from_search_page(go_to_cart = true)
    btn_add_to_cart_on_search_page.click
    wait_for_ajax

    return unless go_to_cart
    nav_account_menu.app_center_cart_link.click
    wait_for_ajax

    AtgAppCenterCheckOutPage.new
  end

  def search_result?(product_id)
    has_text?("Results for #{product_id}", wait: TimeOut::WAIT_MID_CONST)
  end

  # Go to App Center check out page
  def go_to_cart_page
    nav_account_menu.app_center_cart_link.click
    wait_for_ajax
    nav_account_menu.app_center_cart_link.click if nav_account_menu.added_cart_item_number.text.to_i == 0
    AtgAppCenterCheckOutPage.new
  end

  # Add a product to Cart from catalog page by clicking on 'Add to Cart' button
  def add_app_to_cart(prod_id)
    item_num1 = nav_account_menu.added_cart_item_number.text.to_i

    # Workaround to make script stable by trying to click on Add to Cart button
    (1..3).each do
      page.execute_script("$('##{prod_id} button.btn.btn-add-to-cart').click();") if page.has_css?("##{prod_id} button.btn.btn-add-to-cart", wait: TimeOut::WAIT_MID_CONST)
      sleep TimeOut::WAIT_MID_CONST
      item_num2 = nav_account_menu.added_cart_item_number.text.to_i
      return if item_num1 < item_num2
    end
  end

  def open_quick_view_by_prod_id(prod_id)
    quick_link_css = ".resultList \##{prod_id} a.quick-view.btn.btn-green.btn-small"
    page.execute_script("$('#{quick_link_css}').click();")
  end

  def search_app(prod_id)
    txt_search.set prod_id
    btn_search.click
    wait_for_ajax
  end
end
