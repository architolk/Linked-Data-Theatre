/*
 * NAME     chosen.ajax.js
 * VERSION  1.19.0
 * DATE     2017-10-16
 *
 * Copyright 2012-2017
 *
 * This file is part of the Linked Data Theatre.
 *
 * The Linked Data Theatre is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Linked Data Theatre is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Linked Data Theatre.  If not, see <http://www.gnu.org/licenses/>.
 */
/*
 * DESCRIPTION
 * Javascript to support ajax in chosen.
 * Based on https://github.com/meltingice/ajax-chosen, changed to fit LDT and latest version of chosen.js
 *
 */
(function($) {
  return $.fn.ajaxChosen = function(settings, callback, chosenOptions) {
    var chosenXhr, defaultOptions, options, select;
    if (settings == null) {
      settings = {};
    }
    if (chosenOptions == null) {
      chosenOptions = {};
    }
    defaultOptions = {
      minTermLength: 3,
      afterTypeDelay: 500,
      jsonTermKey: "term",
      keepTypingMsg: "Keep typing...",
      lookingForMsg: "Looking for"
    };
    select = this;
    chosenXhr = null;
    options = $.extend({}, defaultOptions, $(select).data(), settings);
    this.chosen(chosenOptions ? chosenOptions : {});
    return this.each(function() {
      return $(this).next('.chosen-container').find(".search-field > input, .chzn-search > input").bind('keyup', function() {
        var field, msg, success, untrimmed_val, val;
        untrimmed_val = $(this).val();
        val = $.trim($(this).val());
        msg = val.length < options.minTermLength ? options.keepTypingMsg : options.lookingForMsg + (" '" + val + "'");
        select.next('.chosen-container').find('.no-results').text(msg);
        if (val === $(this).data('prevVal')) {
          return false;
        }
        $(this).data('prevVal', val);
        if (this.timer) {
          clearTimeout(this.timer);
        }
        if (val.length < options.minTermLength) {
          return false;
        }
        field = $(this);
        if (options.data == null) {
          options.data = {};
        }
        options.data[options.jsonTermKey] = val;
        if (options.dataCallback != null) {
          options.data = options.dataCallback(options.data);
        }
        success = options.success;
        options.success = function(data) {
          var items, nbItems, selected_values;
          if (data == null) {
            return;
          }
          selected_values = [];
          select.find('option').each(function() {
            if (!$(this).is(":selected")) {
              return $(this).remove();
            } else {
              return selected_values.push($(this).val() + "-" + $(this).text());
            }
          });
          select.find('optgroup:empty').each(function() {
            return $(this).remove();
          });
          items = callback != null ? callback(data, field) : data;
          nbItems = 0;
          $.each(items, function(i, element) {
            var group, text, value;
            nbItems++;
            if (element.group) {
              group = select.find("optgroup[label='" + element.text + "']");
              if (!group.size()) {
                group = $("<optgroup />");
              }
              group.attr('label', element.text).appendTo(select);
              return $.each(element.items, function(i, element) {
                var text, value;
                if (typeof element === "string") {
                  value = i;
                  text = element;
                } else {
                  value = element.value;
                  text = element.text;
                }
                if ($.inArray(value + "-" + text, selected_values) === -1) {
                  return $("<option />").attr('value', value).html(text).appendTo(group);
                }
              });
            } else {
              if (typeof element === "string") {
                value = i;
                text = element;
              } else {
                value = element.value;
                text = element.text;
              }
              if ($.inArray(value + "-" + text, selected_values) === -1) {
                return $("<option />").attr('value', value).html(text).appendTo(select);
              }
            }
          });
          if (nbItems) {
            select.trigger("chosen:updated");
          } else {
            select.data().chosen.no_results_clear();
            select.data().chosen.no_results(field.val());
          }
          if (settings.success != null) {
            settings.success(data);
          }
		  field.css('width','auto');
          return field.val(untrimmed_val);
        };
        return this.timer = setTimeout(function() {
          if (chosenXhr) {
            chosenXhr.abort();
          }
          return chosenXhr = $.ajax(options);
        }, options.afterTypeDelay);
      });
    });
  };
})(jQuery);
