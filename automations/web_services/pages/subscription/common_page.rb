require 'capybara'
require 'capybara/rspec'
require 'selenium-webdriver'
require 'site_prism'

class CommonPage < SitePrism::Page
  def load(url)
    visit url
  end
end
