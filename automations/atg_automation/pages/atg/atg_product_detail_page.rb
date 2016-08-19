require 'pages/atg/atg_common_page'

class AtgProductDetailPage < AtgCommonPage
  element :breadcrumbs_div, '#breadcrumbs'
  element :add_to_wish_list_without_login_link, :xpath, "//div[@id='productOverview']//a[@class='addToWishlistlogin']"
  element :add_to_wish_list, :xpath, "(//div[@id='productOverview']//a[@class='addToWishlist'])[1]"
  element :add_to_cart_on_pdp_btn, :xpath, "//*[@id='productOverview']//*[@id='addItemToCartForm']//input[@class='btn btn-yellow add-to-cart atc-submit btn-add-to-cart-softgoods']"

  def add_to_cart_from_pdp
    item_num1 = cart_item_number
    item_num2 = 0

    # Workaround to make script stable by trying to click on Add to Cart button
    3.times do
      add_to_cart_on_pdp_btn.click if has_add_to_cart_on_pdp_btn?(wait: TimeOut::WAIT_SMALL_CONST)
      sleep TimeOut::WAIT_SMALL_CONST
      item_num2 = cart_item_number
      break if item_num1 < item_num2
    end

    item_num1 < item_num2
  end

  def pdp_displays?(product_id)
    has_breadcrumbs_div?
    current_url.include? product_id
  end

  def add_to_wishlist
    if has_add_to_wish_list?(wait: TimeOut::WAIT_MID_CONST)
      add_to_wish_list.click
    else
      add_to_wish_list_without_login_link.click
    end

    sleep TimeOut::WAIT_MID_CONST
  end
end
