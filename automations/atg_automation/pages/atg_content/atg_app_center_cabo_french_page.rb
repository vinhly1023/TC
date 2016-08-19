require 'pages/atg_content/atg_app_center_device_common_page'

# ATG App Center page French
class AtgAppCenterCaboFrenchPage < AtgAppCenterDeviceCommonPage
  def expected_catalog_product_info(title)
    # Map content type from EN to FR
    content_type_str = Title.english_to_french(title['contenttype'], 'contenttype')

    # If ContentType = 'Vidéo éducatif (Vidéo éducatives)' -> Verify content type is one of 'Vidéo éducatif' or 'Vidéo éducative'
    content_type = (content_type_str == 'Vidéo éducatif (Vidéo éducatives)') ? ['Vidéo éducatif', 'Vidéo éducative'] : content_type_str.split(',')

    e_search_info = super
    e_search_info[:content_type] = content_type
    e_search_info[:curriculum] = RspecEncode.normalizes_unexpected_characters(Title.english_to_french(title['curriculum'], 'curriculum'))
    e_search_info[:age] = Title.calculate_age_device(title['agefrommonths'], title['agetomonths'], 'fr', 'catalog')

    e_search_info
  end

  def actual_catalog_product_info(product_info)
    super
  end

  def expected_pdp_product_info(title)
    # Map content type from EN to FR
    content_type_str = Title.english_to_french(title['contenttype'], 'contenttype')

    # If ContentType = 'Vidéo éducatif (Vidéo éducatives)' -> Verify content type is one of 'Vidéo éducatif' or 'Vidéo éducative'
    content_type = (content_type_str == 'Vidéo éducatif (Vidéo éducatives)') ? ['Vidéo éducatif', 'Vidéo éducative'] : content_type_str.split(',')

    if title['skills'] == 'Just for Fun' && title['learningdifference'] == ''
      teaches = []
      learning_difference = ''
    else
      teaches = Title.teach_info(Title.english_to_french(title['teaches'], 'teaches'))
      learning_difference = RspecEncode.encode_description(title['learningdifference'])
    end

    e_pdp_info = super
    e_pdp_info[:content_type] = content_type
    e_pdp_info[:teaches] = teaches
    e_pdp_info[:learning_difference] = learning_difference
    e_pdp_info[:curriculum] = RspecEncode.normalizes_unexpected_characters(Title.english_to_french(title['curriculum'], 'curriculum'))
    e_pdp_info[:age] = Title.calculate_age_device(title['agefrommonths'], title['agetomonths'], 'fr')
    e_pdp_info[:skill] = Title.english_to_french(title['skills'], 'skill')
    e_pdp_info[:publisher] = Title.convert_french_moas_data(title['publisher'])
    e_pdp_info[:has_credit_link] = Title.english_to_french(title['contenttype'], 'contenttype') == 'Musique'

    e_pdp_info
  end

  def actual_pdp_product_info(pdp_info)
    super
  end
end
