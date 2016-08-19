require 'pages/subscription/common_page'

class LogInPage < CommonPage
  element :email_txt, 'input[name="email"]'
  element :password_txt, 'input[name="password"]'
  element :my_membership_btn, '.goto-membership-page.button.button_primary'

  def log_in(username, password)
    email_txt.set username
    password_txt.set "#{password}\n"
  end

  def already_signed_up_popup?
    has_my_membership_btn?(wait: TimeOut::WAIT_CONTROL_CONST)
  end
end
