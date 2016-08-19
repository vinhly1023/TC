$(document).ready(function () {
  children();
  devices();
  apps();
  link_devices();
  unlink_devices();
  revoke_license();
  show_hide_manual_linking();
  update_customer();
});

function show_hide_manual_linking() {
  $('#atg_ld_autolink').click(function () {
    $('.manual').slideUp();
  });

  $('#atg_ld_noautolink').click(function () {
    $('.manual').slideDown();
  });

  $('#user_email').val($('#username').val());
  $('#user_password').val($('#password').val());
}

function children() {
  $('#children_info .ajax-loader').show();
  var url = '/accounts/children';
  var mydata = {
    'cus_id': $('#cus_id').val()
  };
  var i = 0, tr = '';
  $.ajax({
    type: 'GET',
    url: url,
    data: mydata,
    dataType: 'json',
    success: function (data) {
      for (i = 0; i < data.length; i++) {
        /*jshint multistr: true */
        tr += '<tr id="' + data[i].id + '" class="anchor">\
                <td>' + (i + 1) + '</td>\
                <td>' + data[i].id + '</td>\
                <td>' + data[i].name + '</td>\
                <td>' + data[i].grade + '</td>\
                <td>' + data[i].gender + '</td>\
                <td>' + data[i].dob + '</td>\
              </tr>';
      }
      $('#children_info table').append(tr);
      $('#children_info .ajax-loader').hide();
    },
    error: function (jqXHR) {
      $('#children_info .ajax-loader').hide();
      $('#children_info table').html('<div class=\'alert alert-error\'>' + jqXHR.responseText + '</div>');
    }
  });
}

function devices() {
  $('#devices_info .ajax-loader').show();
  var url = '/accounts/devices';
  var i = 0, tr = '';
  $.ajax({
    type: 'GET',
    url: url,
    dataType: 'json',
    success: function (data) {
      if (data.length === 0) {
        $('#devices_info table').html('There is no device in this account.');
      } else {
        for (i = 0; i < data.length; i++) {
          /*jshint multistr: true */
          tr += '<tr>\
                <td class="td_center"><input type="checkbox" name="devices[]" value="' + data[i].serial + '"/></td>\
                <td>' + (i + 1) + '</td>\
                <td>' + data[i].serial + '</td>\
                <td>' + data[i].platform + '</td>\
                <td>' + data[i].profiles + '</td>\
              </tr>';
        }
        $('#devices_info table tbody').html(tr);
        $('#devices_info .submit').html('<input class="btn btn-success" type="submit" onclick=\'$("#devices_info .ajax-loader").show();\' value="Un-link" name="commit">');
      }
      $('#devices_info .ajax-loader').hide();
    },
    error: function (jqXHR) {
      $('#devices_info .ajax-loader').hide();
      $('#devices_info table').html('<div class=\'alert alert-error\'>' + jqXHR.responseText + '</div>');
    }
  });
}

function apps() {
  $('#app_history_info .ajax-loader').show();
  $('#revoke_license .ajax-loader').show();
  var url = '/accounts/app_history';
  var mydata = {
    'cus_id': $('#cus_id').val()
  };
  var i = 0, j = 0, tr = '',
    el = '<div class="ajax-loader"></div>',
    app, apps, device_info, rs, value,
    licenses, license;
  $.ajax({
    type: 'GET',
    url: url,
    data: mydata,
    dataType: 'json',
    success: function (data) {
      apps = data.apps;
      for (i = 0; i < apps.length; i++) {
        app = apps[i];
        device_info = app.device_info;
        rs = device_info.length;
        if (rs === 0) {
          rs = 1;
        }
        /*jshint multistr: true */
        tr += '<tr id="' + app.license_id + '">\
                <td rowspan=' + rs + '>' + (i + 1) + '</td>\
                <td rowspan=' + rs + '>' + app.app_name + '</td>\
                <td rowspan=' + rs + '>' + app.sku + '</td>\
                <td rowspan=' + rs + '>' + app.type + '</td>\
                <td rowspan=' + rs + '>' + app.grant_date + '</td>\
                <td>' + ((device_info.length === 0) ? '' : device_info[0].device_serial) + '</td>\
                <td>' + ((device_info.length === 0) ? '' : device_info[0].package_id) + '</td>\
                <td>' + ((device_info.length === 0) ? '' : device_info[0].status) + '</td>\
                <td>';
        if (device_info.length !== 0) {
          if (device_info[0].status == 'installed') {
            tr += '<a data-remote="true" onclick="apps();" href="/accounts/remove_license?device_serial=' + device_info[0].device_serial + '&sku=' + app.sku + '&slot=' + device_info[0].slot + '">remove</a>';
          }
          else {
            tr += '<a data-remote="true" onclick="apps();" href="/accounts/report_installation?device_serial=' + device_info[0].device_serial + '&sku=' + app.sku + '&license_id=' + app.license_id + '">install</a>';
          }
        }

        tr += '</td></tr>';
        device_info.shift();
        for (j = 0; j < device_info.length; j++) {
          value = device_info[j];
          tr += '<tr>\
          <td>' + value.device_serial + '</td>\
          <td>' + value.package_id + '</td>\
          <td>' + value.status + '</td>\
          <td>';
          if (value.status == 'installed') {
            tr += '<a data-remote="true" onclick="apps();" href="/accounts/remove_license?device_serial=' + value.device_serial + '&sku=' + app.sku + '&slot=' + value.slot + '">remove</a>';
          }
          else {
            tr += '<a data-remote="true" onclick="apps();" href="/accounts/report_installation?device_serial=' + value.device_serial + '&sku=' + app.sku + '&license_id=' + app.license_id + '">install</a>';
          }
          tr += '</td></tr>';
        }
      }
      $('#app_history_info table tbody').html(tr);

      if (apps.length === 0) {
        $('#app_history_info table').html('There is no app in this account.');
      }

      // show revoke device license
      licenses = data.revoke_license;
      for (i = 0; i < licenses.length; i++) {
        license = licenses[i];
        el += '<label>\
                <input type="checkbox" name="revoke_licenses[]" value="' + license[1] + '">\
                <span>' + (i + 1) + '. ' + license[0] + '</span>\
              </label>';
      }
      if (licenses.length === 0) {
        el += 'There is no license to revoke';
      } else {
        el += '<input type="submit" name="commit" value="Revoke license" class="btn btn-success" onclick=\'$("#revoke_license .ajax-loader").show();\'>';
      }

      $('#revoke_license').html(el);
      $('#app_history_info .ajax-loader').hide();
      $('#revoke_license .ajax-loader').hide();
    },
    error: function (jqXHR) {
      $('#app_history_info .ajax-loader').hide();
      $('#revoke_license .ajax-loader').hide();
      $('#app_history_info table').html('<div class=\'alert alert-error\'>' + jqXHR.responseText + '</div>');
    }
  });
}

function link_devices() {
  $("input[value='Link device']").click(function () {
    // Validate Env
    if ($('#env input:radio:checked').length === 0) {
      return false;
    }

    // Validate Email
    var emailRegex = /^([a-zA-Z0-9_\.\-\+])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/;
    var $email = $('#atg_ld_email');
    if ($email.val().match(emailRegex)) {
      mark_control_status($email, 'valid');
    } else {
      mark_control_status($email, 'invalid');
      return false;
    }

    // Validate Password
    var $password = $('#atg_ld_password');
    if ($password.val() === '') {
      mark_control_status($password, 'invalid');
      return false;
    } else {
      mark_control_status($password, 'valid');
    }

    // Validate Device serial
    var $device_serial = $('#atg_ld_deviceserial');
    if ($('.manual').css('display') === 'block') {
      if ($device_serial.val() === '') {
        mark_control_status($device_serial, 'invalid');
        return false;
      } else {
        mark_control_status($device_serial, 'valid');
      }
    }

    // Show loading indicator
    $('.glb-loader').show();

    // specify method
    var url = '/accounts/process_linking_devices';
    var mydata = {
      'atg_ld_email': $email.val(),
      'atg_ld_password': $password.val(),
      'atg_ld_platform': $('#atg_ld_platform').val(),
      'atg_ld_env': $('#env label input:radio:checked').val(),
      'atg_ld_autolink': $("#atg_ld_autolink").is(":checked"),
      'atg_ld_children': $('#atg_ld_children').val(),
      'atg_ld_deviceserial': $device_serial.val()
    };

    $.ajax({
      type: 'GET',
      url: url,
      data: mydata,
      dataType: 'json',
      success: function () {
        $('.glb-loader').hide();
        $('#ld_msg').html('<div class=\'alert alert-success\'>Your account is linked to devices successfully!</div>');
      },
      error: function (jqXHR) {
        $('.glb-loader').hide();
        $('#ld_msg').html('<div class=\'alert alert-error\'>Error while linking device: ' + jqXHR.responseText + '</div>');
      }
    });
  });
}

function unlink_devices() {
  $('#devices_info').parent().on('ajax:success', function (event, data, status, xhr) {
    $('.alert.alert-error').remove();
    devices();
  });

  $('#devices_info').parent().on('ajax:error', function (event, data, status, xhr) {
    $('.alert.alert-error').remove();
    $('#devices_info .ajax-loader').hide();
    $('#devices_info table').append('<div class=\'alert alert-error\'>' + xhr.responseText + '</div>');
  });
}

function revoke_license() {
  $('#revoke_license').parent().on('ajax:success', function (event, data, status, xhr) {
    $('.alert.alert-error').remove();
    apps();
  });

  $('#revoke_license').parent().on('ajax:error', function (event, data, status, xhr) {
    $( ".alert.alert-error" ).remove();
    $('#app_history_info .ajax-loader').hide();
    $('#revoke_license .ajax-loader').hide();
    $('#revoke_license').append('<div class=\'alert alert-error\'>' + xhr.responseText + '</div>');

  });
}

function update_customer() {
  $('#cus_info form').on('ajax:success', function (event, data, status, xhr) {
    $('.alert.alert-error').remove();
    $('#cus_info .ajax-loader').hide();
  })

  $('#cus_info form').on('ajax:error', function (event, data, status, xhr) {
    $( ".alert.alert-error" ).remove();
    $('#cus_info .ajax-loader').hide();
    $('#cus_info').append('<div class=\'alert alert-error\'>' + xhr.responseText + '</div>');
  })
}

function mark_control_status($element, status) {
  if (status === 'invalid') {
    $element.css({
      'background': 'url(\'/assets/ui-bg_diagonals-thick_18_b81900_40x40.png\') repeat scroll 50% 50% #b81900',
      'border': '1px solid #cd0a0a',
      'color': '#fff'
    });
    $element.focus();
  } else {
    $element.css({
      'border': '',
      'background': '',
      'color': '#000'
    });
  }
}
