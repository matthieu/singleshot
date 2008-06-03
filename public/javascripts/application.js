// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
//
var Singleshot = {
  // Returns the SingleShot.TaskView object.
  taskView: function(target) {
    target = $$(target).first() || $(target);
    // Adjust lower frame to expand and fit the reminder of the window.
    // Do it once now, and each time the window is resized.
    var adjust = function() {
      target.style.height = window.innerHeight - target.offsetTop;
    }
    Event.observe(window, 'resize', adjust);
    adjust();
    Singleshot.taskView = function() { };
  },

  expand: function(event, target, alternative) {
    event = event || window.event;
    var source = Event.element(event);
    target = $$(target).first() || $(target);
    if (target.visible()) {
      source.innerHTML = source.originalText; 
      target.hide();
    } else if (event.shiftKey || event.ctrlKey || event.metaKey) {
      return;
    } else {
      source.originalText = source.innerHTML;
      if (alternative)
        source.innerHTML = alternative;
      target.show();
    }
    Event.stop(event);
  }
}
