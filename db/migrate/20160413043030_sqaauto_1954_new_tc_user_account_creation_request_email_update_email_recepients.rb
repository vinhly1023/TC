class Sqaauto1954NewTcUserAccountCreationRequestEmailUpdateEmailRecepients < ActiveRecord::Migration
  def up
    say 'New TC User Account Creation Request Email - update email recipients'

    say 'De-active accounts: Peter Choi, Cedric Young and Kenny Shiu'
    update "UPDATE `users` SET `is_active` = 0 WHERE `email` = 'pchoi@leapfrog.com'"
    update "UPDATE `users` SET `is_active` = 0 WHERE `email` = 'cyoung@leapfrog.com'"
    update "UPDATE `users` SET `is_active` = 0 WHERE `email` = 'kshiu@leapfrog.com'"

    say 'Add new/Update existing accounts to ADMIN group: Alan Abar, Andrew Sonsten and Doraiah Vundavally'
    add_update_user 'Alan', 'Abar', 'aabar@leapfrog.com'
    add_update_user 'Andrew', 'Sonsten', 'Asonsten@leapfrog.com'
    add_update_user 'Doraiah', 'Vundavally', 'DVundavally@leapfrog.com'

    say 'Update password of existing accounts: Tin Trinh, Van Ngoc Nguyen, Vinh Ly and Thuong Dang'
    update "UPDATE `users` SET `password` = 'd33f1a6621f17e8090f8fb9c1b6b6f01' WHERE `email` = 'tin.trinh@logigear.com'"
    update "UPDATE `users` SET `password` = 'b0b9f909c3bcddc77f09151937ce3723' WHERE `email` = 'van.ngoc.nguyen@logigear.com'"
    update "UPDATE `users` SET `password` = '1d97ba3c1132b0b754d335263b9eaf99' WHERE `email` = 'vinh.ly@logigear.com'"
    update "UPDATE `users` SET `password` = '4607e782c4d86fd5364d7e4508bb10d9' WHERE `email` = 'thuong.dang@logigear.com'"
  end

  def add_update_user(f_name, l_name, email, password = 'e10adc3949ba59abbe56e057f20f883e', is_active = 1)
    user = User.find_by(email: email)
    if user
      user[:is_active] = 1
      user.save
      UserRoleMap.where(user_id: user[:id]).update_all(role_id: 1)
    else
      new_user = User.create(first_name: f_name, last_name: l_name, email: email, password: password, is_active: is_active)
      UserRoleMap.create(user_id: new_user[:id], role_id: 1) if new_user
    end
  end
end
