require 'pages/atg_content/atg_app_center_web_common_page'

class AtgAppCenterLFCFrenchPage < AtgAppCenterWebCommonPage
  def expected_catalog_product_info(title)
    search_info = super

    search_info[:age] = Title.calculate_age_lfc(title['agefrommonths'], title['agetomonths'], 'fr', 'catalog')

    # If ContentType = 'Vidéo éducatif (Vidéo éducatives)' -> Verify content type is one of 'Vidéo éducatif' or 'Vidéo éducative'
    fr_content_type = Title.english_to_french(title['contenttype'], 'contenttype')
    if fr_content_type == 'Vidéo éducatif (Vidéo éducatives)'
      search_info[:content_type] = ['Vidéo éducatif', 'Vidéo éducative']
    else
      search_info[:content_type] = fr_content_type.split(',')
    end

    search_info
  end

  def actual_catalog_product_info(product_info)
    super
  end

  def expected_pdp_product_info(title)
    pdp_info = super

    # If ContentType = 'Vidéo éducatif (Vidéo éducatives)' -> Verify content type is one of 'Vidéo éducatif' or 'Vidéo éducative'
    fr_content_type = Title.english_to_french(title['contenttype'], 'contenttype')
    if fr_content_type == 'Vidéo éducatif (Vidéo éducatives)'
      pdp_info[:content_type] = ['Vidéo éducatif', 'Vidéo éducative']
    else
      pdp_info[:content_type] = fr_content_type.split(',')
    end

    # If Skill == 'Just for Fun' and learning_difference == '' => teaches = []
    if title['skills'] == 'Just for Fun|skill9' && title['learningdifference'] == ''
      pdp_info[:teaches] = []
    else
      pdp_info[:teaches] = Title.teach_info(Title.english_to_french(title['teaches'], 'teaches'))
    end

    pdp_info[:learning_difference] = (title['skills'] == 'Just for Fun' && title['learningdifference'] == '') ? '' : RspecEncode.encode_description(title['learningdifference'])
    pdp_info[:has_credits_link] = Title.english_to_french(title['contenttype'], 'contenttype') == 'Musique'
    pdp_info[:curriculum] = RspecEncode.normalizes_unexpected_characters(Title.english_to_french(title['curriculum'], 'curriculum'))
    pdp_info[:age] = Title.calculate_age_lfc(title['agefrommonths'], title['agetomonths'], 'fr')
    pdp_info[:work_with] = Title.map_french_platforms_to_english(title['platformcompatibility'])
    pdp_info[:publisher] = Title.convert_french_moas_data(title['publisher'])
    pdp_info[:filesize] = Title.calculate_filesize(title['filesizes_total'])
    pdp_info[:special_message] = RspecEncode.encode_description(title['specialmsg'])
    pdp_info[:buy_now_btn] = 'Acheter ▼'

    pdp_info
  end

  def actual_pdp_product_info(pdp_info)
    super
  end

  def expected_quick_view_product_info(title)
    quick_view_info = super

    # If Skill == 'Just for Fun' and learning_difference == '' => teaches = []
    if title['skills'] == 'Just for Fun' && title['learningdifference'] == ''
      quick_view_info[:teaches] = []
    else
      quick_view_info[:teaches] = Title.teach_info(Title.english_to_french(title['teaches'], 'teaches'))
    end

    quick_view_info[:age] = Title.calculate_age_lfc(title['agefrommonths'], title['agetomonths'], 'fr', 'quick_view')
    quick_view_info[:workswith_header] = 'Compatible avec :'
    quick_view_info[:see_detail_link] = 'Détails >'
    quick_view_info[:add_to_wishlist] = 'Ajouter à mes favoris'

    quick_view_info
  end

  def actual_quick_view_product_info(quick_view_info)
    super
  end
end
