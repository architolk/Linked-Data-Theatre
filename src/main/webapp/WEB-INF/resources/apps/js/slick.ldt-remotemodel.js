/*
 * NAME     slick.ldt-remotemodel.js
 * VERSION  1.23.0
 * DATE     2018-10-20
 *
 * Copyright 2012-2018
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
function saveGrid() {
  var url = containerurl;
  if (subjecturi!=="") {
    url = url + "?subject=" + encodeURIComponent(subjecturi);
  }
  loader.saveData(url,context);
}
function saveChangedGrid() {
  var url = containerurl;
  if (subjecturi!=="") {
    url = url + "?subject=" + encodeURIComponent(subjecturi);
  }
  loader.saveChangedData(url,context);
}

function statusFormatter(row, cell, value, columnDef, dataContent) {
  var img = "";
  if (value === 1) { //New item
    img = "<img src='"+staticroot+"/css/images/tick.png'>";
  } else if (value === 2) { //Changed item
    img = "<img src='"+staticroot+"/css/images/tag_red.png'>";
  }
  return img;
}

(function ($) {
  /***
   * A sample AJAX data store implementation.
   * Right now, it's hooked up to load search results from Octopart, but can
   * easily be extended to support any JSONP-compatible backend that accepts paging parameters.
   */
  function RemoteModel(pUrl, pSubjectUri) {
    // private
    var PAGESIZE = 50;
    var data = [];
    var deletedData = [];
    var searchstr = "";
    var sortcol = null;
    var sortdir = 1;
    var h_request = null;
    var req = null; // ajax request
    var url = pUrl;
    var resourceProperties = {};

    if (pSubjectUri!=="") {
      url = url + "?subject=" + encodeURIComponent(pSubjectUri);
    }
    
    // events
    var onDataLoading = new Slick.Event();
    var onDataLoaded = new Slick.Event();
    var onDataSaving = new Slick.Event();
    var onDataSaved = new Slick.Event();


    function init() {
    }

    function alertError(resp) {
      if (resp.hasOwnProperty("status")) {
        if (resp.status == 0) {
          alert("Connection lost - please try again");
        } else {
          if (resp.hasOwnProperty("responseText")) {
            alert(resp.status + ": " + resp.responseText);
          } else {
            alert("Error: " + resp.status + "(sorry, don't have more information)");
          }
        }
      } else {
        alert("Connection lost - please try again");
      }
    }
    

    function isDataLoaded(from, to) {
      for (var i = from; i <= to; i++) {
        if (data[i] == undefined || data[i] == null) {
          return false;
        }
      }

      return true;
    }


    function clear() {
      for (var key in data) {
        delete data[key];
      }
      data.length = 0;
    }

    function removeRow(row) {
      var d = new Date(Date.now());
      deletedData.push({
        "@id": data[row]["@id"],
        "http://www.w3.org/ns/prov#invalidatedAtTime": d.toISOString()
      });
      data.splice(row,1);
    }

    function ensureData(from, to) {
      if (req) {
        req.abort();
        for (var i = req.fromPage; i <= req.toPage; i++)
          data[i * PAGESIZE] = undefined;
      }

      if (from < 0) {
        from = 0;
      }

      if (data.length > 0) {
        to = Math.min(to, data.length - 1);
      }

      var fromPage = Math.floor(from / PAGESIZE);
      var toPage = Math.floor(to / PAGESIZE);

      while (data[fromPage * PAGESIZE] !== undefined && fromPage < toPage)
        fromPage++;

      while (data[toPage * PAGESIZE] !== undefined && fromPage < toPage)
        toPage--;

      if (fromPage > toPage || ((fromPage == toPage) && data[fromPage * PAGESIZE] !== undefined)) {
        // TODO:  look-ahead
        onDataLoaded.notify({from: from, to: to});
        return;
      }

      if (h_request != null) {
        clearTimeout(h_request);
      }

      h_request = setTimeout(function () {
        for (var i = fromPage; i <= toPage; i++)
          data[i * PAGESIZE] = null; // null indicates a 'requested but not available yet'

        onDataLoading.notify({from: from, to: to});

        req = $.ajax({
          cache: false,
          headers: {Accept: "application/ld+json"},
          datatype: "json",
          url: url,
          success: onSuccess,
          error: function (resp) {
            onError(resp, fromPage, toPage)
          }
        });
        req.fromPage = fromPage;
        req.toPage = toPage;
      }, 50);
    }


    function onError(resp, fromPage, toPage) {
      alertError(resp);
      //alert("error loading pages " + fromPage + " to " + toPage);
      //Notify to remove loading splash screen. Better would be a specific event
      onDataLoaded.notify({from: 0, to: 0});
    }

    function onSuccess(resp) {
      var from = 0;
      var context = resp['@context'];
      //Save resource properties to know which values are URI's
      for (var item in context) {
        if (typeof context[item] === 'object') {
          var pos = item.indexOf(":");
          if (pos > 0) {
            var prefix = item.substring(0,pos);
            var name = item.substring(pos+1);
            var namespace = context[prefix];
            if (namespace !== "") {
              resourceProperties[namespace+name] = true;
            }
          }
        }
      }
      //Load data
      //TODO: Needs refactoring. Same code three times
      if ('graph' in resp) {
        // Data contains a graph statement: triples are part of a graph node
        to = from + resp.graph.length;
        data.length = resp.graph.length;
        for (var i = 0; i < resp.graph.length; i++) {
          var resource = resp.graph[i];
          var item = {};
          //Populate item with data from JSON-LD
          for (var property in resource) {
            if (resource.hasOwnProperty(property)) {
              var pos = property.indexOf(":");
              var url = property;
              if (pos > 0) {
                var prefix = property.substring(0,pos);
                var name = property.substring(pos+1);
                var namespace = context[prefix];
                if (namespace !== "") {
                  url = namespace+name;
                }
              } else {
                var alias = context[property];
                if (alias !== "") {
                  url = alias;
                }
              }
              item[url] = resource[property];
            }
          }
          //Populate item for calculated fields
          for (var key in fragments) {
            if (fragments.hasOwnProperty(key)) {
              if (fragments[key] === key) {
                for (var value in templateItem) {
                  if (templateItem.hasOwnProperty(value) && item.hasOwnProperty(value)) {
                    if (templateItem[value].indexOf("{"+key+"}")>0) {
                      var regex = new RegExp("^"+templateItem[value].replace("{"+key+"}","(.+)")+"$","g");
                      item[key]=item[value].replace(regex,"$1");
                    }
                  }
                }
              }
            }
          }
          
          data[from + i] = item;
          data[from + i].index = from + i;
          data[from + i]['#'] = 0; // Keep track of changes in the data
        }
      } else if ('@id' in resp) {
        //Single item, not part of a graph statement
        to = from + 1;
        var resource = resp;
        var item = {};
        //Populate item with data from JSON-LD
        for (var property in resource) {
          if (resource.hasOwnProperty(property) && property!=='@context') {
            var pos = property.indexOf(":");
            var url = property;
            if (pos > 0) {
              var prefix = property.substring(0,pos);
              var name = property.substring(pos+1);
              var namespace = context[prefix];
              if (namespace !== "") {
                url = [namespace+name];
              }
            }
            item[url] = resource[property];
          }
        }
        //Populate item for calculated fields
        for (var key in fragments) {
          if (fragments.hasOwnProperty(key)) {
            if (fragments[key] === key) {
              item[key]='calc';
            }
          }
        }
        
        data[from] = item;
        data[from].index = from;
        data[from]['#'] = 0; // Keep track of changes in the data
      } else if ($.isArray(resp)) {
        //Multiple items, contained in an array
        to = from + resp.length;
        data.length = resp.length;
        for (var i = 0; i < resp.length; i++) {
          var resource = resp[i];
          var item = {};
          //Populate item with data from JSON-LD
          for (var property in resource) {
            if (resource.hasOwnProperty(property)) {
              var url = property;
              if (url === "@type") {
                url = "http://www.w3.org/1999/02/22-rdf-syntax-ns#type";
              }
              var value = resource[property];
              if ($.isArray(value)) {
                value = value[0]; //Multiple values are not supported yet
              }
              if (typeof value === "object") {
                if (value.hasOwnProperty('@value')) {
                  item[url] = value['@value'];
                }
                if (value.hasOwnProperty('@id')) {
                  item[url] = value['@id'];
                }
              } else {
                item[url] = value;
              }
            }
          }
          //Populate item for calculated fields
          for (var key in fragments) {
            if (fragments.hasOwnProperty(key)) {
              if (fragments[key] === key) {
                for (var value in templateItem) {
                  if (templateItem.hasOwnProperty(value) && item.hasOwnProperty(value)) {
                    if (templateItem[value].indexOf("{"+key+"}")>0) {
                      var regex = new RegExp("^"+templateItem[value].replace("{"+key+"}","(.+)")+"$","g");
                      item[key]=item[value].replace(regex,"$1");
                    }
                  }
                }
              }
            }
          }
          
          data[from + i] = item;
          data[from + i].index = from + i;
          data[from + i]['#'] = 0; // Keep track of changes in the data
        }
      } else {
        to = from;
      }
      
      req = null

      onDataLoaded.notify({from: from, to: to});
    }


    function reloadData(from, to) {
      for (var i = from; i <= to; i++)
        delete data[i];

      ensureData(from, to);
    }


    function setSort(column, dir) {
      sortcol = column;
      sortdir = dir;
      clear();
    }

    function setSearch(str) {
      searchstr = str;
      clear();
    }

    function addRow(grid,item, defaultItem) {
      item['#'] = 1;
      for (var property in defaultItem) {
        if (defaultItem.hasOwnProperty(property)) {
            item[property]=defaultItem[property];
        }
      }
      item['@id'] = UUIDjs.create().toURN();
      data.push(item);
      updateRow(data.length-1);
      grid.invalidateRow(data.length-1);
      grid.updateRowCount();
      grid.render();
    }

    function updateRow(row) {
      for (var property in templateItem) {
        if (templateItem.hasOwnProperty(property)) {
          var value = templateItem[property];
          for (var name in fragments) {
            if (fragments.hasOwnProperty(name)) {
              if (value.indexOf("{"+name+"}")>0) {
                if (data[row].hasOwnProperty(fragments[name])) {
                  var newvalue = data[row][fragments[name]];
                  if (newvalue !== "") {
                    value = value.replace("{"+name+"}",newvalue);
                  } else {
                    value = "";
                  }
                } else {
                  value = "";
                }
              }
            }
          }
        }
        if (value === "") {
          delete data[row][property];
        } else {
          data[row][property] = value;
        }
      }
    }
    
    function saveData(url,context) {

      var mergedContext = {};
      for (var item in context) {
        if (context.hasOwnProperty(item)) {
          if (typeof context[item] === 'object') {
            mergedContext[item]={'@type': '@id'};
          } else {
            mergedContext[item]=context[item];
          }
        }
      }
      for (var item in resourceProperties) {
        if (resourceProperties.hasOwnProperty(item)) {
          mergedContext[item]={'@type': '@id'};
        }
      }
    
      var body = {
        '@context': mergedContext,
        graph: data
      };

      onDataSaving.notify();
      
      $.ajax({
        type: "PUT",
        contentType: "application/ld+json",
        url: url,
        data: JSON.stringify(body),
        success: function () {
          for (var i = 0; i < data.length; i++) {
            data[i]['#'] = 0; //Saved, so reset change indication
          }
          grid.invalidateAllRows();
          grid.render();
          onDataSaved.notify();
        },
        error: function (resp) {
          alertError(resp);
          //Notify to remove saving splash screen. Better would be a specific event
          onDataSaved.notify();
        }
      })
    }
    
    function saveChangedData(url,context) {

      function onlyInsertedItems(value) {
        return (value['#'] === 1)
      }
      function onlyChangedItems(value) {
        return (value['#'] === 2)
      }
      function handleSucces() {
        callCount--;
        if (callCount === 0) {
          callCount = -1;
          for (var i = 0; i < data.length; i++) {
            data[i]['#'] = 0; //Saved, so reset change indication
          }
          deletedData.splice(0,deletedData.length);
          grid.invalidateAllRows();
          grid.render();
          onDataSaved.notify();
        }
      }
    
      var mergedContext = {};
      for (var item in context) {
        if (context.hasOwnProperty(item)) {
          if (typeof context[item] === 'object') {
            mergedContext[item]={'@type': '@id'};
          } else {
            mergedContext[item]=context[item];
          }
        }
      }
      for (var item in resourceProperties) {
        if (resourceProperties.hasOwnProperty(item)) {
          mergedContext[item]={'@type': '@id'};
        }
      }
    
      var bodyInserted = {
        '@context': mergedContext,
        graph: data.filter(onlyInsertedItems)
      };
      var bodyChanged = {
        '@context': mergedContext,
        graph: data.filter(onlyChangedItems)
      };
      var bodyDeleted = {
        '@context': mergedContext,
        graph: deletedData
      };

      var callCount = 0;
      if (bodyDeleted.graph.length > 0) {callCount++}
      if (bodyInserted.graph.length > 0) {callCount++}
      if (bodyChanged.graph.length > 0) {callCount++}
      
      if (callCount > 0) {onDataSaving.notify();}
      
      if (bodyDeleted.graph.length > 0) {
        $.ajax({
          type: "DELETE",
          contentType: "application/ld+json",
          url: url,
          data: JSON.stringify(bodyDeleted),
          success: handleSucces,
          error: function (resp) {
            alertError(resp);
            //Notify to remove saving splash screen. Better would be a specific event
            onDataSaved.notify();
          }
        })
      }
      if (bodyInserted.graph.length > 0) {
        $.ajax({
          type: "POST",
          contentType: "application/ld+json",
          url: url,
          data: JSON.stringify(bodyInserted),
          success: handleSucces,
          error: function (resp) {
            alertError(resp);
            //Notify to remove saving splash screen. Better would be a specific event
            onDataSaved.notify();
          }
        })
      }
      if (bodyChanged.graph.length > 0) {
        $.ajax({
          type: "PUT",
          contentType: "application/ld+json",
          url: url,
          data: JSON.stringify(bodyChanged),
          success: handleSucces,
          error: function (resp) {
            alertError(resp);
            //Notify to remove saving splash screen. Better would be a specific event
            onDataSaved.notify();
          }
        })
      }
    }
    
    init();

    return {
      // properties
      "data": data,

      // methods
      "clear": clear,
      "isDataLoaded": isDataLoaded,
      "ensureData": ensureData,
      "reloadData": reloadData,
      "setSort": setSort,
      "setSearch": setSearch,
      "addRow": addRow,
      "removeRow": removeRow,
      "updateRow": updateRow,
      "saveData": saveData,
      "saveChangedData": saveChangedData,

      // events
      "onDataLoading": onDataLoading,
      "onDataLoaded": onDataLoaded,
      "onDataSaving": onDataSaving,
      "onDataSaved": onDataSaved
    };
  }

  // Slick.Data.RemoteModel
  $.extend(true, window, { Slick: { Data: { RemoteModel: RemoteModel }}});
})(jQuery);