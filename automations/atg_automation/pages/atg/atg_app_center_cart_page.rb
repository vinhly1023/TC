require 'pages/atg/atg_common_page'

class AtgAppCenterCartPage < AtgCommonPage
  set_url_matcher(/.*\/checkout.*/)

  elements :remove_item_lnk, '.fa.fa-lg.fa-times-circle'
  element :first_remove_item_lnk, :xpath, "(.//i[@class='fa fa-lg fa-times-circle'])[1]"
  element :promote_code_txt, 'input[name=couponCode]'
  element :promote_apply_btn, :xpath, './/button[text()="Apply"]'
  element :promote_response_success, '.response p'
  element :promote_response_error, '.response div'

  def product_info_in_cart(product_id)
    return {} unless page.has_css?('.no-style.cart__list', wait: TimeOut::WAIT_BIG_CONST)

    str = page.evaluate_script("$('.no-style.cart__list').html();")
    html_doc = Nokogiri::HTML(str)

    html_doc.css('.cart__item.ng-scope').each do |el|
      if el.css('div.media >a.pull-left> @href').to_s.split('/')[-1].gsub('A-', '') == product_id
        title = el.css('div>h3.title>a.ng-binding').text

        if el.at_css('div.span3>div.qty-price>span.single.price.strike.ng-binding')
          price = el.css('div.span3>div.qty-price>span.single.price.strike.ng-binding').text
        else
          price = el.css('div.span3>div.qty-price>span.single.price').text
        end

        return {
          prod_id: product_id,
          title: RspecEncode.encode_title(title),
          price: RspecEncode.remove_nbsp(price)
        }
      end
    end

    {}
  end

  def clean_cart_page
    return unless has_remove_item_lnk?(wait: TimeOut::WAIT_MID_CONST)

    num_of_link = remove_item_lnk.count
    num_of_link.times do
      first_remove_item_lnk.click
      sleep TimeOut::WAIT_MID_CONST
    end
  end

  def cart_empty?
    !page.has_css?('.media.softgoods-cart-item__body', wait: TimeOut::WAIT_BIG_CONST)
  end

  def promote_code(code)
    promote_code_txt.set code
    promote_apply_btn.click
    wait_for_ajax
  end

  def promote_response
    if has_promote_response_success?(wait: TimeOut::WAIT_MID_CONST)
      promote_response_success.text
    else
      promote_response_error.text
    end
  rescue
    ''
  end
end
