require 'pages/subscription/common_page'

class AppCenterSbPage < CommonPage
  element :popup_title, 'p.popup__title'
  element :most_popular, '#MostPopular'
  element :expired_message, '#sbcrExpiredMessage'

  def choose_the_first_app
    page.execute_script("$('.pod__action.pod__action_download>img:eq(1)').trigger('click');")
  rescue => e
    e.message
  end

  def downloading_popup?
    has_popup_title?(wait: TimeOut::WAIT_CONTROL_CONST)
  end

  def most_popular?
    has_most_popular?(wait: TimeOut::WAIT_CONTROL_CONST)
  end

  def expired_message?
    has_expired_message?(wait: TimeOut::WAIT_CONTROL_CONST)
  end
end
