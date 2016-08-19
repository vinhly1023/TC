$(document).ready(function () {
  // Load results base on the Cookies
  select_filter_options();

  // Click on Refresh Outpost link
  $('#refresh_outpost').click(function () {
    var request = $.ajax({
      type: 'GET',
      url: '/outpost/refresh',
      dataType: 'JSON'
    });

    request.done(function () {
      location.reload();
    });

    request.error(function () {
      alert('Failed to refresh. Please try again later!');
    });

    return false;
  });

  // Handle select/unselect of ALL button
  $('.filter-list label input[name="all"]').click(function () {
    var section = this.closest('div').id;
    var filter_css = '.filter-list#' + section + ' label input[name="filter"]';

    if (this.checked) {
      $(filter_css).prop('checked', true);
    } else {
      $(filter_css).prop('checked', false);
    }

    var options = {
      queued: filter_options('queued'),
      recent: filter_options('recent'),
      scheduled: filter_options('scheduled')
    };
    Cookies.set('options', options, { expires: 7 });

    filter_results(section, options[section]);
  });

  // Handle select/unselect of each filter option
  $('.filter-list label input[name="filter"]').click(function () {
    var section = this.closest('div').id;
    var $all_ele = $('.filter-list#' + section + ' label input[name="all"]');
    var filter_css = '.filter-list#' + section + ' label input[name="filter"]';

    if ($(filter_css + ':not(:checked)').length > 0) {
      $all_ele.prop('checked', false);
    } else {
      $all_ele.prop('checked', true);
    }

    var options = {
      queued: filter_options('queued'),
      recent: filter_options('recent'),
      scheduled: filter_options('scheduled')
    };
    Cookies.set('options', options, { expires: 7 });

    filter_results(section, options[section]);
  });
});

function refreshEnv() {
  $('.glb-loader-small').css('display', 'block');
  $.ajax({
    type: 'GET',
    url: '/dashboard/refresh_env',
    dataType: 'json',
    success: function () {
      location.reload();
    },
    error: function () {
      $('.glb-loader-small').css('display', 'none');
      alert('Failed to refresh');
    }
  });
}

function deleteOutpost(id, silo) {
  var cf = confirm('Are you sure you want to delete?');
  if (cf) {
    var myData = {
      id: id
    };

    var request = $.ajax({
      type: 'POST',
      url: '/outpost/delete',
      data: myData,
      dataType: 'JSON'
    });

    request.done(function () {
      var isRpCol = $('#outpost_' + id + '  > td[rowspan]').size() !== 0 && $('#outpost_' + id).next().attr('data-outpost-silo') === silo,
        rp = $('tr[data-outpost-silo="' + silo + '"]').size() - 1,
        $op_removed = $('#outpost_' + id);

      if (isRpCol) {
        $op_removed.next().children().first().before('<td rowspan="' + rp + '">' + silo + '</td>');
        $op_removed.remove();
      }
      else {
        $('tr[data-outpost-silo="' + silo + '"]' + ' > td[rowspan]').prop('rowspan', rp);
        $op_removed.remove();
      }
    });

    request.error(function () {
      alert('Failed to delete. Please try again!');
    });
  }
}

function filter_options(section) {
  if ($('.filter-list#' + section + ' label input[name="all"]').is(':checked')) return 'ALL';

  var silo_list = [];
  $('.filter-list#' + section + ' label input[name="filter"]').each(function () {
    if ($(this).is(':checked')) silo_list.push(this.id.replace(section + '_', ''));
  });

  return silo_list;
}

function select_filter_options() {
  var filter_options = Cookies.get('options');
  if (filter_options === undefined) return;

  var options = JSON.parse(filter_options);
  $.each(options, function (k, v) {
    if (v === 'ALL') {
      $('.filter-list#' + k + ' label input').prop('checked', true);
    } else {
      $('.filter-list#' + k + ' label input').prop('checked', false);
      for (var i = 0; i < v.length; i++) {
        $('.filter-list#' + k + ' label input[id="' + k + '_' + v[i] + '"]').prop('checked', true);
      }
    }

    $('.filter-list#' + k + ' label:has(input:checked)').addClass('active');
    $('.filter-list#' + k + ' label:has(input:not(:checked))').removeClass('active');

    filter_results(k, v);
  });
}

function filter_results(section, silo_list) {
  var request = $.ajax({
    type: 'GET',
    url: '/dashboard/filter_results',
    dataType: 'html',
    data: {
      section: section,
      silo: silo_list
    }
  });

  request.done(function (data) {
    var $filter_results = $('table tbody#' + section + '_results');
    $filter_results.empty();
    $filter_results.html(data);
  });
}
