require 'site_prism'

class AtgQuickViewOverlayPage < SitePrism::Page
  element :quick_view_overlay, :xpath, "//*[@id='productQuickview']/a[text()='Close']"
  element :add_to_cart_btn, :xpath, "//div[@id='productQuickview']//input[contains(@value, 'Add to Cart')]"
  element :add_to_wish_list_lnk, '#addToWishlist'

  def quick_view_overlay_displayed?
    has_quick_view_overlay?(wait: TimeOut::WAIT_MID_CONST)
  end

  def add_to_cart_from_quickview
    add_to_cart_btn.click
    sleep TimeOut::WAIT_MID_CONST
  end

  def add_to_wishlist
    add_to_wish_list_lnk.click
    sleep TimeOut::WAIT_SMALL_CONST
  end
end
