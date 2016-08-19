require 'capybara'
require 'capybara/rspec'
require 'selenium-webdriver'
require 'site_prism'

class NavAccountSection < SitePrism::Section
  element :login_register_link, '#headerLogin'
  element :app_center_cart_link, '.nav-account__mini-cart-softgoods-link'
  element :added_cart_item_number, :xpath, ".//a[@class='nav-account__mini-cart-softgoods-link']/span"
  element :logout_link, '#atg_logoutBtn'
  element :login_link, '#atg_loginBtn'
  element :checkout_btn, '#miniCartCheckoutBtn'
  element :my_wishlist_lnk, '.nav-account__my-wishlist-list-item .nav-account__my-account-link'
  element :add_item_to_card_lnk, :xpath, "//*[@id='atg_miniWishlistItems']//*[contains(text(),'Add to Cart')][1]"
  element :wishlist_item_number_txt, '.nav-account__my-account-link .ng-binding'
  element :products_link, :xpath, "//*[@id='header']//a[@title='Products']"
end

class MyAccountMenuSection < SitePrism::Section
  element :my_profile_link, :xpath, ".//ul/li/a[contains(text(),'My Profile')]", visible: false
  element :my_orders_link, :xpath, ".//ul/li/a[contains(text(),'My Orders')]", visible: false
  element :welcome_link, :xpath, './/p/strong/span', visible: false
  element :account_balance, :xpath, ".//div/p/span[@ng-bind='shop.accountBalance.fmt']", visible: false
  element :redeem_code_lnk, :xpath, ".//li/a[contains(text(),'Redeem Code')]"
end

class AppCenterDropDownSection < SitePrism::Section
  element :check_out_btn, '.btn.btn-yellow.pull-right.ng-scope'
  elements :cart_items, '.cart-item.mini-cart__item.ng-scope'
  element :remove_item, '.mini-cart__item-action-remove.ng-isolate-scope'
  element :add_to_wishlist, '.mini-cart__item-action-add-to-wishlist.ng-isolate-scope'
  element :cart_dropdown_text, '.text-center .mini-cart-empty.fontsize18'
end

class MyWishlistDropDownSection < SitePrism::Section
  element :wishlist_header, 'div.center h3.no-margin'
end

class AtgCommonPage < SitePrism::Page
  section :nav_account_menu, NavAccountSection, '#navAccount'
  section :my_account_menu, MyAccountMenuSection, '.ui-popover__modal-my-account'
  section :my_wishlist_menu, MyWishlistDropDownSection, '.ui-popover__modal.ui-popover__modal-mini-wishlist'
  section :app_center_cart_menu, AppCenterDropDownSection, '.ui-popover__modal.ui-popover__modal-mini-cart-softgoods'

  element :leapfrog_logo, '.brand>img'
  element :search_btn, :xpath, "//button[@class='btn']"
  element :add_to_cart_btn, :xpath, "(//*[@cart-button='add' or contains(text(),'Add to Cart')])[1]"
  element :logout_link, :xpath, ".//div[@class='logged-in ng-scope']//a[contains(text(),'Logout')]"
  element :added_wishlist_item_number, :xpath, ".//*[@id='navAccount']//a[@class='nav-account__my-account-link']/span"

  def refresh
    visit current_url
  end

  def page_content(jquery)
    Nokogiri::HTML(page.evaluate_script(jquery).to_s.gsub('<br>', ' '))
  end

  def close_welcome_popup
    page.execute_script("$('.btn.btn-primary.btn-primary_red.center-block.text-center').click()")
  end

  def close_email_capture_popup
    page.execute_script("$('#monetate_lightbox').css('display','none')")
  end

  def close_device_selection_popup
    page.execute_script("$('.ui-popup__modal_video .fa.fa-times-circle').click()")
  end

  def close_cookie_privacy_popup
    page.execute_script("$('#cookie-privacy-banner .close.margin20r').click()")
  end

  def goto_login
    # Go to "Log in/Register" page
    nav_account_menu.login_register_link.click

    atg_login_register = AtgLoginRegisterPage.new
    unless atg_login_register.has_login_form?(wait: TimeOut::WAIT_CONTROL_CONST)
      visit current_url
      nav_account_menu.login_register_link.click
    end

    close_email_capture_popup
    close_welcome_popup
    close_device_selection_popup
    close_cookie_privacy_popup
    
    atg_login_register
  end

  def login_register_text
    nav_account_menu.login_register_link.text.strip
  rescue
    ''
  end

  def show_all_account_menus
    execute_script("$('.ui-popover__container').attr('style', 'opacity: 1; z-index: 1011; top: 41px; left: 506.7px; display: block;')")
  end

  def mouse_hover_my_account_link
    page.execute_script("$('#headerLogin').trigger('mouseenter')")
  end

  def mouse_hover_wishlist_link
    page.execute_script("$('.nav-account__my-wishlist-list-item .nav-account__my-account-link').trigger('mouseenter')")
  end

  def mouse_hover_app_center_link
    page.execute_script("$('.nav-account__mini-cart-softgoods-link').trigger('mouseenter')")
  end

  def welcome_text
    'Welcome ' + my_account_menu.welcome_link.text.strip
  rescue
    ''
  end

  def click_redeem_code_link
    my_account_menu.redeem_code_lnk.click
  end

  def account_balance_under_my_profile
    my_account_menu.account_balance.text.strip
  rescue
    ''
  end

  def cart_item_number
    nav_account_menu.added_cart_item_number.text.to_i
  rescue
    0
  end

  def wishlist_item_number
    added_wishlist_item_number.text.to_i
  rescue
    0
  end

  def wishlish_header_text
    mouse_hover_wishlist_link
    my_wishlist_menu.wishlist_header.text
  rescue
    ''
  end

  def wishlist_items_box?
    page.has_css?('.row.atg-product.ng-scope .media', wait: TimeOut::WAIT_MID_CONST)
  end

  def product_info_under_cart_dropdown(product_id)
    mouse_hover_app_center_link
    return {} unless page.has_css?('.ui-popover__modal.ui-popover__modal-mini-cart-softgoods')

    # convert string element to html element
    str = page.evaluate_script("$('.ui-popover__modal.ui-popover__modal-mini-cart-softgoods').html();")
    html_doc = Nokogiri::HTML(str)

    html_doc.css('.cart-item.mini-cart__item.ng-scope').each do |el|
      if el.css('.mini-cart__item-title a.ng-binding > @href').to_s.split('/')[-1].gsub('A-', '') == product_id
        title = el.css('.mini-cart__item-title a.ng-binding').text

        if el.at_css('.mini-cart__item-price > .single.price.mini')
          price = el.css('.mini-cart__item-price > .single.price.mini').text
        else
          price = el.css('.mini-cart__item-price > .ng-binding').text
        end

        return {
          prod_id: product_id,
          title: RspecEncode.encode_title(title),
          price: RspecEncode.remove_nbsp(price),
        }
      end
    end

    {}
  end

  def product_info_under_wishlist_dropdown(product_id)
    mouse_hover_wishlist_link
    return {} unless page.has_css?('.ui-popover__modal.ui-popover__modal-mini-wishlist')

    # convert string element to html element
    str = page.evaluate_script("$('.ui-popover__modal.ui-popover__modal-mini-wishlist').html();")
    html_doc = Nokogiri::HTML(str)

    html_doc.css('.cart-item').each do |el|
      if el.css('@data-productid').to_s == product_id
        title = el.css('.product-title').text
        strike = el.css('.strike.ng-binding.ng-scope').text
        sale = el.css('.price.ng-binding.sale').text
        price = strike.blank? ? el.css('.price.ng-binding').text : ''

        return {
          prod_id: product_id,
          title: RspecEncode.encode_title(title),
          price: RspecEncode.remove_nbsp(price),
          strike: RspecEncode.remove_nbsp(strike),
          sale: RspecEncode.remove_nbsp(sale)
        }
      end
    end

    {}
  end

  def remove_item_from_wishlist_dropdown product_id
    item_num1 = wishlist_item_number
    return if item_num1 == 0

    # Mouse hover on Wishlist menu items
    mouse_hover_wishlist_link

    find(:xpath, ".//li[@data-productid='#{product_id}']//i[@class='icon-close icon']", wait: TimeOut::WAIT_MID_CONST).click
    sleep TimeOut::WAIT_SMALL_CONST

    item_num2 = wishlist_item_number
    return if item_num2 == item_num1 - 1

    find(:xpath, ".//li[@data-productid='#{product_id}']//i[@class='icon-close icon']", wait: TimeOut::WAIT_MID_CONST).click
    sleep TimeOut::WAIT_SMALL_CONST
  end

  def app_center_cart_dropdown_displays?
    app_center_cart_menu.has_check_out_btn?
  end

  def app_center_dropdown_text
    app_center_cart_menu.cart_dropdown_text.text.to_s.strip
  rescue
    ''
  end

  def hover_app_center_cart
    nav_account_menu.execute_script('$(".nav-account__mini-cart-softgoods-link").trigger("mouseenter")')
  end

  def hover_my_wishlist
    nav_account_menu.execute_script('$(".nav-account__my-wishlist-list-item .nav-account__my-account-link").trigger("mouseenter")')
  end

  def hover_the_x_in_the_menu
    page.execute_script("$('.mini-cart__item-actions-dropdown').attr('style', 'opacity: 1; display: block;')")
  end

  def remove_item_app_center_dropdown_cart
    app_center_cart_menu.remove_item.click
    sleep TimeOut::WAIT_SMALL_CONST
  end

  def add_to_wishlist_from_app_center_dropdown_cart
    app_center_cart_menu.add_to_wishlist.click
  end

  def goto_my_account
    nav_account_menu.login_register_link.click

    atg_my_profile_page = AtgMyProfilePage.new

    5.times do
      break if atg_my_profile_page.has_account_information_link?(wait: TimeOut::WAIT_BIG_CONST)

      refresh
      nav_account_menu.login_register_link.click

      next
    end

    atg_my_profile_page
  end

  # Search by Product ID or Title
  def search_product(item)
    wait_for_ajax
    fill_in 'search', with: item
    wait_for_ajax
    search_btn.click
    wait_for_ajax
  end

  def goto_checkout
    nav_account_menu.shop_cart_link.click

    # handle: if not on check out page
    app_center_cart_page = AtgAppCenterCartPage.new
    nav_account_menu.shop_cart_link.click unless app_center_cart_page.has_checkout_btn?(wait: TimeOut::WAIT_MID_CONST)
    wait_for_ajax
    app_center_cart_page
  end

  def goto_my_wishlist
    nav_account_menu.my_wishlist_lnk.click
    wait_for_ajax

    wishlist_page = AtgWishListPage.new
    return wishlist_page if wishlist_page.has_wishlist_header?(wait: TimeOut::WAIT_CONTROL_CONST)
  end

  def logout
    5.times do
      mouse_hover_my_account_link

      if has_logout_link?(wait: TimeOut::WAIT_MID_CONST)
        logout_link.click
        wait_for_ajax
        break
      end

      next
    end

    AtgAppCenterCatalogPage.new
  end

  def logout_successful?
    current_url.include?('/home?DPSLogout=true')
  end

  # TBD
  def wait_for_ajax
    Timeout.timeout TimeOut::READ_TIMEOUT_CONST do
      # handle exception: execution expired. The network is sometimes slow, default_wait_time is not enough
      begin
        active = evaluate_script 'jQuery.active'
        active = evaluate_script 'jQuery.active' until active == 0
      rescue => e
        puts "The network is slow. Should optimize the network or increase the time wait\nError class: #{e.class.name}"
      end
    end
  end

  #
  # Get SKU, title, platformcompatibility, supported locales of a SKU from database
  #
  def get_ymal_in_database(title_ymal, locale, is_cabo = false)
    ymal_info = []
    ymal_sku_arr = title_ymal.nil? ? [] : title_ymal.downcase.split(',')

    ymal_sku_arr.each do |sku|
      titles_list = Connection.my_sql_connection(AppCenterContent::CONST_QUERY_GET_YMAL_INFO % [sku, locale])
      titles_list = Connection.my_sql_connection(CaboAppCenterContent::CONST_CABO_QUERY_GET_YMAL_INFO % [sku, locale]) if is_cabo # If run for CABO platform
      titles_list.each do |title|
        ymal_info.push(
          sku: sku,
          prod_number: title['prodnumber'],
          title: title['longname'],
          platform: title['platformcompatibility'],
          us: title['us'],
          ca: title['ca'],
          uk: title['uk'],
          ie: title['ie'],
          au: title['au'],
          row: title['row']
        )
      end
    end

    ymal_info
  end

  def support_locale?(ymal_title_hash, locale)
    support =
      case locale.upcase
      when 'US' then
        ymal_title_hash[:us]
      when 'CA' then
        ymal_title_hash[:ca]
      when 'UK' then
        ymal_title_hash[:uk]
      when 'IE' then
        ymal_title_hash[:ie]
      when 'AU' then
        ymal_title_hash[:au]
      else
        ymal_title_hash[:row]
      end

    support.to_s.downcase == 'x'
  end

  def generate_pdp_url(url_const, product_long_name, product_number)
    url_const + '/' + product_long_name.downcase.gsub(/[^0-9a-z ]/i, '').gsub(' ', '-') + '/_/A-' + product_number.downcase
  end

  def page_title
    RspecEncode.remove_nbsp(page.title.strip)
  end
end
