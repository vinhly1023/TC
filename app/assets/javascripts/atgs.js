$(document).ready(function () {
  var $body = $('body');
  $body.on('change', function () {
    var $pin_type = $('#pin_type'),
      $pin_file = $('.code_file_cover').find('input[type="text"]');

    if ($pin_type.val() !== '--- Select a code type ---') $pin_type.removeClass('run_info_error');
    if ($pin_file.val() !== '') $pin_file.removeClass('run_info_error');
  });
});

function clean_pins() {
  var request = $.ajax({
    type: 'POST',
    url: '/atgs/clean_pins',
    data: {},
    dataType: 'html'
  });

  $('.glb-loader').show();

  request.done(function (data) {
    $('.glb-loader').hide();
    var $pin_type_list = $('table.available_pins tbody');
    $pin_type_list.empty();
    $pin_type_list.html(data);
  });

  request.fail(function (jqXHR) {
    $('.glb-loader').hide();
    alert(jqXHR.responseText);
  });
}
