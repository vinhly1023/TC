tc.using('tc.custom', function () {
  // When clicking on radio button or checkbox in btn-group
  $(document).ready(function () {
    var onResize = function() {
      // apply dynamic padding at the top of the body according to the fixed navbar height
      $('body').css('padding-top', $('.navbar-fixed-top').height());
    };

    $(window).resize(onResize);

    onResize();

    var $body = $('body');
    $body.on('change', function () {
      $('label:has(input:checked)').addClass('active');
      $('label:has(input:not(:checked))').removeClass('active');

      var element_ids = ['#env', '#webdriver', '#locale', '#language', '#release_date', '#device_store', '#payment_type', '#type_pin'];
      for (var i = 0; i < element_ids.length; i++) {
        removeErrorClass(element_ids[i]);
      }

      if ($('#test_suite > option:selected').text().indexOf('Select') == -1) $('#test_suite').removeClass('run_info_error');
      if ($('#testcase > label:has(input:checked)').length > 0) $('#testcase').removeClass('run_info_error');

      var releaseVal = $('#release_date').val() || '';
      if (releaseVal.match(/^([1-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9])$/)) $('#release_date').removeClass('run_info_error');
    });

    $body.on('change', '.btn-file :file', function () {
      var $input = $(this),
        $text = $input.parents('.input-group').find(':text'),
        numFiles = $input.get(0).files ? $input.get(0).files.length : 1,
        label = $input.val().replace(/\\/g, '/').replace(/.*\//, ''),
        log = numFiles > 1 ? numFiles + ' files selected' : label;

      if ($text.length) {
        $text.val(log);
      } else if (log) {
        alert(log);
      }
    });

    $('.js-validate-env-locale').click(validateEnvLocale);
    $('.js-validate-redeem-pin').click(validateRedeemPin);
    $('.js-validate-uploaded-pin').click(validateUploadRedeemCode);

    tc.run.showStatusBar('/run/status');
  });

  function removeErrorClass(element_id) {
    if (element_id === '#release_date') {
      var $element = $('#release_date');
      if ($element.val() !== '') $element.removeClass('run_info_error');
      return;
    }

    var $input_selection = $(element_id + ' > label:has(input:checked)');
    $input_selection.removeClass('run_info_error');
    if ($input_selection.length !== 0) $(element_id + ' > label:has(input:not(:checked))').removeClass('run_info_error');
  }

  // Validate uploaded PIN: Code Type and Code File
  var validateUploadRedeemCode = function () {
    var $pin_type = $('#pin_type'),
      $pin_file = $('.code_file_cover').find('input[type="text"]');
    var pin_type_status = true,
      pin_file_status = true;

    if ($pin_type.val() === '--- Select a code type ---') {
      $pin_type.addClass('run_info_error');
      pin_type_status = false;
    } else {
      $pin_type.removeClass('run_info_error');
    }

    if ($pin_file.val() === '') {
      $pin_file.addClass('run_info_error');
      pin_file_status = false;
    } else {
      $pin_file.removeClass('run_info_error');
    }

    return pin_type_status && pin_file_status;
  };

  // Validate env and locale
  var validateEnvLocale = function () {
    var env = validateData('#env'),
      locale = validateData('#locale') || true;
    return env && locale;
  };

  var validateRedeemPin = function () {
    var pin_type = validateData('#type_pin'),
      email = validateData('#email');
    return pin_type && email;
  };

  // Add or remove run_info_error class
  function addErrorClass($element, is_add) {
    if (is_add) {
      $element.addClass('run_info_error');
    } else {
      $element.removeClass('run_info_error');
    }
  }

  // Validate function for all silos
  var validateData = function (element_name) {
    var $element = $(element_name);

    switch (element_name) {
      case '#test_suite':
        if ($element.val().trim() === '--- Select test suite ---' || $element.val().trim() === '') {
          addErrorClass($element, true);
          return false;
        } else {
          addErrorClass($element, false);
        }
        break;
      case '#testcase':
        if ($('#test_suite :checked').text() === '--- All test suites ---') {
          return true;
        } else if ($('#testcase input:checkbox:checked').length === 0) {
          addErrorClass($element, true);
          return false;
        } else {
          addErrorClass($element, false);
        }
        break;
      case '#d_testcase':
        if ($('#d_testcase input:checkbox:checked').length === 0) {
          addErrorClass($element, true);
          return false;
        } else {
          addErrorClass($element, false);
        }
        break;
      case '#env':
        $element = $(element_name + '>label');
        if ($('#env input:radio:checked').length === 0) {
          addErrorClass($element, true);
          return false;
        } else {
          addErrorClass($element, false);
        }
        break;
      case '#webdriver':
        $element = $(element_name + '>label');
        if ($('#webdriver input:radio:checked').length === 0) {
          addErrorClass($element, true);
          return false;
        } else {
          addErrorClass($element, false);
        }
        break;
      case '#language':
        $element = $(element_name + '>label');
        if ($('#language input:radio:checked').length === 0) {
          addErrorClass($element, true);
          return false;
        } else {
          addErrorClass($element, false);
        }
        break;
      case '#locale':
        $element = $(element_name + '>label');
        if ($('#locale').is(':visible') === true && ($('#locale input:checkbox:checked').length === 0 && $('#locale input:radio:checked').length === 0)) {
          addErrorClass($element, true);
          return false;
        } else {
          addErrorClass($element, false);
        }
        break;
      case '#release_date':
        var release_date = $element.val(),
          release_date_reg = /^([1-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9])$/,
          release_date_arr = release_date.split(';');

        if (release_date !== 'ALL') {
          for (var i = 0; i < release_date_arr.length; i++) {
            if (!release_date_arr[i].match(release_date_reg)) {
              addErrorClass($element, true);
              return false;
            }
          }
        }
        addErrorClass($element, false);
        break;
      case '#note':
        if ($element.val().length > 255) {
          addErrorClass($element, true);
          return false;
        } else {
          addErrorClass($element, false);
        }
        break;
      case '#data_driven_csv':
        var $input = $('.data_driven_csv').find('input[type="text"]');
        if ($element.val() === '') {
          addErrorClass($input, true);
          return false;
        } else {
          addErrorClass($input, false);
        }
        break;
      case '#type_pin':
        $element = $(element_name + '>label');
        if ($('#type_pin input:radio:checked').length === 0) {
          addErrorClass($element, true);
          return false;
        } else {
          addErrorClass($element, false);
        }
        break;
      case '#email':
        var email = $element.val(),
          emailRegex = /^([a-zA-Z0-9_\.\-\+])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/;

        if (email.match(emailRegex)) {
          addErrorClass($element, false);
        } else {
          addErrorClass($element, true);
          return false;
        }
        break;
      case '#device_store':
        $element = $(element_name + '>label');
        if ($('#device_store').is(':visible') === true && $('#device_store input:checkbox:checked').length === 0) {
          addErrorClass($element, true);
          return false;
        } else {
          addErrorClass($element, false);
        }
        break;
      case '#payment_type':
        $element = $(element_name + '>label');
        if ($('#payment_type').is(':visible') === true && $('#payment_type input:checkbox:checked').length === 0) {
          addErrorClass($element, true);
          return false;
        } else {
          addErrorClass($element, false);
        }
        break;
      default:
        if ($element.val().trim() === '') {
          addErrorClass($element, true);
          return false;
        } else {
          addErrorClass($element, false);
        }
    }
    return true;
  };

  /**
   * Validate input control as a number and in [min, max].
   * @param {control} $ele - The unique input control with min and max attribute.
   * @param {string} name - The name which describe control, the name is used to show on the GUI.
   * @param {control} $error_div - The control which is used to display message.
   */
  var validateNumber = function ($ele, name, $error_div) {
    var number = $ele.val();
    number = $.isNumeric(number) ? parseInt(number) : -1;

    var min = parseInt($ele.attr('min')),
      max = parseInt($ele.attr('max')),
      minMaxErr = number > max || number < min;

    if (number === -1) {
      appendErrorMsg(name + ', please enter a number!', $error_div);
      return false;
    }
    else if (minMaxErr) {
      appendErrorMsg(name + ', must be between ' + min + ' and ' + max, $error_div);
      return false;
    }
    return true;
  };

  function appendErrorMsg(msg, $error_div) {
    $error_div.append('<div class="alert alert-error">' + msg + '</div>');
    $('.glb-loader').hide();
  }

  return { validateData: validateData, validateNumber: validateNumber };
}());
