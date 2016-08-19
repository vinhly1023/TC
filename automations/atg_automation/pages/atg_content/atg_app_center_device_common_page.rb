require 'pages/atg/atg_common_page'
require 'cgi'

class AtgAppCenterDeviceCommonPage < AtgCommonPage
  set_url URL::ATG_APP_CENTER_URL
  attr_reader :catalog_div_css, :pdp_div_css

  def initialize
    @catalog_div_css = '.container.no-pad.ng-scope'
    @pdp_div_css = '#product-overview'
  end

  element :product_catalog_div, '.container.no-pad.ng-scope'
  element :product_pdp_div, '#product-overview'
  elements :attributes_div, '.list-unstyled>li'

  # Load AppCenter home page
  def load(url)
    visit url
  end

  # Go to PDP page
  def go_pdp(prod_id)
    page.execute_script("$('##{prod_id} > a').click();")
    AtgAppCenterDeviceCommonPage.new
  end

  # Redirect to PDP page via pdp url
  def navigate_to_pdp(url)
    visit url
    AtgAppCenterDeviceCommonPage.new
  end

  # Get all HTML info on Catalog/Search page
  def catalog_html_content
    wait_for_product_catalog_div(TimeOut::WAIT_BIG_CONST)
    return Nokogiri::HTML('') unless page.has_css?(@catalog_div_css, wait: TimeOut::WAIT_MID_CONST)

    page_content("$(\"#{@catalog_div_css}\").html();")
  end

  # Get info on Catalog/Search page
  def catalog_product_info(html_doc, product_id)
    product_el = html_doc.xpath("(.//div[@class='row row-results']//div[translate(@id,'PROD','prod')=translate('#{product_id}','PROD','prod')] )[1]")
    return {} if product_el.empty?

    id = product_el.css('div>@id').to_s
    longname = product_el.css('.col-xs-12>h2').text
    href = product_el.css('div > a.thumbnail > @href').to_s
    curriculum = product_el.css('.curriculum>strong').text
    age = product_el.css('.age').text

    if product_el.at_css('.price.strike')
      price = "Strike: #{product_el.css('.price.strike').text} - Sale: #{product_el.css('.price.sale').text}"
    else
      price = product_el.css('.price').text
    end

    # Get content type
    screenshot_url = CGI.parse(product_el.css('.media-item>@src').to_s)
    content_type = screenshot_url['$label'][0]

    { id: id,
      longname: longname,
      href: href,
      curriculum: curriculum,
      age: age,
      price: price,
      content_type: content_type }
  end

  # @return Boolean
  def product_not_exist?(html_doc, product_id)
    html_doc.xpath("(.//div[translate(@id,'PROD','prod')=translate('#{product_id}','PROD','prod')] )[1]").empty?
  end

  # Get info on PDP page
  def pdp_info
    # Wait for loading PDP page
    wait_for_product_pdp_div(TimeOut::WAIT_BIG_CONST)

    return {} unless page.has_css?(@pdp_div_css, wait: TimeOut::WAIT_MID_CONST * 2)

    pdp_html_content = page_content("$(\"#{@pdp_div_css}\").html();")

    # Get all information
    long_name = pdp_html_content.css('.col-xs-12 .row > .col-xs-12 > h1').text
    curriculum_top = (pdp_html_content.css('.col-xs-12 .row > .col-xs-12 > h2').to_a)[0].text # Get the curriculum that displays under longname
    age = RspecEncode.remove_nbsp(pdp_html_content.css('.age').to_a[0].text)
    add_to_cart_btn = !pdp_html_content.at_css('.btn.btn-primary.ng-isolate-scope').nil? # If 'Add to Cart' button exists => return 'true', else => return 'false'
    add_to_wishlist = !pdp_html_content.at_css('.btn.btn-link.addToWishlistLogin').nil?
    description = RspecEncode.encode_description(pdp_html_content.css('.description').text)
    special_message = special_message(pdp_html_content)
    learning_difference = pdp_html_content.css('#teachingInfo>p').text
    has_credit_link = credit_link_exist?

    if pdp_html_content.at_css('.price.old.vcenter')
      price = "Strike: #{pdp_html_content.css('.price.old.vcenter').text} - Sale: #{pdp_html_content.css('.sale.vcenter').text}".delete("\n")
    else
      price = pdp_html_content.css('.price.vcenter').text.delete("\n")
    end

    # Get attributes info: content type, notable, curriculum, work with, publisher, size
    content_type = ''
    notable = ''
    curriculum_bottom = ''
    work_with = ''
    publisher = ''
    size = ''

    attributes_div = pdp_html_content.css('.list-unstyled>li').to_a
    attributes_div.each do |a|
      attr = a.text.split(':')
      content_type = attr[1].strip if attr[0].include?('Type')
      notable = attr[1].strip if attr[0].include?('Notable')
      curriculum_bottom = attr[1].strip if attr[0].include?('Curriculum') || attr[0].include?('Programme')
      work_with = attr[1].gsub(', ', ',').strip if attr[0].include?('Works With') || attr[0].include?('Fonctionne avec')
      publisher = attr[1].strip if attr[0].include?('Publisher') || attr[0].include?('Éditeur')
      size = attr[1].strip if attr[0].include?('Size') || attr[0].include?('Taille')
    end

    # Get legal top/bottom
    legals = legal_text
    legal_top = legals[:legal_top]
    legal_bottom = legals[:legal_bottom]

    # Get trailer link
    has_trailer = trailer_exist?
    trailer_link = []
    trailer_arr = (pdp_html_content.css('#productMediaCarousel .owl-stage .ui-carousel__item>.video').to_a)
    trailer_arr.each do |trailer|
      url = trailer.css('@ng-click').to_s.gsub('"', '\"')
      trailer_link.push(url)
    end

    # Get screen shot link
    screenshots = []
    screenshot_arr = pdp_html_content.css('#productMediaCarousel .owl-stage .ui-carousel__item>.media-item').to_a
    screenshot_arr.each do |sc|
      url = sc.css('@src').to_s
      alt = sc.css('@alt').to_s
      screenshots.push(url: url, alt: alt)
    end

    # Get product detail: => {:title, :text}
    details = []
    details_arr = pdp_html_content.css('#details-container div.details-item').to_a
    details_arr.each do |detail|
      title = RspecEncode.encode_title detail.css('h3').text
      text = RspecEncode.encode_description detail.css('p').to_s
      details.push(title: title, text: text)
    end

    # Get more info label/text
    more_info = more_info pdp_html_content
    more_info_label = more_info[:more_info_label]
    more_info_text = more_info[:more_info_text]

    # Get all teaches
    teaches = []
    teaches_arr = pdp_html_content.css('#teachingInfo>ul>li>span').to_a
    teaches_arr.each do |teach|
      teaches.push(teach.text)
    end

    # Get More like this: if exist => 'True', else => 'False'
    more_like_this_arr = (pdp_html_content.css('.thumbnail').to_a)[1]
    more_like_this = !more_like_this_arr.nil?

    # Put all info into array
    { long_name: long_name,
      curriculum_top: curriculum_top,
      age: age,
      price: price,
      has_trailer: has_trailer,
      trailer_link: trailer_link,
      screenshots: screenshots,
      legal_top: legal_top,
      add_to_wishlist: add_to_wishlist,
      add_to_cart_btn: add_to_cart_btn,
      description: description,
      content_type: content_type,
      notable: notable,
      curriculum_bottom: curriculum_bottom,
      work_with: work_with,
      publisher: publisher,
      size: size,
      special_message: special_message,
      more_info_label: more_info_label,
      more_info_text: more_info_text,
      details: details,
      teaches: teaches,
      learning_difference: learning_difference,
      has_credit_link: has_credit_link,
      more_like_this: more_like_this,
      legal_bottom: legal_bottom }
  end

  # Get special message
  def special_message(pdp_html_content)
    if page.has_css?('div >.row>.container>.row', wait: TimeOut::WAIT_SMALL_CONST)
      rows = pdp_html_content.css('div >.row>.container>.row').to_a
    else
      rows = pdp_html_content.css('.container .col-xs-12').to_a
    end

    return '' if rows.empty?

    mgs = ''
    rows.each_with_index do |r, index|
      if r.text.include?('Works With') || r.text.include?('Programme')
        mgs = rows[index + 1].text
        break
      end
    end

    return '' if ['Details', 'Teaches', 'Overall Rating:', 'Reviews', 'More Like This', 'Détails', 'Apports éducatifs', 'Apps similaires'].any? { |w| mgs =~ /#{w}/ }
    mgs.delete("\n")
  end

  # Get legal top/bottom text
  def legal_text
    pdp_html_content = page_content("$('.container-fluid').parent().html();")
    {
      legal_top: pdp_html_content.css('.col-xs-12 > .container .row .col-xs-12 .disclaimer').text,
      legal_bottom: pdp_html_content.css('.container-fluid > .container .row .col-xs-12 .disclaimer').text
    }
  end

  # Get more info label/text
  def more_info(pdp_html_content)
    more_info_text = ''
    more_info_label = pdp_html_content.css('#product-overview > .col-xs-12 .container > .row > .col-xs-12 > .btn.btn-link').text.gsub(/\s+/, ' ') # text.gsub(/\s+/,' ') => Replace double spaces with one spaces

    if more_info_label == 'Credits' || more_info_label == 'Crédits'
      more_info_label = ''
    else
      page.execute_script("$('#product-overview > .col-xs-12 .container > .row > .col-xs-12 > .btn.btn-link > .fa.fa-info-circle.fa-lg').click();")
      more_info_text = page.evaluate_script("$('.slidein .col-xs-12>p').text();").gsub(/\s+/, ' ')
    end

    # Close pop-up
    page.execute_script("$('.fa.fa-times.fa-2x.light-grey').click();")

    { more_info_label: more_info_label, more_info_text: more_info_text }
  end

  # Check if Trailer link exist or not exist
  def trailer_exist?
    !page.evaluate_script("$('#productMediaCarousel .owl-stage .ui-carousel__item>.video').attr('ng-click');").nil?
  end

  # Check if Credit link exist
  def credit_link_exist?
    credit_link_text = page.evaluate_script("$('#product-overview .col-xs-12>.btn.btn-link').text();")
    credit_link_text == 'Credits' || credit_link_text == 'Crédits'
  end

  # get Credit text
  def credits_text
    # Click on Credit link
    page.execute_script("$('#product-overview .col-xs-12>.btn.btn-link').click();")
    sleep(TimeOut::WAIT_MID_CONST)

    # Get credit text
    credits_text = page.evaluate_script("$('.slidein-content .richtext.section p:nth-of-type(-n + 2)').text();")

    # Close pop-up
    page.execute_script("$('.fa.fa-times.fa-2x.light-grey').click();")

    RspecEncode.encode_title credits_text
  end

  # Get YMAL information on PDP page
  def ymal_info_on_pdp
    page.has_css?('.row .row-results', wait: TimeOut::WAIT_MID_CONST)
    html_doc = page_content("$('.row .row-results').html();")

    ymal_arr = []
    html_doc.css('.owl-stage .owl-item').each do |el|
      prod_number = el.css('div> @id').to_s
      title = el.css('div>a>div.caption>div.row>div.col-xs-12>h2').text.strip
      link = el.css('div>a> @href').to_s

      # Put all info into array
      ymal_arr.push(prod_number: prod_number, title: title, link: link)
    end

    ymal_arr.uniq
  end

  def expected_catalog_product_info(title)
    { sku: title['sku'],
      prod_number: title['prodnumber'],
      short_name: RspecEncode.encode_title(title['shortname']),
      long_name: RspecEncode.encode_title(title['longname']),
      content_type: Title.content_type_mapping(title['contenttype']),
      curriculum: RspecEncode.normalizes_unexpected_characters(title['curriculum']),
      age: Title.calculate_age_device(title['agefrommonths'], title['agetomonths'], 'en', 'catalog'),
      price: Title.calculate_price(title['prices_total'], AppCenterContent::CONST_PRICE_TIER) }
  end

  def actual_catalog_product_info(product_info)
    { prod_number: product_info[:id],
      long_name: RspecEncode.encode_title(product_info[:longname]),
      content_type: product_info[:content_type],
      curriculum: RspecEncode.normalizes_unexpected_characters(product_info[:curriculum]),
      age: RspecEncode.remove_nbsp(product_info[:age]),
      price: RspecEncode.remove_nbsp(product_info[:price]),
      href: product_info[:href] }
  end

  def expected_pdp_product_info(title)
    if title['skills'] == 'Just for Fun' && title['learningdifference'] == ''
      teaches = []
      learning_difference = ''
    else
      teaches = Title.teach_info title['teaches']
      learning_difference = RspecEncode.encode_description(title['learningdifference'])
    end

    { sku: title['sku'],
      prod_number: title['prodnumber'].downcase,
      short_name: title['shortname'],
      long_name: RspecEncode.encode_title(title['longname']),
      age: Title.calculate_age_device(title['agefrommonths'], title['agetomonths']),
      price: Title.calculate_price(title['prices_total'], AppCenterContent::CONST_PRICE_TIER),
      legal_top: RspecEncode.encode_description(title['legaltop']),
      skill: title['skills'],
      has_trailer: title['trailer'] == 'Yes',
      trailer_link: title['trailerlink'],
      add_to_wishlist: true,
      add_to_cart_btn: true,
      description: RspecEncode.encode_description(title['lfdesc']),
      one_sentence: RspecEncode.encode_description(title['onesentence']),
      content_type: Title.content_type_mapping(title['contenttype']),
      notable: title['highlights'],
      curriculum: RspecEncode.normalizes_unexpected_characters(title['curriculum']),
      work_with: Title.replace_epic_platform(title['platformcompatibility'].split(',')),
      publisher: title['publisher'],
      size: Title.calculate_filesize(title['filesizes_total']),
      special_message: RspecEncode.encode_description(title['specialmsg']),
      more_info_label: title['moreinfolb'],
      more_info_text: title['moreinfotxt'],
      details: Title.title_details_info(title['details']).drop(1),
      learning_difference: learning_difference,
      more_like_this: true,
      legal_bottom: RspecEncode.encode_description(title['legalbottom']),
      has_credit_link: Title.content_type_mapping(title['contenttype']) == 'Music',
      credit_text: RspecEncode.encode_title(title['longname']),
      teaches: teaches }
  end

  def actual_pdp_product_info(pdp_info)
    { long_name_pdp: RspecEncode.encode_title(pdp_info[:long_name]),
      curriculum_top: RspecEncode.normalizes_unexpected_characters(pdp_info[:curriculum_top]),
      age: pdp_info[:age],
      price: pdp_info[:price],
      legal_top: RspecEncode.encode_description(pdp_info[:legal_top]),
      legal_bottom: RspecEncode.encode_description(pdp_info[:legal_bottom]),
      add_to_wishlist: pdp_info[:add_to_wishlist],
      add_to_cart_btn: pdp_info[:add_to_cart_btn],
      description: RspecEncode.encode_description(pdp_info[:description]),
      content_type: pdp_info[:content_type],
      notable: pdp_info[:notable],
      curriculum_bottom: RspecEncode.normalizes_unexpected_characters(pdp_info[:curriculum_bottom]),
      work_with: pdp_info[:work_with].split(','),
      publisher: pdp_info[:publisher],
      size: pdp_info[:size],
      special_message: RspecEncode.encode_description(pdp_info[:special_message]),
      more_info_label: pdp_info[:more_info_label],
      more_info_text: pdp_info[:more_info_text],
      details: pdp_info[:details],
      teaches: pdp_info[:teaches],
      learning_difference: RspecEncode.encode_description(pdp_info[:learning_difference]),
      more_like_this: pdp_info[:more_like_this],
      has_credit_link: pdp_info[:has_credit_link],
      has_trailer: pdp_info[:has_trailer],
      trailer_link: pdp_info[:trailer_link][0] }
  end
end
