$(document).ready(function () {
  var $body = $('body');
  $body.on('change', function () {
    var $pin_type = $('#pin_type'),
      $pin_file = $('.code_file_cover').find('input[type="text"]');

    if ($pin_type.val() !== '--- Select a code type ---') $pin_type.removeClass('run_info_error');
    if ($pin_file.val() !== '') $pin_file.removeClass('run_info_error');
  });

  $('label:has(input) > input[name="outpost"]').click(function () {
    $('#reload_outpost').click();
  });

  $('#btn_update').click(function () {
    var $fileName = $('#file_name'),
      $fileContent = $('#txt_file_content');

    if (validateContent($fileName, $fileContent) === false) return;

    var url = '/outpost/update_file',
      data = {
        file_name: $fileName.text(),
        content: $fileContent.val(),
        upload_url: $('#upload_url').val()
      };

    $.ajax({
      type: 'POST',
      url: url,
      data: data,
      dataType: 'JSON',
      success: function (data) {
        alert(data.message);
        $('#mdl_edit_file').modal('hide');
        window.location.href = "";
      },
      error: function () {
        alert("Exception while requesting!");
      }
    });
  });

  function validateContent(txtFileName, txtFileContent) {
    var fileExt = txtFileName.text().split('.').pop().toLowerCase(),
      fileContent = txtFileContent.val();
    try {
      switch (fileExt) {
        case 'json':
          jQuery.parseJSON(fileContent);
          break;
        case 'xml':
          jQuery.parseXML(fileContent);
          break;
      }
    } catch (err) {
      alert("The content is invalid:\n" + err.message);
      return false;
    }

    return true;
  }

  $('#btn_op_run_queue_settings').click(function () {
    var $limit_running_ctrl = $('#limit_running_test'),
      $error_div = $('#op_run_queue_settings_msg');

    $('.glb-loader').show();
    $error_div.empty();

    if (tc.custom.validateNumber($limit_running_ctrl, 'limit_running', $error_div)) {
      updateLimitRunning($limit_running_ctrl.val(), $('#outpost>.active>input').val(), $error_div);
    }
  });

  function updateLimitRunning(limitRunning, outpostName, $messageDiv) {
    var myData = {
      limitRunning: limitRunning,
      name: outpostName
    };
    var request = $.ajax({
      type: 'POST',
      url: '/outpost/update_limit_running',
      data: myData,
      dataType: 'html'
    });
    request.done(function (data) {
      $messageDiv.html(data);
      $('.glb-loader').hide();
    });
    request.error(function () {
      $messageDiv.html('<div class="alert alert-error">Fail to update</div>');
      $('.glb-loader').hide();
    });
  }

  $('#btn_op_clean_pins').click(function () {
    var $glb_loader = $('.glb-loader');
    var clean_pin_endpoint = $('#clean_pins_url').val();
    $glb_loader.show();

    $.ajax({
      type: 'POST',
      url: clean_pin_endpoint,
      data: {},
      async: true,
      dataType: 'json',
      crossDomain: true,
      success: function (data) {
        $glb_loader.hide();
        var pins = data['available_pins'];
        var pin_html = '';
        for (var i = 0; i < pins.length; i++)
          pin_html += '<tr class="bout"><td>' + pins[i]['type'] + '</td><td>' + pins[i]['qa'] + '</td><td>' + pins[i]['prod'] + '</td><td>' + pins[i]['staging'] + '</td></tr>';

        var $pin_type_list = $('table.available_pins tbody');
        $pin_type_list.empty();
        $pin_type_list.html(pin_html);
      },
      error: function (jqXHR) {
        $glb_loader.hide();
        alert(jqXHR.responseText);
      }
    });
  });
});
