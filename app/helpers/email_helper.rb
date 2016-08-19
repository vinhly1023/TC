module EmailHelper
  def email_image_tag(image, **options)
    attachments['image'] = {
      data: image,
      mine_type: 'image/png'
    }

    image_tag attachments['image'].url, **options
  end
end
