#= require vendor/custom.modernizr
#= require vendor/jquery-2.0.3
#= require vendor/angular
#= require vendor/angular-cookies
#= require vendor/jquery.magnific-popup.min
#= require admin
#= require_self

$ ->
  setExplorerSize = () ->
    parent.document.getElementById("explorer").style.height = (window.innerHeight - 45)+ 'px';

  setExplorerSize();

  $(window).on("resize", setExplorerSize)

  window.getHashParams = () ->
    angular.element(document.getElementsByTagName("body")[0]).scope().getHashParams()

  window.setHashParams = (params) ->
    angular.element(document.getElementsByTagName("body")[0]).scope().setHashParams(params)

  $(document).foundation();
