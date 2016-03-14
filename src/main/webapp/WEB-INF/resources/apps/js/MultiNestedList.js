/*
 * NAME     MultiNestedList.js
 * VERSION  1.6.1
 * DATE     2016-03-14
 *
 * Copyright 2012-2016
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
// Select the main list and add the class "hasSubmenu" in each LI that contains an UL
$('.tree ul').each(function(){
  $this = $(this);
  $this.find("li").has("ul").addClass("hasSubmenu");
});
// Find the last li in each level
$('.tree li:last-child').each(function(){
  $this = $(this);
  // Check if LI has children
  if ($this.children('ul').length === 0){
    // Add border-left in every UL where the last LI has not children
    $this.closest('ul').css("border-left", "1px solid gray");
  } else {
    // Add border in child LI, except in the last one
    $this.closest('ul').children("li").not(":last").css("border-left","1px solid gray");
    // Add the class "addBorderBefore" to create the pseudo-element :defore in the last li
    $this.closest('ul').children("li").last().children("a").addClass("addBorderBefore");
    // Add margin in other levels of the list
    $this.closest('ul').find("li").children("ul").css("margin-top","12px");
  };
});
// Add bold in li and levels above
$('.tree ul li').each(function(){
  $this = $(this);
  $this.mouseenter(function(){
    $( this ).children("a").css({"font-weight":"bold","color":"#336b9b"});
  });
  $this.mouseleave(function(){
    $( this ).children("a").css({"font-weight":"normal","color":"#428bca"});
  });
});
// Add button to expand and condense - Using FontAwesome
$('.tree ul li.hasSubmenu').each(function(){
  $this = $(this);
  $this.prepend("<a href='#'><i class='glyphicon glyphicon-minus-sign'></i><i style='display:none;' class='glyphicon glyphicon-plus-sign'></i></a>");
  $this.children("a").not(":last").removeClass().addClass("toogle");
});
// Actions to expand and consense
$('.tree ul li.hasSubmenu a.toogle').click(function(){
  $this = $(this);
  $this.closest("li").children("ul").toggle("slow");
  $this.children("i").toggle();
  return false;
});