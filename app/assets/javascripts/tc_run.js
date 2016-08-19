tc.using("tc.run", function () {
  var is_import_csv = false;
  var is_refresh_outpost = false;

  var showStatusBar = function (path) {
    fillStatus(path);
    setInterval(function () {
      fillStatus(path);
    }, 30000);
  };

  var validateEmail = function (element_id) {
    var $email_box = $(element_id);
    var emailRegex = /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i;

    if ($email_box.val().length) {
      var email_list = $email_box.val().split(/,|;/);
      for (var i = 0; i < email_list.length; i++) {
        if (email_list[i].match(emailRegex)) {
          $email_box.css({
            'border': '',
            'background': ''
          });
        } else {
          $email_box.css({
            'background': 'url(\'/assets/ui-bg_diagonals-thick_18_b81900_40x40.png\') repeat scroll 50% 50% #b81900',
            'border': '1px solid #cd0a0a',
            'color': '#fff'
          });
          $email_box.focus();

          return false;
        }
      }
    }
    return true;
  };

  var populateRepeat = function () {
    var $repeat_on = $('#repeat[value="on"]');
    var $repeat_area = $('.repeat_area');
    var $inputs = $repeat_area.find('input');
    var $buttons = $repeat_area.find('.btn');

    $repeat_on.attr('checked', false);
    $inputs.prop('disabled', true);
    $buttons.addClass('disabled');

    $repeat_on.click(function () {
      $inputs.prop('disabled', !$repeat_on.is(':checked'));
      $buttons.toggleClass('disabled');
    });
  };

  var refreshOutpostTestRun = function () {
    is_refresh_outpost = true;
    buildOutpostTestSuites();
  };

  var setReleaseDateBasedOnOutpost = function (outpost_id) {
    $.ajax({
      type: 'GET',
      url: '/outpost/release_date',
      data: { outpost_id: outpost_id },
      dataType: 'json',
      success: function (data) {
        if (data.status === true) {
          // set data for release_date_url hidden field
          $('#release_date_url').val(data.release_date_url);
        } else {
          alert('Cannot get release date from database');
        }
      },
      error: function () {
        alert('Error while getting release date from database');
      }
    });
  };

  var buildOutpostTestSuites = function () {
    $('#parent_suite').val('');
    var $test_suite = $('#test_suite');
    var outpost = $('label:has(input) > input[name="outpost"]:checked').val() || '';
    var mydata = {
      outpost: outpost,
      is_refresh_outpost: is_refresh_outpost
    };

    $.ajax({
      type: 'GET',
      url: '/outpost/test_suites',
      data: mydata,
      dataType: 'html',
      async: false,
      success: function (data) {
        // Load test suites
        $test_suite.empty();
        $test_suite.append(data);
        $('#test_suite_instruction_ctl').addClass('hidden');

        // Refresh Outpost test runs
        if (is_refresh_outpost) buildOutpostControls();
      },
      error: function () {
        $test_suite.empty();
        alert('Error while loading test suites!');
      }
    });
  };

  var testSuiteInstruction = function (outpost, test_suite) {
    $('#test_suite_instruction_ctl').addClass('hidden');
    if (outpost === null || test_suite === null || test_suite === '--- Select test suite ---') return false;

    $('#test_suite_name').text(test_suite);
    var mydata = {
      outpost: outpost,
      test_suite: test_suite
    };

    $.ajax({
      type: 'GET',
      url: '/outpost/test_suite_instruction',
      data: mydata,
      dataType: 'html',
      success: function (data) {
        if (data !== '') {
          $('#test_suite_instruction_ctl').removeClass('hidden');
          $('#test_suite_instruction').html(data);
        }
      },
      error: function () {
        $('#test_suite_instruction').html('Error while getting test suite instruction');
      }
    });
  };

  var buildOutpostControls = function () {
    var outpost = $('label:has(input) > input[name="outpost"]:checked').val() || '';
    var test_suite = $('#parent_suite').val() || $('#test_suite').val() || '';
    if (outpost === '' || test_suite === '') return false;

    var url = '/outpost/controls',
      mydata = {
      outpost: outpost,
      test_suite: test_suite
    };

    $.ajax({
      type: 'GET',
      url: url,
      data: mydata,
      dataType: 'html',
      async: false,
      success: function (data) {
        // Load Outpost controls
        $('#outposts-options').html(data);

        // Load Test cases
        if (is_refresh_outpost) buildOutpostTestCases();
      },
      error: function () {
        alert('Error while loading controls!');
      }
    });
  };

  var buildOutpostTestCases = function () {
    var $test_suite = $('#test_suite');
    var test_suite = $test_suite.val() || null;
    if (test_suite === null) return false;

    var outpost = $('label:has(input) > input[name="outpost"]:checked').val() || '';
    var mydata = {
      outpost: outpost,
      parent_suite: test_suite
    };

    $.ajax({
      type: 'GET',
      url: '/outpost/test_suites',
      data: mydata,
      dataType: 'html',
      async: false,
      success: function (data) {
        if (data !== '') {
          $test_suite.empty();
          $test_suite.append(data);
          $('#parent_suite').val(test_suite);
        }

        buildTCsFromTS();
      },
      error: function () {
        alert('Error while loading test suites!');
      }
    });
  };

  var buildTCsFromTS = function (ts_ctrl, tc_ctrl) {
    ts_ctrl = ts_ctrl || '#test_suite';
    tc_ctrl = tc_ctrl || '#testcase';
    var $test_suite = $(ts_ctrl);
    var $test_case = $(tc_ctrl);
    $test_case.empty();

    var test_suite = $('#test_suite').val();
    var parent_suite = $('#parent_suite').val() || null;
    var outpost = $('label:has(input) > input[name="outpost"]:checked').val() || '';
    var mydata = {
      outpost: outpost,
      test_suite: test_suite,
      parent_suite: parent_suite
    };

    $.ajax({
      type: 'GET',
      url: '/run/test_case_list',
      data: mydata,
      dataType: 'json',
      async: false,
      success: function (data) {
        $test_case.empty();
        var options = '',
          i = 0;

        if (test_suite === '--- All test suites ---') {
          $test_case.text('Run all test cases');
        } else if (data.length < 0) {
          $test_case.text('Please select a Test Suite');
        } else if (data[0] == 'folder_type') {
          for (i = 1; i < data.length; i++)
            options += '<option value="' + data[i][0] + '">' + data[i][1] + '</option>';

          $test_suite.empty();
          $test_suite.append(options);
          $test_case.empty();
        } else {
          for (i = 1; i < data.length; i++) {
            options += '<label><input type="checkbox" name="testrun[]" value=\"' + data[i][0] + '"/><span>' + i + '. ' + data[i][1] + '</span></label>';
          }

          $test_case.empty();
          $test_case.append(options);
        }

        is_refresh_outpost = false;
      },
      error: function () {
        alert('Error while loading test cases!');
      }
    });
  };

  var buildCreateTSModal = function () {
    $('#d_atgs').modal('show');

    // bind data to fields on dialog
    var request = atgGetTestSuites(),
      $existing_ts = $('#d_existing_ts');

    request.done(function (data) {
      var option = '';
      if (data[0] !== '') {
        for (var i = 0; i < data.length; i++) {
          option += '<option value=\'' + data[i][1] + '\'>' + (i + 1) + ' - ' + data[i][0] + '</option>';
        }
      }

      $existing_ts.empty();
      $existing_ts.append(option);

      // get test cases
      buildTCsFromTS('#d_existing_ts', '#d_testcase');
    });
    request.fail(function (jqXHR) {
      alert('Cannot get test suites\n' + jqXHR.responseText);
    });

    $existing_ts.change(function () {
      buildTCsFromTS('#d_existing_ts', '#d_testcase');
    });
  };

  var changeLocaleByTS = function (ts_id) {
    var request = atgGetParentSuiteId($(ts_id).val());
    request.done(function (data) {
      var ts_id_value = (data !== -1 && data.length > 0) ? data[0][0] : $(ts_id).val(),
        $ts_selected = $('#test_suite').find(':selected'),
        $release_cv = $('#release_cover'),
        $locale = $('#locale');

      //If TS = Heart Beat -> Hide the Locale combobox
      atgShowHideLocale(ts_id_value !== '50');
      atgShowHideDataDriven(ts_id_value === '60');
      atgShowHideDeviceStore(ts_id_value === '65');
      atgShowHideComServer(ts_id_value === '56');

      var label_parts = [
        '<label class="btn btn-default hidden-input"><input type="checkbox" name="locale[]" value="',
        '" /><span> ',
        '</span></label>'
      ];
      var locales = [];

      switch (ts_id_value) {
        case '45': // English ATG Web Content
        case '46': // English ATG Cabo Content
        case '52': // YMAL Checking
        case '62': // English ATG LeapPad Ultra Content
        case '64': // English ATG LFC Content
        case '48': // ATG Soft Good Smoke Test
        case '56':
          locales = ['US', 'CA', 'UK', 'IE', 'AU', 'ROW'];
          break;
        case '47': // French ATG Cabo Content
        case '67': // French ATG LFC Content
          locales = ['FR_FR', 'FR_CA', 'FR_ROW'];
          break;
        case '65': // Device Stores - Soft Good Smoke Test
          locales = ['US', 'CA', 'UK', 'IE', 'AU', 'ROW', 'FR_FR', 'FR_CA', 'FR_ROW'];
          break;
        default:
          locales = ['US', 'CA'];
      }

      var option_locale = '';
      for (var i = 0; i < locales.length; i++) {
        option_locale += label_parts[0] + locales[i] + label_parts[1] + locales[i] + label_parts[2];
      }
      $locale.html(option_locale);

      //If TS = HeartBeat => Set default locale is US
      if (ts_id_value === '50') $locale.find(':nth-child(2)').prop('selected', true);

      // display release day
      var content_index = $ts_selected.text().toLowerCase().indexOf('content');
      var ymal_index = $ts_selected.text().toLowerCase().indexOf('ymal');
      if (content_index !== -1 || ymal_index !== -1) {
        $release_cv.show();
      } else {
        $release_cv.hide();
      }
    });
  };

  var loadReleaseDateByTS = function loadReleaseDateByTS() {
    var silo = $("#silo input[type='radio']:checked").val().toUpperCase(),
      $test_suite = $('#test_suite').find(':selected'),
      language = 'EN';

    if ($test_suite.text().toLowerCase().indexOf('french atg') !== -1) language = 'FR';
    var my_data = {
      'silo': silo,
      'language': language
    };

    $.ajax({
      type: 'GET',
      url: '/atg/release_date',
      data: my_data,
      dataType: 'html',
      success: function (data) {
        $('#release_date_opts').html(data);
      },
      error: function () {
        alert('Error while loading release dates');
      }
    });
  };

  var loadReleaseDateOutpost = function loadReleaseDateOutpost() {
    var release_date_endpoint = $('#release_date_url').val();
    if (release_date_endpoint === '') return;

    var outpost_name = $('#outpost>.active>span').text().toLowerCase();
    var test_suite = $('#test_suite :selected').val();

    $.ajax({
      type: 'POST',
      url: release_date_endpoint,
      data: { test_suite: test_suite },
      async: false,
      dataType: 'json',
      crossDomain: true,
      success: function (data) {
        var release_date = data.release_date;
        var options = '';

        for (var i = 0; i < release_date.length; i++) {
          options += '<li><label><input type="checkbox" value="' + release_date[i].date + '" onclick="tc.run.clickReleaseDate(this);"><span>' + release_date[i].date + ' - Total: ' + release_date[i].quantity + ' app(s)</span></label></li>';
        }

        $('#release_date_' + outpost_name + '_opts').html(options);
      },
      error: function (jqXHR) {
        alert(jqXHR.responseText);
      }
    });
  };

  var rerunTest = function (run_data_ele) {
    var run_data_val = $(run_data_ele).val();

    if (run_data_val !== undefined && run_data_val.trim !== '') {
      try {
        loadComponentBySilo(true, JSON.parse(run_data_val));
      } catch (err) {}
    }
  };

  var atgCreateNewTestSuite = function () {
    var $tcs = $('#d_testcase').find('input:checkbox:checked'),
      $tsId = $('#d_existing_ts'),
      $eTestSuites = $tsId.find('option'),
      $tsName = $('#tsname');
    var valid = atgCheckTestSuiteName($tsName, $eTestSuites, $tcs);
    if (valid) {
      var opt_vals = '';
      $tcs.map(function () {
        opt_vals = opt_vals + ($(this).val()) + ',';
      });
      var myData = {
        'tsname': $tsName.val(),
        'tcs': opt_vals,
        'tsId': $tsId.val()
      };

      $.ajax({
        type: 'GET',
        url: '/atgs/ajax/create_ts',
        data: myData,
        dataType: 'json',
        success: function () {
          location.reload();
        },
        error: function () {
          alert('Fail to create new Test Suite');
        }
      });
    }
    return valid;
  };

  // For WS
  var back = function () {
    $.ajax({
      type: 'GET',
      url: '/web_services/back',
      data: null,
      dataType: 'json',
      success: function (data) {
        var $tsuite = $('#test_suite');
        $tsuite.empty();
        if (data.length === 0) return;

        var option_list = '';
        for (var i = 0; i < data.length; i++) {
          if (Array.isArray(data[i])) {
            option_list += '<option value="' + data[i][1] + '">' + data[i][0] + '</option>';
          } else {
            option_list += '<option>' + data[i] + '</option>';
          }
        }
        $tsuite.append(option_list);
        $('#testcase').empty();
      },
      error: function () {
        alert('error');
      }
    });
  };

  // For export and import run config data-drive
  var exportToCSV = function () {
    var request = atgGetParentSuiteId($('#test_suite :selected').val());
    request.done(function (data) {
      var silo = $("#silo input[type='radio']:checked").val();
      var locale = $('#locale :input:checkbox:checked').map(function () {
        return this.value;
      }).get().join(";") || '';

      var env = $("input[type='radio'][name='env']:checked").val() || '',
        release_date = $("#release_date").val() || '',
        browser = $("#webdriver input[type='radio']:checked").val() || '',
        selected_ts_name = $('#test_suite :selected').text();

      var device_store = $('#device_store .active input').map(function () {
        return this.value;
      }).get().join(';');

      var payment_type = $('#payment_type .active input').map(function () {
        return this.value;
      }).get().join(';');

      if (data !== -1 && data.length > 0) selected_ts_name = data[0][1] + '/' + selected_ts_name;

      var test_suite = ignoreCommas(selected_ts_name);
      var testcase = ignoreCommas($('#testcase :checkbox:checked').map(function () {
        return $(this).next("span").text();
      }).get().join(";"));

      var run_info = {
        silo: silo,
        env: env,
        locale: locale,
        release_date: release_date,
        browser: browser,
        device_store: device_store,
        payment_type: payment_type,
        test_suite: test_suite,
        testcase: testcase
      };

      var columns = ['silo', 'env', 'locale', 'release_date', 'browser', 'device_store', 'payment_type', 'test_suite', 'testcase'],
        csvContent = "data:text/csv;charset=utf-8,";
      csvContent += columns.join(',') + "\n";
      csvContent += columns.map(function (a) {
        return run_info[a];
      }).join(',');

      var encodedUri = encodeURI(csvContent);
      var a = document.createElement('a');
      a.style.display = 'none';
      a.download = 'exported-data.csv';
      a.href = encodedUri;
      document.body.appendChild(a);
      a.click();
    });
    request.fail(function () {
      alert('Fail to get run config data!');
    });
  };

  var importFromCSV = function (evt) {
    var file = evt.target.files[0];
    Papa.parse(file, {
      header: true,
      dynamicTyping: true,
      complete: function (results) {
        var run_info = getRunInfoFromCSV(results.data[0]);
        var current_silo = $("#silo input[type='radio']:checked").val();

        // Bind data into RUN fields
        if (current_silo != run_info.silo) is_import_csv = true;
        $('#silo').find("label:has(input[value='" + run_info.silo + "'])").click();
        loadComponentBySilo(true, run_info);
      },
      error: function () {
        alert('Failed to load file!');
      }
    });
  };

  var clickReleaseDate = function clickReleaseDate(element) {
    var op_suffix = outpostSuffix();
    var $release_date_chk = $('ul#release_date' + op_suffix + '_opts input[type=checkbox]');
    if (element.value === 'ALL') {
      if (element.checked) {
        selectReleaseDate($release_date_chk, true, 'ALL');
      } else {
        selectReleaseDate($release_date_chk, false, '');
      }
    } else {
      var is_all_checked = true,
        release_str = '';

      for (var x = 0; x < $release_date_chk.length; x++) {
        if ($release_date_chk[x].checked) {
          release_str += $release_date_chk[x].value + ';';
        } else if ($release_date_chk[x].value !== 'ALL') {
          is_all_checked = false;
        }
      }

      if (is_all_checked) {
        selectReleaseDate($release_date_chk, true, 'ALL');
      } else {
        var $all_release_date_chk = $('ul#release_date' + op_suffix + '_opts input[value=ALL]');
        $($all_release_date_chk).prop('checked', false);
        $('#release_date' + op_suffix).val(release_str.substring(0, release_str.length - 1).replace('ALL;', ''));
      }
    }
  };

  var outpostSuffix = function () {
    var op_suffix = '',
      op_name = $('#outpost>.active>span').text().toLowerCase();

    if (op_name !== '') op_suffix = '_' + op_name;
    return op_suffix;
  };

  var selectReleaseDate = function selectReleaseDate($element, status, text) {
    $element.prop('checked', status);
    var op_suffix = tc.run.outpostSuffix();
    $('#release_date' + op_suffix).val(text);
  };

  function atgShowHideLocale(is_show) {
    var $locale = $('#locale'),
      $locale_all = $('#locale_all'),
      $label_locale = $('label[for="locale"]');
    if (is_show) {
      $locale.show();
      $locale_all.show();
      $label_locale.show();
    } else {
      $locale.hide();
      $locale_all.hide();
      $label_locale.hide();
    }
  }

  function atgShowHideDataDriven(is_show) {
    var $data_driven = $('#data_driven_csv'),
      $label_data_driven = $('.data_driven_csv');
    if (is_show) {
      $data_driven.show();
      $label_data_driven.show();
    } else {
      $data_driven.hide();
      $label_data_driven.hide();
    }
  }

  function atgShowHideDeviceStore(is_show) {
    var $device_store = $('#device_store_cover');
    if (is_show) {
      $device_store.show();
    } else {
      $device_store.hide();
    }
  }

  function atgShowHideComServer(is_show) {
    var $com_server = $('#com_server'),
      $label_com_server = $('label[for="com_server"]');
    if (is_show) {
      $com_server.show();
      $label_com_server.show();
    } else {
      $com_server.hide();
      $label_com_server.hide();
    }
  }

  function atgCheckTestSuiteName(tsName, eTestSuites) {
    var flag = true,
      testSuites = eTestSuites.toArray();
    testSuites.forEach(function (entry) {
      var entry_str = $(entry).text().split('-')[1].trim();
      if (entry_str.toUpperCase() === tsName.val().trim().toUpperCase()) flag = false;
    });

    if (flag === false) {
      tsName.css({
        'background': 'url(\'/assets/ui-bg_diagonals-thick_18_b81900_40x40.png\') repeat scroll 50% 50% #b81900',
        'border': '1px solid #cd0a0a',
        'color': '#fff'
      });
      tsName.val('Suite should be unique');
    }
    return flag;
  }

  function atgGetTestSuites() {
    return $.ajax({
      type: 'GET',
      url: '/atg/first_parent_level_tss',
      dataType: 'json'
    });
  }

  function atgGetParentSuiteId(testSuiteId) {
    var myData = {
      'ts_id': testSuiteId
    };

    return $.ajax({
      type: 'GET',
      url: '/atg/parent_suite_id',
      data: myData,
      dataType: 'json'
    });
  }

  function ignoreCommas(str) {
    return str.indexOf(',') > -1 ? '"' + str + '"' : str;
  }

  function getRunInfoFromCSV(data) {
    var run_info = {};
    for (var key in data) {
      if (data[key] === undefined || data[key].trim() === '') continue;

      run_info[key] = data[key];
    }

    return run_info;
  }

  function loadComponentBySilo(is_imported_from_csv, run_info) {
    var $component = $('#component');
    $component.load('/run/show_run_silo/' + run_info.silo, function (status, xhr) {
      if (status == 'error') {
        $component.html('Sorry but there was an error: ' + xhr.status + ' ' + xhr.statusText);
        return;
      }

      changeLocaleByTS('#test_suite');
      buildTCsFromTS();
      populateRepeat();
      loadReleaseDateByTS();
      loadReleaseDateOutpost();

      if (is_imported_from_csv === false) return;

      var t = 0,
        ts_arr = run_info.test_suite.split('/');
      $.each(ts_arr, function (index, ts) {
        setTimeout(function () {
          var $test_suite = $("#test_suite");
          $test_suite.val($("#test_suite option:contains('" + ts + "')").val());
          $test_suite.change();
        }, t += 500);
      });

      setTimeout(function () {
        if (run_info.env !== '') $('#env').find("label:has(input[value='" + run_info.env + "'])").click();
        if (run_info.browser !== '') $('#webdriver').find("label:has(input[value='" + run_info.browser + "'])").click();
        if (run_info.release_date !== '') $("#release_date").val(run_info.release_date);

        findAndClickLabels('#locale', run_info.locale);
        findAndClickLabels('#device_store', run_info.device_store);
        findAndClickLabels('#payment_type', run_info.payment_type);
        findAndClickLabels('#testcase', run_info.testcase);
      }, (ts_arr.length + 1) * 500);
    });
  }

  function loadViewResultBySilo(silo, view_path) {
    var $component = $('#view_result_component');
    $component.load('/run/show_view_silo/' + silo + '/view' + view_path, function (status, xhr) {
      if (status == 'error') alert('Error while loading results: ' + xhr.status + ' ' + xhr.statusText);
    });
  }

  function findAndClickLabels(jquery_path, values) {
    if (jquery_path === undefined || values === undefined) return;

    var label_values = values.split(';');
    var has_element = $(jquery_path).find("label input[value='" + label_values[0] + "']").length > 0 || $(jquery_path).find("label:contains('" + label_values[0] + "')").length > 0,
      element;

    if (has_element) {
      try {
        label_values.forEach(function (value) {
          element = $(jquery_path).find("label input[value='" + value.trim() + "']");
          if (element.length > 0) element.click();
          else $(jquery_path).find("label:contains('" + value.trim() + "')").click();
        });
      } catch (err) {}
    } else {
      window.setTimeout(function () {
        try {
          label_values.forEach(function (value) {
            element = $(jquery_path).find("label input[value='" + value.trim() + "']");
            if (element.length > 0) element.click();
            else $(jquery_path).find("label:contains('" + value.trim() + "')").click();
          });
        } catch (err) {}
      }, 500);
    }
  }

  function fillStatus(path) {
    var status = $('#run_status');
    var running = status.find('#srunning');
    var queued = status.find('#squeued');
    var today = status.find('#sdaily');
    var scheduled = status.find('#sscheduled');
    var outpost = status.find('#soutpost');

    $.get(path, function (data) {
      running.text(data.running);
      queued.text(data.queued);
      today.text(data.today);
      scheduled.text(data.scheduled);
      outpost.text(data.outpost);
    });
  }

  return {
    showStatusBar: showStatusBar,
    validateEmail: validateEmail,
    populateRepeat: populateRepeat,
    buildTCsFromTS: buildTCsFromTS,
    exportToCSV: exportToCSV,
    importFromCSV: importFromCSV,
    is_import_csv: is_import_csv,
    changeLocaleByTS: changeLocaleByTS,
    buildCreateTSModal: buildCreateTSModal,
    loadComponentBySilo: loadComponentBySilo,
    loadViewResultBySilo: loadViewResultBySilo,
    atgCreateNewTestSuite: atgCreateNewTestSuite,
    loadReleaseDateByTS: loadReleaseDateByTS,
    loadReleaseDateOutpost: loadReleaseDateOutpost,
    buildOutpostTestSuites: buildOutpostTestSuites,
    buildOutpostTestCases: buildOutpostTestCases,
    buildOutpostControls: buildOutpostControls,
    refreshOutpostTestRun: refreshOutpostTestRun,
    setReleaseDateBasedOnOutpost: setReleaseDateBasedOnOutpost,
    back: back,
    rerunTest: rerunTest,
    testSuiteInstruction: testSuiteInstruction,
    outpostSuffix: outpostSuffix,
    clickReleaseDate: clickReleaseDate,
    selectReleaseDate: selectReleaseDate
  };
}());
