require 'site_prism'

class AtgDvStarterPage < SitePrism::Page
  def go_to_starter_page(url)
    visit url
  end

  def select_the_first_app_on_starter_page
    page.execute_script("$('.btn.btn-primary.btn-xs:eq(1)').click();")
  rescue => e
    e.message
  end
end
