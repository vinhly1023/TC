require 'pages/subscription/common_page'

class ConfirmationPage < CommonPage
  set_url_matcher(%r{.*\/subscription\/confirmation.jsp})

  def confirmation_page_exist?
    displayed?
  end
end
