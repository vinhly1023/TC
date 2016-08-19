$(document).ready(function () {
  $('#fetch_status').click(function () {
    var env = $('input[name="env"]:checked').val();
    if (env !== undefined) {
      $('.glb-loader').show();
    }
  });

  var status_pin_form = $('.form-horizontal');

  status_pin_form.on('ajax:success', function (event, data, status, xhr) {
    $('#pins_status').html(data);
    $('.glb-loader').hide();
  });

  status_pin_form.on('ajax:error', function (event, data, status, xhr) {
    $('#pins_status').html('<p class=\'alert alert-error\'>' + xhr.responseText + '</p>');
    $('.glb-loader').hide();
  });
});
