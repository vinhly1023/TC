//= require papaparse

$(document).ready(function () {
  var $body = $('body');

  // Load View result by Silo
  loadViewResult();

  // Load Run content base on browser history
  if (history.pushState) {
    window.addEventListener('popstate', function () {
      var silo = '';
      var path = location.pathname;
      var run_index = path.indexOf('/run');

      if (run_index == -1) {
        loadViewResult();
        silo = path.slice(1, path.indexOf('/view'));
      } else {
        silo = path.slice(1, run_index);
        tc.run.loadComponentBySilo(false, {silo: silo});
      }

      // Set selected Silo and active class
      $('#silo').find("label:has(input[value='" + silo + "']) > input").prop('checked', true);
      $('label:has(input:checked)').addClass('active');
      $('label:has(input:not(:checked))').removeClass('active');
    });
  }

  // click to select silo on New run page
  $body.on('change', '#new_run label:has(input) > input[name="silo"]', function () {
    var silo = $('#silo').find('label:has(input:checked) > input').val().trim();
    changeUrlBySilo(silo, 'run');

    if (tc.run.is_import_csv) {
      tc.run.is_import_csv = false;
    } else {
      tc.run.loadComponentBySilo(false, {silo: silo});
    }
  });

  // click to select silo on View results page
  $body.on('change', '#view_result label:has(input) > input[name="silo"]', function () {
    var silo = $('#silo').find('label:has(input:checked) > input').val().trim();
    changeUrlBySilo(silo, 'view');
    loadViewResult();
  });

  // click to select Outpost
  $body.on('change', 'label:has(input) > input[name="outpost"]', function () {
    var silo = $('#silo>.active>span').text();

    if (silo.toLocaleLowerCase() === 'accr') {
      tc.run.setReleaseDateBasedOnOutpost(this.value);
    }
    tc.run.refreshOutpostTestRun();
  });

  // change test suites
  $body.on('change', '#test_suite', function () {
    var outpost = $('label:has(input) > input[name="outpost"]:checked').val() || null;
    var $test_suite = $('#test_suite');
    if (outpost === null) {
      if ($test_suite.val() === 'new_test_suite') tc.run.buildCreateTSModal();
      tc.run.changeLocaleByTS('#test_suite');
      tc.run.loadReleaseDateByTS();
      tc.run.buildTCsFromTS();
    } else {
      tc.run.testSuiteInstruction(outpost, $test_suite.val() || null);
      tc.run.buildOutpostControls();
      tc.run.buildOutpostTestCases();
      tc.run.loadReleaseDateOutpost();
    }
  });

  // click to select locales, device stores, payment types
  $body.on('click', '.select_all label > input', function () {
    var name, select_all_name;

    if (this.value === 'all') {
      select_all_name = this.name;
      name = select_all_name.replace('_all', '[]');

      if ($('label:has(input[name="' + select_all_name + '"]) > input').is(':checked')) {
        $('label:has(input) > input[name="' + name + '"]:not(:checked)').click();
      } else {
        $('label:has(input) > input[name="' + name + '"]:checked').click();
      }
    } else {
      name = this.name;
      select_all_name = name.replace('[]', '_all');

      var $lbl_all_obj = $('label:has(input[name="' + select_all_name + '"])'),
        $ip_all_obj = $('label:has(input[name="' + select_all_name + '"]) > input');

      if ($('label:has(input) > input[name="' + name + '"]:not(:checked)').length > 0) {
        $lbl_all_obj.removeClass('active');
        $ip_all_obj.removeAttr('checked');
      } else {
        $lbl_all_obj.addClass('active');
        $ip_all_obj.prop('checked', true);
      }
    }
  });

  // click to select release checkboxes (USE FOR TEST CENTRAL)
  $body.on('click', 'ul#release_date_opts input[type=checkbox]', function () {
    var $release_date_chk = $('ul#release_date_opts input[type=checkbox]');
    if (releaseDateValue(this) === 'ALL') {
      if ($(this).is(':checked')) {
        tc.run.selectReleaseDate($release_date_chk, true, 'ALL');
      } else {
        tc.run.selectReleaseDate($release_date_chk, false, '');
      }
    } else {
      var is_all_checked = true,
        release_str = '';

      for (var x = 0; x < $release_date_chk.length; x++) {
        if ($($release_date_chk[x]).is(':checked')) {
          release_str += releaseDateValue($release_date_chk[x]) + ';';
        } else if (releaseDateValue($release_date_chk[x]) !== 'ALL') {
          is_all_checked = false;
        }
      }

      if (is_all_checked) {
        tc.run.selectReleaseDate($release_date_chk, true, 'ALL');
      } else {
        var $all_release_date_chk = $('ul#release_date_opts input[value=ALL]');
        $($all_release_date_chk).prop('checked', false);
        $('#release_date').val(release_str.substring(0, release_str.length - 1).replace('ALL;', ''));
      }
    }
  });

  // change release date (USE FOR BOTH TC AND OUTPOST)
  $body.on('change', 'ul[id^=release_date]', function () {
    var op_suffix = tc.run.outpostSuffix();
    var release_str = $('#release_date' + op_suffix).val().toUpperCase();
    var $release_date_chk = $('ul#release_date' + op_suffix + '_opts input[type=checkbox]');

    if (release_str === 'ALL') {
      tc.run.selectReleaseDate($release_date_chk, true, release_str);
    } else if (release_str === '') {
      tc.run.selectReleaseDate($release_date_chk, false, release_str);
    } else {
      var arr = release_str.split(';');
      for (var x = 0; x < $release_date_chk.length; x++) {
        if (arr.indexOf($release_date_chk[x].value) === -1) {
          $($release_date_chk[x]).prop('checked', false);
        } else {
          $($release_date_chk[x]).prop('checked', true);
        }
      }
    }

    if (areAllReleaseDatesChecked()) {
      tc.run.selectReleaseDate($release_date_chk, true, 'ALL');
    }

    $('input[id^=release_date][type=text]').change();
  });

  $body.on('change', 'input[id^=release_date][type=text]', function () {
    $('#' + this.id).removeClass('run_info_error');
  });

  // continue show Release date dropdown
  $body.on('click', 'ul.dropdown-menu>li>label', function (e) {
    e.stopPropagation();
  });

  // import run config CSV file
  $body.on('change', '#csv-file', tc.run.importFromCSV);

  // click on running note on ATG page
  $body.on('click', '#atg_running_note', function () {
    $('#atg_running_note_content').modal('show');
  });

  // click to create new test suite
  $body.on('click', '#dAtgSubmit', function () {
    if (!(tc.custom.validateData('#tsname') && tc.custom.validateData('#d_testcase'))) return false;
    tc.run.atgCreateNewTestSuite();
  });

  // click to add run to queue
  $body.on('click', 'input[value="QUEUE"]', function () {
    var status,
      defaults = ['#test_suite', '#testcase', '#note', '#user_email'];

    status = tc.run.validateEmail('#user_email');
    for (var i = 0; i < defaults.length; i++) {
      status = tc.custom.validateData(defaults[i]) && status
    }

    var silo = $('#silo').find('label:has(input:checked) > input').val().toLowerCase();
    if (silo === 'tc') return status;

    if ($('#outpost>.active>span').text() === '') {
      var options = ['#env', '#webdriver', '#locale', '#language', '#release_date', '#data_driven_csv', '#device_store', '#payment_type'];
      for (var x = 0; x < options.length; x++) {
        status = runValidateData(options[x]) && status;
      }
    } else {
      status = validateOutpostControls() && status
    }

    return status;
  });

  $body.on ('click', '#outposts-options input', function(){
    var id = this.parentNode.parentNode.id;
    if (id === '') return;
    $('#' + id + ' > label').removeClass('run_info_error');
    $('#' + id + '_all > label').removeClass('run_info_error');
  });

  $body.on('click', '.delete', function () {
    return confirm("Are you sure you want to delete?");
  });

  $body.on('click', '#re_run_lnk', function () {
    $('#btn_run_data').click();
  });

  tc.run.rerunTest('#run_data');

  function clearValidation(element) {
    $(element).change(function () {
      $(element).removeClass('run_info_error');
    });
  }

  function changeUrlBySilo(silo, page) {
    if (typeof (history.pushState) === 'undefined') {
      alert('Browser does not support HTML5.');
    } else {
      var url = location.protocol + '//' + location.hostname + (location.port ? ':' + location.port : '') + '/' + silo + '/' + page;
      var obj = { title: '', url: url };
      history.pushState(obj, obj.title, obj.url);
    }
  }

  function loadViewResult() {
    var path = location.pathname,
      view_index = path.indexOf('/view');
    var silo = path.slice(1, view_index),
      view_path = path.slice(view_index + 5, path.length);

    tc.run.loadViewResultBySilo(silo, view_path);
  }

  function areAllReleaseDatesChecked() {
    var op_suffix = tc.run.outpostSuffix();
    var $release_date_chk = $('ul#release_date' + op_suffix + '_opts input[type=checkbox]');

    for (var x = 1; x < $release_date_chk.length; x++) {
      if ($($release_date_chk[x]).is(':checked') === false) return false;
    }

    return true;
  }

  function isRealObject(obj) {
    return obj && obj !== null && obj !== undefined && obj.length !== 0;
  }

  function runValidateData(element_id) {
    var $object = $(element_id);
    if (element_id === '#release_date') $object = $('#release_cover');
    if (isRealObject($object) && $object.css('display') !== 'none') return tc.custom.validateData(element_id);
    return true;
  }

  function validateOutpostControls() {
    var $outpost_controls  = $('#outposts-options .form-group');
    var $text_controls, $radio_controls, $checkbox_controls;
    var status = true;

    for (var x = 0; x < $outpost_controls.length; x++) {
      $text_controls = $($outpost_controls[x]).find(':input:text');
      if ($text_controls.length > 0) {
        var temp = true;

        for (var i = 0; i < $text_controls.length; i++) {
          if ($text_controls[i].value === '') {
            status = false;
            temp = false;
            $text_controls.addClass('run_info_error');
            break;
          }
        }
        if (temp) $text_controls.removeClass('run_info_error');

        continue;
      }

      $radio_controls = $($outpost_controls[x]).find(':input:radio');
      if ($radio_controls.length > 0) {
        if ($radio_controls.filter(':checked').length === 0){
          status = false;
          $radio_controls.parent().addClass('run_info_error');
        } else {
          $radio_controls.parent().removeClass('run_info_error');
        }

        continue;
      }

      $checkbox_controls = $($outpost_controls[x]).find(':input:checkbox');
      if ($checkbox_controls.length > 0) {
        if ($checkbox_controls.filter(':checked').length === 0){
          status = false;
          $checkbox_controls.parent().addClass('run_info_error');
        } else {
          $checkbox_controls.parent().removeClass('run_info_error');
        }

        continue;
      }
    }

    return status;
  }

  function releaseDateValue($element) {
    return $($element).val();
  }

  // clear validation
  clearValidation('#env>label');
  clearValidation('#locale>label');
  clearValidation('#webdriver>label');
  clearValidation('#release_date');
  clearValidation('#test_suite');
  clearValidation('#testcase');
});
