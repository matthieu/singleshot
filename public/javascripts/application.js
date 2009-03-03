// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
//
var Singleshot = {
  makeTopFrame: function() {
    var to = window.location.href;
    if (top.location != to)
      top.location = to;
  }
}
