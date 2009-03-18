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
  $('input[title]').each(function() { $(this).watermark({'cls': 'watermark', 'html': this.title}) })
  $('input.auto_focus').each(function() { $(this).focus() ; return false })
  $.datepicker.setDefaults({ numberOfMonths: 2, showButtonPanel: true, dateFormat: $.datepicker.RSS });
  $('input.date').datepicker();
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
