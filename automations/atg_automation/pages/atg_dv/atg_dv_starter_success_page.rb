require 'site_prism'

class AtgDvStarterSuccessPage < SitePrism::Page
  set_url_matcher(%r{.*\/starter\/starterSuccess.jsp})

  def starter_success_page_exist?
    displayed?
  end
end
