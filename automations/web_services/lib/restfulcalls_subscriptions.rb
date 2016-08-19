require 'net/http'
require 'net/https'
require 'openssl'
require 'uri'
require 'json'
require 'rest-client'

def login_sub_account(email, password)
  params = { 'login' => email, 'password' => password }
  header = { 'Content-Type' => 'application/x-www-form-urlencoded' }
  url_login = "#{LFREST::CONST_SUB_ENDPOINT}#{LFRESOURCES::CONST_SUB_LOGIN}"
  rest_call_login(url_login, params, header)
end

def cancel_membership(email, password)
  login_response = login_sub_account(email, password)
  url_cancel = "#{LFREST::CONST_SUB_ENDPOINT}#{LFRESOURCES::CONST_SUB_CANCEL_MEMBERSHIP}"
  response = rest_call_cancel_restart(url_cancel, login_response[:cookies])
  JSON.parse(response.body)
end

def restart_membership(email, password)
  login_response = login_sub_account(email, password)
  url_cancel = "#{LFREST::CONST_SUB_ENDPOINT}#{LFRESOURCES::CONST_SUB_RESTART_MEMBERSHIP}"
  response = rest_call_cancel_restart(url_cancel, login_response[:cookies])
  JSON.parse(response.body)
end

def rest_call_login(url, params, header)
  request = RestClient::Request.new(
    method: :post,
    url: url,
    headers: header,
    payload: params,
    verify_ssl: OpenSSL::SSL::VERIFY_NONE
  )

  res = request.execute

  { body: JSON.parse(res.body), cookies: res.cookies }
end

def rest_call_cancel_restart(url, cookies)
  RestClient.get(url, cookies: cookies)
end
