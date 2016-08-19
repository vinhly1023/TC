require 'pages/csc/csc_home_page'

class CSCLoginPage < SitePrism::Page
  set_url URL::CSC_CONST

  element :username_input, '#username'
  element :password_input, '#password'
  element :login_btn, '#loginFormSubmit'
  element :username_label, "#loginForm>fieldset>ul>li>label[for='username']"
  element :password_label, "#loginForm>fieldset>ul>li>label[for='password']"

  def login(username, password)
    username_input.set username
    password_input.set password
    login_btn.click

    CSCHomePage.new
  end
end
