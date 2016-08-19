require 'capybara'
require 'capybara/rspec'
require 'selenium-webdriver'
require 'site_prism'

class RegisterDevice < SitePrism::Section
  element :device_serial_txt, '.regCodeTextInputSmall'
  element :act_code_txt, '.regCodeTextInput'
  element :submit_btn, '#btnSubmitForm'
  element :regcode_div, '#body_container_regcode'
  element :regcode_title, '.regcode_title'
end

class Login < SitePrism::Section
  element :create_account_btn, '#btnCreateAccount'
  element :email_txt, '#email'
  element :password_txt, '#password'
  element :login_btn, '#btnSubmitForm'
  element :title, :xpath, "(.//div[@class='standard_title'])[1]"
end

class CreateParentLock < SitePrism::Section
  element :pin1_txt, '#inputCode1'
  element :next1_btn, '#btnStep1'
  element :pin2_txt, '#inputCode2'
  element :next2_btn, '#btnStep2'
  element :next3_btn, '#btnStep3'
  element :step1_title, :xpath, ".//*[@id='step1']/div[@class='standard_title']"
end

class CreateAccount < SitePrism::Section
  element :first_name_txt, :xpath, ".//*[@id='parentFirstName']"
  element :last_name_txt, :xpath, ".//input[@name = 'parentLastName']"
  element :email_txt, :xpath, ".//input[@name = 'email']"
  element :confirm_email_txt, :xpath, ".//input[@name = 'emailConfirm']"
  element :password_txt, :xpath, ".//input[@name = 'password']"
  element :confirm_password_txt, :xpath, ".//input[@name = 'passwordConfirm']"
  element :zipcode_txt, :xpath, ".//input[@name = 'zipcode']"
  element :year_txt, :xpath, ".//*[@id='birth_year']"
  element :country_txt, :xpath, ".//*[@id='country']"
  element :submit_btn, '#btnSubmitForm'
end

class CreateProfile < SitePrism::Section
  element :first_name_txt, '.enter_key_trigger_submit'
  element :gender_cbo, '#gender'
  element :grade_cbo, '#grade_level'
  element :month_cbo, '#birth_month'
  element :day_cbo, '#birth_day'
  element :year_cbo, '#birth_year'
  element :save_btn, '#btnSubmitForm'
  element :create_another_profile_btn, '#btnCreateAnotherProfile'
  element :done_btn, '#btnDone'
  element :registration_complete_lbl, '.appcenter_title'
  element :title, :xpath, "(.//div[@class='login_title'])[1]"
end

class GlasGowPage < SitePrism::Page
  section :register_form, RegisterDevice, '#body_container_regcode'
  section :login_form, Login, '#body_container'
  section :create_parent_lock_form, CreateParentLock, '#body_container'
  section :create_profile_form, CreateProfile, '#body_container'
  section :create_account_form, CreateAccount, '#body_container'
  element :registration_complete_lbl, '.appcenter_title'
  element :act_code_txt, '#body_container_regcode .regCodeTextInput'

  def load(url)
    visit url
  end

  def register_device(device_serial)
    register_form.device_serial_txt.set device_serial
    page.find('#btnSubmitForm', wait: TimeOut::WAIT_SMALL_CONST).click
    has_act_code_txt?(wait: TimeOut::WAIT_10_SECONDS_CONST)
  end

  def submit_act_code(act_code)
    act = register_form.act_code_txt.value
    register_form.act_code_txt.set act_code unless act == act_code
    page.find('#btnSubmitForm', wait: TimeOut::WAIT_SMALL_CONST).click
    sleep TimeOut::WAIT_SMALL_CONST
  end

  def create_new_account(data)
    login_form.create_account_btn.click if login_form.has_create_account_btn?(wait: TimeOut::WAIT_SMALL_CONST)

    create_account_form.first_name_txt.set data[:first_name]
    create_account_form.last_name_txt.set data[:last_name]
    create_account_form.email_txt.set data[:email]
    create_account_form.confirm_email_txt.set data[:confirm_email]
    create_account_form.password_txt.set data[:password]
    create_account_form.confirm_password_txt.set data[:confirm_password]
    create_account_form.zipcode_txt.set data[:zip_code]
    create_account_form.year_txt.select data[:year]
    create_account_form.country_txt.select data[:locale]

    create_account_form.submit_btn.click
  end

  def login_account(username, password)
    login_form.email_txt.set username
    login_form.password_txt.set password
    login_form.login_btn.click
  end

  def create_parent_pin(pin)
    create_parent_lock_form.pin1_txt.set pin
    create_parent_lock_form.next1_btn.click

    create_parent_lock_form.pin2_txt.set pin
    create_parent_lock_form.next2_btn.click

    create_parent_lock_form.next3_btn.click
    sleep TimeOut::WAIT_SMALL_CONST
  end

  def enter_profile_info(profile_info)
    create_profile_form.first_name_txt.set profile_info[:name]
    create_profile_form.gender_cbo.select profile_info[:gender]
    create_profile_form.grade_cbo.select profile_info[:grade]
    create_profile_form.month_cbo.select profile_info[:month]
    create_profile_form.day_cbo.select profile_info[:day]
    create_profile_form.year_cbo.select profile_info[:year]

    create_profile_form.save_btn.click
    sleep TimeOut::WAIT_SMALL_CONST
  end

  def create_maximum_child_profile
    i = 0
    profile_arr = []

    while !has_registration_complete_lbl? && i < 10
      profile_arr.push create_profiles i

      sleep TimeOut::WAIT_SMALL_CONST
      i += 1
    end

    profile_arr
  end

  def create_random_child_profile
    profile_arr = []

    profile_arr.push(create_profiles 0, false)
  end

  def create_profiles(index, multiple = true)
    name = 'profile' + index.to_s
    gender = %w(Boy Girl)[rand(0..1)]
    grade = ['Early Pre-K', 'Pre-K', 'Kindergarten', '1st', '2nd', '3rd', '4th', '5th', '6th'][rand(0..8)]
    month = %w(January February March April May June July August September October November December)[rand(0..11)]
    day = rand(1..29).to_s
    year = rand(2006..2015).to_s

    profile_info = { name: name, gender: gender, grade: grade, month: month, day: day, year: year }

    create_profile_form.create_another_profile_btn.click if multiple && create_profile_form.has_create_another_profile_btn?

    enter_profile_info profile_info if create_profile_form.has_first_name_txt?

    { slot: index.to_s, name: name, gender: gender_mapping(gender), grade: grade_mapping(grade), dob: dob_mapping(month, day, year) }
  end

  # This method is used to map gender value that entered with database value
  # Boy -> male, Girl -> female
  def gender_mapping(gender)
    return 'male' if gender == 'Boy'
    'female'
  end

  # This method is used to map grade value that entered with database value
  # E.g. 'Early Pre-K' -> '2', '6th' -> 10
  def grade_mapping(grade)
    grade_arr = ['Early Pre-K', 'Pre-K', 'Kindergarten', '1st', '2nd', '3rd', '4th', '5th', '6th']
    ((grade_arr.index grade) + 2).to_s
  end

  # This method is used to generate and mappe DOB value that entered with database value
  # e.g. '2014-10-04'
  def dob_mapping(month, day, year)
    month_arr = %w(January February March April May June July August September October November December)
    m_str = ((month_arr.index month) + 1).to_s
    m = (m_str.length > 1) ? m_str : '0' + m_str
    d = (day.length > 1) ? day : '0' + day
    y = year

    y + '-' + m + '-' + d
  end
end
