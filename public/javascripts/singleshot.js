/*
 * Singleshot  Copyright (C) 2008-2009  Intalio, Inc
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


$(function() {
  // Form fields watermark and auto focus.
  $('input[type=text], input[type=password], textarea').each(function() { $(this).watermark({'cls': 'watermark', 'html': this.title}) })
  $('input.auto_focus:first').focus();
  // Sparkline bars.
  $('.sparkline.bar').each(function() {
    var values = $($(this).text().split(',')).each(function() { parseInt(this, 10) });
    $(this).show().sparkline(values, { height:'1em', chartRangeMin:0, type: 'bar', barColor: '#8fafff' });
  });
  // Form datepicked control.
  $.datepicker.setDefaults({ numberOfMonths: 2, showButtonPanel: true, dateFormat: $.datepicker.RSS });
  $('input.date').datepicker();

  // Expand/collapse options in task view.
  $('a.dropdown').click(function(e) {
    var target = $($(this).attr('href'));
    var highlight = $(this).parent();
    if (target.is(':visible')) {
      target.slideUp(250, function() { highlight.removeClass('active') });
    } else {
      highlight.addClass('active');
      target.slideDown(250);
    }
    $(this).blur();
    return false;
  });

  // Adjust iframe to fit window on creation and whenever browser window is resized.
  $('#task_frame').each(function() {
    var frame = $(this);
    //$(window).bind('resize load', function() { frame.height(window.innerHeight - frame.offset().top) })
  });

  // Form controls disabled for everyone but owner.
  $('form#task.disabled').find('input, select, textarea, button').attr('disabled', true);
})


var Singleshot = {
  makeTopFrame: function() {
    var to = window.location.href;
    if (top.location != to)
      top.location = to;
  },

  populateForm: function(form, data, prefix) {
    var form = $(form);
    prefix = prefix || 'task'
    for (key in data) {
      var value = data[key];
      var input = form.find('input[name=' + prefix + '[' + key + ']]');
      if (value instanceof Date) {
        input.datepicker('setDate', value);
      } else if (value instanceof Object) {
        populateForm(form, prefix + '[' + key + ']', value)
      } else {
        switch(input.attr('type')) {
          case 'radio':
            input.attr('checked', value.toString() == input.val())
          default:
            input.val(value)
        }
      }
    }
  }
}
