class VinHomePage < SitePrism::Page
  element :contact_us_link, :xpath, ".//*[@id='searchBar']/a[1]"
  element :log_out_link, :xpath, ".//*[@id='searchBar']/a[2]"
end
