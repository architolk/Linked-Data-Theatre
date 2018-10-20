/*
 * NAME     slick.ldt-grid.js
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
var grid, s;
var loader = new Slick.Data.RemoteModel(apicall,subjecturi);
var options = {
  editable: true,
  enableAddRow: true,
  enableCellNavigation: true,
  asyncEditorLoading: false,
  autoEdit: false
};
var loadingIndicator = null;
var savingIndicator = null;
$(function () {
  grid = new Slick.Grid("#myGrid", loader.data, columns, options);
  grid.onViewportChanged.subscribe(function (e, args) {
    var vp = grid.getViewport();
    loader.ensureData(vp.top, vp.bottom);
  });
  grid.onSort.subscribe(function (e, args) {
    loader.setSort(args.sortCol.field, args.sortAsc ? 1 : -1);
    var vp = grid.getViewport();
    loader.ensureData(vp.top, vp.bottom);
  });
  grid.onCellChange.subscribe(function (e, args) {
    if (args.item['#'] == 0) {
      args.item['#'] = 2;
    }
    loader.updateRow(args.row);
    grid.invalidateRow(args.row);
    grid.render();
  });
  grid.onClick.subscribe(function (e, args) {
    if (args.cell == 0) {
      grid.setActiveCell(args.row, 1, false, false, true);
      grid.getSelectionModel().setSelectedRanges([new Slick.Range(args.row,1,args.row,grid.getColumns().length-1)]);
    }
  });
  grid.onKeyDown.subscribe(function(e, args) {
    // 46: delete key
    if (e.which == 46) {
      ranges = grid.getSelectionModel().getSelectedRanges();
      if (ranges.length == 1) {
        if (ranges[0].fromRow == ranges[0].toRow && ranges[0].fromCell == 1 && ranges[0].toCell == grid.getColumns().length-1) {
          loader.removeRow(ranges[0].fromRow,1);
          grid.invalidate();
          grid.getSelectionModel().setSelectedRanges([]);
          e.preventDefault();
          e.stopPropagation();
        }
      }
    }
  });
  loader.onDataLoading.subscribe(function () {
    if (!loadingIndicator) {
      loadingIndicator = $("<span class='loading-indicator'><label>Loading...</label></span>").appendTo(document.body);
      var $g = $("#myGrid");
      loadingIndicator
          .css("position", "absolute")
          .css("top", $g.position().top + $g.height() / 2 - loadingIndicator.height() / 2)
          .css("left", $g.position().left + $g.width() / 2 - loadingIndicator.width() / 2);
    }
    loadingIndicator.show();
  });
  loader.onDataLoaded.subscribe(function (e, args) {
    for (var i = args.from; i <= args.to; i++) {
      grid.invalidateRow(i);
    }
    grid.updateRowCount();
    grid.render();
    loadingIndicator.fadeOut();
  });
  loader.onDataSaving.subscribe(function () {
    if (!savingIndicator) {
      savingIndicator = $("<span class='loading-indicator'><label>Saving...</label></span>").appendTo(document.body);
      var $g = $("#myGrid");
      savingIndicator
          .css("position", "absolute")
          .css("top", $g.position().top + $g.height() / 2 - savingIndicator.height() / 2)
          .css("left", $g.position().left + $g.width() / 2 - savingIndicator.width() / 2);
    }
    savingIndicator.show();
  });
  loader.onDataSaved.subscribe(function (e, args) {
    savingIndicator.fadeOut();
  });
  $("#txtSearch").keyup(function (e) {
    if (e.which == 13) {
      loader.setSearch($(this).val());
      var vp = grid.getViewport();
      loader.ensureData(vp.top, vp.bottom);
    }
  });
  loader.setSearch($("#txtSearch").val());
  loader.setSort("score", -1);
  grid.setSortColumn("score", false);
  // load the first page
  grid.onViewportChanged.notify();

  grid.setSelectionModel(new Slick.CellSelectionModel());

  grid.onAddNewRow.subscribe(function (e, args) {
    loader.addRow(grid,args.item,defaultItem);
  });

})
