// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
//
var Singleshot = {
  setFrameSize: function(target) {
    target = $$(target).first() || $(target);
    // Adjust lower frame to expand and fit the reminder of the window.
    // Do it once now, and each time the window is resized.
    var adjust = function() {
      target.style.height = window.innerHeight - target.offsetTop + 'px';
    }
    Event.observe(window, 'resize', adjust);
    Event.observe(window, 'load', adjust);
  },

  // Called to show/hide (or expand/collapse) the target element on click.
  expand: function(event, target, alternative) {
    event = event || window.event;
    var source = Event.element(event);
    target = $$(target).first() || $(target);
    if (target.visible()) {
      if (source.originalText)
        source.innerHTML = source.originalText; 
      target.hide();
    } else if (event.shiftKey || event.ctrlKey || event.metaKey) {
      return;
    } else {
      if (alternative) {
        source.originalText = source.innerHTML;
        source.innerHTML = alternative;
      }
      target.show();
    }
    Event.stop(event);
  },

  makeTopFrame: function() {
    var to = window.location.href;
    if (top.location != to)
      top.location = to;
  }
}
