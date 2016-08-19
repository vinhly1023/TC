require 'pages/atg/atg_common_page'

class AtgAppCenterWebCommonPage < AtgCommonPage
  set_url URL::ATG_APP_CENTER_URL

  elements :product_list_div, :xpath, "//div[@class='resultList']//div[@class='catalog-product blk blk-l' or @class='catalog-product']/div"
  element :product_detail_div, '#productDetails'
  elements :attributes_div, 'div.attributes>p'
  element :add_to_cart_btn, '#productDetails .btn.add-to-cart.atc-submit.btn-add-to-cart-softgoods'
  element :show_more_lnk, '#showBtn a'
  elements :teaches_txt, '.span3.skills-container>ul>li'
  element :credits_lnk, '.details-credits>div>a'
  element :credits_app_title_txt, '.richtext.section p:first-of-type'
  element :quick_view_overlay, '#productQuickview'

  def load(url)
    visit url
    wait_for_ajax

    close_email_capture_popup
    close_welcome_popup
    close_cookie_privacy_popup
  end

  def go_pdp(product_number)
    page.find(:xpath, "(.//div[@id='#{product_number}']/div/p/a)[1]", wait: TimeOut::WAIT_MID_CONST).click
    wait_for_ajax

    # Make sure pdp page is loaded successfully
    page.has_css? '#productOverview', wait: TimeOut::WAIT_MID_CONST

    close_welcome_popup

    AtgAppCenterCatalogPage.new
  end

  def navigate_to_pdp(url)
    visit url
    wait_for_ajax

    # Make sure pdp page is loaded successfully
    page.has_css? '#productOverview', wait: TimeOut::WAIT_MID_CONST

    close_welcome_popup

    AtgAppCenterCatalogPage.new
  end

  # Get HTML value in Catalog/Search pages
  def catalog_html_content
    wait_for_ajax
    page_content("$('.resultList .product-row').parent().html();")
  end

  # Get product info on Search/Catalog page
  def catalog_product_info(html_doc, product_id)
    product_el = html_doc.xpath("(.//div[translate(@id,'PROD','prod')=translate('#{product_id}','PROD','prod')] )[1]")
    return {} if product_el.empty?

    longname = product_el.css('div > div.product-inner > p > a').text
    href = product_el.css('div > div.product-inner > p > a > @href').to_s
    content_type = product_el.css('div > div.product-inner > div.product-thumb.has-content > @data-content').to_s
    format = product_el.css('div > div.product-inner p.format-type').text
    age = product_el.css('div > div.product-inner p.ageDisplay').text

    if product_el.at_css('span.single.price.strike')
      price = "Strike: #{product_el.css('span.single.price.strike').text} - Sale: #{product_el.css('span.single.price.sale').text}".delete("\n")
    else
      price = product_el.css('span.single.price').text
    end

    { id: product_id,
      longname: longname,
      href: href,
      price: price,
      content_type: content_type,
      format: format,
      age: age }
  end

  def product_not_exist?(html_doc, product_id)
    html_doc.xpath("(.//div[translate(@id,'PROD','prod')=translate('#{product_id}','PROD','prod')] )[1]").empty?
  end

  def details_title
    # Click on Show more link
    if has_show_more_lnk?
      page.execute_script("$('#showBtn a').click();")
      sleep TimeOut::WAIT_SMALL_CONST
    end

    details = [title: '', text: '']
    detail_html_content = page_content("$('.details-container').parent().html();")

    if detail_html_content.at_css('.detail-2col-dflt')
      details_arr = detail_html_content.css('.detail-2col-dflt').to_a
      details_arr.each do |detail|
        details.push(
          title: RspecEncode.encode_title(detail.css('h4').text),
          text: RspecEncode.encode_description(detail.css('p').text)
        )
      end
    else
      details.push(
        title: RspecEncode.encode_title(detail_html_content.css('.detail-content > h4').text),
        text: RspecEncode.encode_description(detail_html_content.css('.detail-content > p').text)
      )
    end

    details
  end

  def more_info(pdp_html_content)
    {
      moreinfo_lb: pdp_html_content.css('.credits-link>.text').text,
      moreinfo_txt: pdp_html_content.css('#credits').text
    }
  end

  def credits_text
    credits_lnk.click
    wait_for_credits_app_title_txt
    credits_app_title = has_credits_app_title_txt? ? credits_app_title_txt.text : 'Not display'
    find('[data-popup-name="Credits"]>div>a').click

    RspecEncode.encode_title credits_app_title
  end

  def pdp_info
    wait_for_product_detail_div(TimeOut::WAIT_BIG_CONST * 2)

    # Get all html text script
    return {} unless page.has_css?('.atg-wrapper', wait: TimeOut::WAIT_MID_CONST)

    pdp_html_content = page_content("$('.atg-wrapper').parent().html();")

    long_name = pdp_html_content.css('h1.product-name').text
    age = pdp_html_content.css('span.pdp-age-mo').text.strip
    description = pdp_html_content.css('.description').text
    special_message = pdp_html_content.css('.special-message').text
    legal_top = pdp_html_content.css('.legal-top').text
    legal_bottom = pdp_html_content.css('.legal-bottom.section .container').text
    learning_difference = pdp_html_content.css('.span9.teaches-media>p').text
    review = !pdp_html_content.at_css('#Reviews').nil?
    more_like_this = !pdp_html_content.at_css('#MoreLikeThis').nil?
    write_a_review = !pdp_html_content.at_css('.BVRRRatingSummary.BVRRPrimarySummary.BVRRPrimaryRatingSummary').nil?
    add_to_wish_list = !pdp_html_content.at_css('#productDetails .wishlist-link>a').nil?
    has_credits_link = !pdp_html_content.at_css('.details-credits>div>a').nil?
    buy_now_element = pdp_html_content.css('#sub-nav-grnbar-btn')
    buy_now_btn = buy_now_element.empty? ? 'Not exist' : buy_now_element.attr('value').to_s
    details = details_title

    more_info = more_info pdp_html_content
    moreinfo_lb = more_info[:moreinfo_lb]
    moreinfo_text = more_info[:moreinfo_txt]

    if pdp_html_content.at_css('#productDetails .single.price.strike')
      price = "Strike: #{pdp_html_content.css('#productDetails .single.price.strike').text} - Sale: #{pdp_html_content.css('#productDetails .single.price.sale').text}".delete("\n")
    else
      price = pdp_html_content.css('#productDetails .single.price').text.delete("\n")
    end

    content_type = ''
    curriculum = ''
    notable = ''
    work_with = ''
    publisher = ''
    size = ''
    attributes_div.each do |a|
      attr = a.text.split(':')
      content_type = attr[1].strip if attr[0].include?('Type')
      curriculum = attr[1].strip if attr[0].include?('Curriculum') || attr[0].include?('Programme')
      notable = attr[1..-1].join(':').strip if attr[0].include?('Notable') || attr[0].include?('Remarquable')
      work_with = attr[1].gsub(', ', ',').strip if attr[0].include?('Works With') || attr[0].include?('Compatible avec')
      publisher = attr[1].strip if attr[0].include?('Publisher') || attr[0].include?('Éditeur')
      size = attr[1].strip if attr[0].include?('Size') || attr[0].include?('Taille')
    end

    # Get trailer
    if pdp_html_content.at_css('.video').nil?
      has_trailer = false
      trailer_link = ''
    else
      has_trailer = true
      trailer_link = find('.video')['data-largeimage'].to_s.gsub('"', '\"')
    end

    # Get teaches (Skills list)
    teaches = []
    teaches_txt.each do |teach|
      teaches.push(teach.text)
    end

    if has_add_to_cart_btn?(wait: 0)
      add_to_cart_val = 'Add to Cart'
    else
      add_to_cart_val = 'Not Available'
    end

    { long_name: long_name,
      age: age,
      description: description,
      content_type: content_type,
      curriculum: curriculum,
      notable: notable,
      work_with: work_with,
      publisher: publisher,
      size: size,
      moreinfo_lb: moreinfo_lb,
      moreinfo_txt: moreinfo_text,
      special_message: special_message,
      legal_top: legal_top,
      price: price,
      details: details,
      learning_difference: learning_difference,
      legal_bottom: legal_bottom,
      teaches: teaches,
      has_trailer: has_trailer,
      trailer_link: trailer_link,
      has_credits_link: has_credits_link,
      review: review,
      more_like_this: more_like_this,
      write_a_review: write_a_review,
      add_to_wishlist: add_to_wish_list,
      add_to_cart_btn: add_to_cart_val,
      buy_now_btn: buy_now_btn }
  end

  def quick_view_product_by_prodnumber(prod_number)
    wait_for_ajax
    quickview_link_css = ".catalog-product \##{prod_number.downcase} .quick-view.btn.btn-green.btn-small"

    page.execute_script("$('#{quickview_link_css}').first().css('display', 'block');")
    page.execute_script("$('#{quickview_link_css}').first().click();")

    wait_for_quick_view_overlay(TimeOut::WAIT_BIG_CONST)
    sleep TimeOut::WAIT_SMALL_CONST
  end

  def quick_view_info(prod_number, language = 'english')
    quick_view_product_by_prodnumber prod_number

    # Get all html text script
    return {} unless page.has_css?('#productQuickview', wait: TimeOut::WAIT_MID_CONST)

    quick_view_content = page_content("$('#productQuickview').html();")

    long_name = quick_view_content.css('h2>a').text
    ages = quick_view_content.css('.span6.description.qv-description-block .ageDisplay').text.gsub(/\n+/, ' ').strip
    see_detail_link = quick_view_content.css('.span6.description.qv-description-block a').text
    add_to_wish_list = quick_view_content.css('.wishlist-link>a').text
    add_to_cart = quick_view_content.at_css('.btn.btn-yellow.add-to-cart.atc-submit.btn-add-to-cart-softgoods').nil? ? 'Not Available' : 'Add to Cart'
    description_header = quick_view_content.css('.span6.description.qv-description-block>h3:nth-of-type(1)').text.delete("\n").strip
    description = quick_view_content.css('.span6.description.qv-description-block>p:nth-of-type(2)').text

    quick_view_info = quick_view_content.css('.span6.description.qv-description-block').text.gsub(/\n+/, ' ').strip
    teaches_header = quick_view_content.css('.span6.description.qv-description-block>h3:nth-of-type(2)').text.delete("\n").strip
    works_with_header = quick_view_content.css('.span6.description.qv-description-block>h3:nth-of-type(3)').text.delete("\n").strip

    if language == 'french'
      if teaches_header == 'Apports éducatifs'
        sec1 = quick_view_info.split('Apports éducatifs')[1].split('Compatible avec :')
        teaches = sec1[0]
        works_with = sec1[1].gsub('Détails >', '').strip
      else
        sec1 = quick_view_info.split('Compatible avec :')
        teaches = ''
        works_with = sec1[1].gsub('Détails >', '').strip
      end
    else
      if teaches_header == 'Teaches:'
        sec1 = quick_view_info.split('Teaches:')[1].split('Works With:')
        teaches = sec1[0]
        works_with = sec1[1].gsub('See Details >', '').strip
      else
        sec1 = quick_view_info.split('Works With:')
        teaches = ''
        works_with = sec1[1].gsub('See Details >', '').strip
      end
    end

    if quick_view_content.at_css('.single.price.strike')
      price = "Strike: #{quick_view_content.css('.single.price.strike').text} - Sale: #{quick_view_content.css('.single.price.sale').text}".delete("\n")
    else
      price = quick_view_content.css('.single.price').text.delete("\n")
    end

    # get size of small icon [height, width]
    if quick_view_content.at_css('.softgood-sku>img')
      s_height = page.evaluate_script("$('.softgood-sku>img')[0].naturalHeight")
      s_width = page.evaluate_script("$('.softgood-sku>img')[0].naturalWidth")
    else # Mini bundle apps
      s_height = page.evaluate_script("$('.digital-virtual-bundle>img')[0].naturalHeight")
      s_width = page.evaluate_script("$('.digital-virtual-bundle>img')[0].naturalWidth")
    end
    small_icon_size = %W(#{s_height} #{s_width})

    # get size of large icon [height, width]
    # large_icon_size = [quick_view_info.large_icon_img[:naturalHeight], quick_view_info.large_icon_img[:naturalWidth]]
    if quick_view_content.at_css('.video-container>img')
      l_height = page.evaluate_script("$('.video-container>img')[0].naturalHeight")
      l_width = page.evaluate_script("$('.video-container>img')[0].naturalWidth")
    else # Mini bundle apps
      l_height = page.evaluate_script("$('.row.rollover-top>img')[0].naturalHeight")
      l_width = page.evaluate_script("$('.row.rollover-top>img')[0].naturalWidth")
    end
    large_icon_size = %W(#{l_height} #{l_width})

    { long_name: long_name,
      ages: ages,
      description_header: description_header,
      description: description,
      teaches: teaches,
      workswith_header: works_with_header,
      workswith: works_with,
      see_detail_link: see_detail_link,
      price: price,
      add_to_cart: add_to_cart,
      add_to_wishlist: add_to_wish_list,
      small_icon_size: small_icon_size,
      large_icon_size: large_icon_size }
  end

  # Get YMAL information on PDP page
  def ymal_info_on_pdp
    ymal_arr = []

    return ymal_arr unless page.has_css?('.reccommended', wait: 30)
    str = page.evaluate_script("$('.reccommended').html();")

    # convert string element to html element
    ymal_html_content = Nokogiri::HTML(str)

    # get all information of product
    ymal_html_content.css('.catalog-product').each do |el|
      ymal_arr.push(
        prod_number: el.css('div > @id').to_s,
        title: el.css('div>div.product-inner>p>a> @title').to_s.strip,
        link: el.css('div>div.product-inner>p>a> @href').to_s
      )
    end

    ymal_arr
  end

  # Return true if e_arr and a_arr there is at least one same element
  def two_platforms_compare?(e_platform, a_platform)
    e_arr = e_platform.split(',')
    a_arr = a_platform.split(',')
    !(e_arr & a_arr).empty?
  end

  def expected_catalog_product_info(title)
    { sku: title['sku'],
      prod_number: title['prodnumber'],
      short_name: RspecEncode.encode_title(title['shortname']),
      long_name: RspecEncode.encode_title(title['longname']),
      price: Title.calculate_price(title['prices_total'], AppCenterContent::CONST_PRICE_TIER),
      content_type: Title.content_type_mapping(title['contenttype']),
      format: title['format'],
      age: Title.calculate_age_web(title['agefrommonths'], title['agetomonths'], 'catalog') }
  end

  def actual_catalog_product_info(product_info)
    { long_name: RspecEncode.encode_title(product_info[:longname]),
      price: product_info[:price].strip,
      content_type: product_info[:content_type],
      format: product_info[:format],
      href: product_info[:href],
      age: RspecEncode.remove_nbsp(product_info[:age]) }
  end

  def expected_pdp_product_info(title)
    if title['skills'] == 'Just for Fun' && title['learningdifference'] == ''
      teaches = []
      learning_difference = ''
    else
      teaches = Title.teach_info title['teaches']
      learning_difference = RspecEncode.encode_description title['learningdifference']
    end

    { sku: title['sku'],
      prod_number: title['prodnumber'],
      short_name: RspecEncode.encode_title(title['shortname']),
      long_name: RspecEncode.encode_title(title['longname']),
      description: RspecEncode.encode_description(title['lfdesc']),
      one_sentence: RspecEncode.encode_description(title['onesentence']),
      age: Title.calculate_age_web(title['agefrommonths'], title['agetomonths']),
      content_type: Title.content_type_mapping(title['contenttype']),
      format: title['format'],
      price: Title.calculate_price(title['prices_total'], AppCenterContent::CONST_PRICE_TIER),
      curriculum: title['curriculum'],
      work_with: Title.replace_epic_platform(title['platformcompatibility'].split(',')),
      publisher: title['publisher'],
      filesize: Title.calculate_filesize(title['filesizes_total']),
      special_message: RspecEncode.encode_description(title['specialmsg']),
      moreinfo_lb: RspecEncode.encode_description(title['moreinfolb']),
      moreinfo_txt: RspecEncode.encode_description(title['moreinfotxt']),
      legal_top: RspecEncode.encode_description(title['legaltop']),
      has_trailer: title['trailer'] == 'Yes',
      trailer_link: title['trailerlink'],
      details: Title.title_details_info(title['details']).drop(1),
      learning_difference: learning_difference,
      legal_bottom: RspecEncode.encode_description(title['legalbottom']),
      review: true,
      more_like_this: true,
      write_a_review: true,
      add_to_wishlist: true,
      add_to_cart_btn: 'Add to Cart',
      buy_now_btn: 'Buy Now ▼',
      highlights: title['highlights'],
      has_credits_link: Title.content_type_mapping(title['contenttype']) == 'Music',
      credits_text: RspecEncode.encode_title(title['longname']),
      teaches: teaches }
  end

  def actual_pdp_product_info(pdp_info)
    { long_name: RspecEncode.encode_title(pdp_info[:long_name]),
      write_a_review: pdp_info[:write_a_review],
      description: RspecEncode.encode_description(pdp_info[:description]),
      age: RspecEncode.remove_nbsp(pdp_info[:age]),
      curriculum: pdp_info[:curriculum],
      content_type: pdp_info[:content_type],
      notable: pdp_info[:notable],
      work_with: pdp_info[:work_with].split(','),
      publisher: pdp_info[:publisher],
      filesize: pdp_info[:size],
      special_message: RspecEncode.encode_description(pdp_info[:special_message]),
      moreinfo_lb: RspecEncode.encode_description(pdp_info[:moreinfo_lb]),
      moreinfo_txt: RspecEncode.encode_description(pdp_info[:moreinfo_txt]),
      legal_top: RspecEncode.encode_description(pdp_info[:legal_top]),
      price: pdp_info[:price],
      add_to_wishlist: pdp_info[:add_to_wishlist],
      add_to_cart_btn: pdp_info[:add_to_cart_btn],
      buy_now_btn: pdp_info[:buy_now_btn],
      details: pdp_info[:details].drop(1),
      teaches: pdp_info[:teaches],
      learning_difference: RspecEncode.encode_description(pdp_info[:learning_difference]),
      legal_bottom: RspecEncode.encode_description(pdp_info[:legal_bottom]),
      review: pdp_info[:review],
      more_like_this: pdp_info[:more_like_this],
      highlights: pdp_info[:notable],
      has_credits_link: pdp_info[:has_credits_link],
      has_trailer: pdp_info[:has_trailer],
      trailer_link: pdp_info[:trailer_link] }
  end

  def expected_quick_view_product_info(title)
    if title['skills'] == 'Just for Fun' && title['learningdifference'] == ''
      teaches = []
    else
      teaches = Title.teach_info title['teaches']
    end

    { sku: title['sku'],
      prod_number: title['prodnumber'],
      short_name: title['shortname'],
      long_name: RspecEncode.encode_title(title['longname']),
      age: Title.calculate_age_web(title['agefrommonths'], title['agetomonths'], 'quick_view'),
      description_header: 'Description:',
      description: RspecEncode.encode_description(title['lfdesc']),
      teaches: teaches,
      workswith_header: 'Works With:',
      workswith: Title.replace_epic_platform(title['platformcompatibility'].gsub(/,\s+/, ',').split(',')),
      see_detail_link: 'See Details >',
      price: Title.calculate_price(title['prices_total'], AppCenterContent::CONST_PRICE_TIER),
      add_to_cart: 'Add to Cart',
      add_to_wishlist: 'Add to Wishlist',
      small_icon_size: %w(80 143),
      large_icon_size: %w(135 240),
      one_sentence: RspecEncode.encode_description(title['onesentence']) }
  end

  def actual_quick_view_product_info(quick_view_info)
    { long_name: RspecEncode.encode_title(quick_view_info[:long_name]),
      age: RspecEncode.remove_nbsp(quick_view_info[:ages]),
      description_header: quick_view_info[:description_header],
      description: RspecEncode.encode_description(quick_view_info[:description]),
      teaches: quick_view_info[:teaches].split(',').compact.map(&:strip).sort,
      workswith_header: quick_view_info[:workswith_header],
      workswith: quick_view_info[:workswith].gsub(/,\s+/, ',').split(','),
      see_detail_link: quick_view_info[:see_detail_link],
      price: quick_view_info[:price],
      add_to_cart: quick_view_info[:add_to_cart],
      add_to_wishlist: quick_view_info[:add_to_wishlist],
      small_icon_size: quick_view_info[:small_icon_size],
      large_icon_size: quick_view_info[:large_icon_size] }
  end
end
