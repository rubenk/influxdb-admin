#= require vendor/jquery-2.0.3
#= require vendor/angular
#= require admin
#= require_self

$ ->
  setExplorerSize = () ->
    parent.document.getElementById("explorer").style.height = (window.innerHeight - 45)+ 'px';

  setExplorerSize();

  $(window).on("resize", setExplorerSize)
