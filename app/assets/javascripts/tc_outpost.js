tc.using('tc.outpost', function () {
  var upload = function (file) {
    var url = $('#upload_url').val() + file;
    popupGenericDialog(url, 700, 500);
  };

  var loadFileContent = function (file) {
    var $fileContent = $("#txt_file_content");

    $('#mdl_edit_file').modal('show');
    $('#file_name').text(file);
    $fileContent.empty();

    var url = '/outpost/file_content',
      data = {
        url: $('#download_url').val() + file
      };

    $.ajax({
      type: 'GET',
      url: url,
      data: data,
      dataType: 'text',
      success: function (data) {
        $fileContent.html(data);
      },
      error: function () {
        $fileContent.html("Error while getting file content!");
        $fileContent.prop("disabled", true);
        $('#btn_update').hide();
      }
    });
  };

  function popupWindow(strURL, strWindowName, iWidth, iHeight) {
    var objWindow = null;
    if (strURL !== "") {
      objWindow = window.top.open(strURL, strWindowName, 'status=yes,toolbar=no,location=no,scrollbars=yes,resizable=yes,width=' + iWidth + ',height=' + iHeight);
      var winTimer = window.setInterval(function () {
        if (objWindow.closed) {
          location.reload();
          window.clearInterval(winTimer);
        }
      }, 200);

      try {
        objWindow.focus();
      }
      catch (e) {
        objWindow.close();
        objWindow = window.top.open(strURL, strWindowName, 'toolbar=no,location=no,scrollbars=yes,resizable=yes,width=' + iWidth + ',height=' + iHeight);
        objWindow.focus();
      }
    }
  }

  function popupGenericDialog(strURL, iWidth, iHeight) {
    return popupWindow(strURL, "Upload file", iWidth, iHeight);
  }

  return {
    upload: upload,
    loadFileContent: loadFileContent
  };
}());
