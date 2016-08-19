$LOAD_PATH.unshift('automations/lib')
require 'automation_common'

# Override Device Store data.xml
ATGConfiguration.override_atg_data('device_store' => 'LFC', 'payment_type' => 'Account Balance')

require_relative 'checkout_flow'

=begin
  LFC English check-out smoke test with Account Balance
=end

dv_checkout_flow URL::ATG_DV_APP_CENTER_URL % [General::ENV_CONST.downcase, General::LOCATION_URL_CONST], Account::EMAIL_GUEST_CONST
