require File.expand_path('../../spec_helper', __FILE__)

=begin
Smoke test: Verify OOBE flow Bogota device works correctly
=end

describe "TS19 - OOBE Smoke Test - Bogota - #{Misc::CONST_ENV}" do
  # Device info variable
  e_child_name = 'BogotaKid'
  platform = 'leappadplatinum'
  device_name = 'BOGOTA'
  package_id = 'PHRS-0x00280011-000000' # Elements on the Loose

  # run test
  web_services_smoke_test(e_child_name, device_name, platform, package_id)
end
