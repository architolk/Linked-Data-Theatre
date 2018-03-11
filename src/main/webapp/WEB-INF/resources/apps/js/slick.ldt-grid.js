var grid, s;
var loader = new Slick.Data.RemoteModel(apicall);
var options = {
  editable: true,
  enableAddRow: true,
  enableCellNavigation: true,
  asyncEditorLoading: false,
  autoEdit: false
};
var loadingIndicator = null;
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
    if (args.item['#']===0) {
      args.item['#'] = 2;
    }
    grid.invalidateRow(args.row);
    grid.render();
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
