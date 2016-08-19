$(document).ready(function () {
  $('#limit_log_paging_btn').click(function () {
    var $error_div = $('#limit_log_paging_msg');
    $error_div.empty();

    if (tc.custom.validateNumber($('#limit_log_paging'), 'Limit items', $error_div)) {
      return true;
    }

    return false;
  });
});
