// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
//
var Singleshot = {
  // Returns the SingleShot.TaskView object.
  taskView: function() {
    var taskView = new Singleshot.TaskView();
    Singleshot.taskView = function() { return taskView };
    return taskView;
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

Singleshot.TaskView = Class.create({
  initialize: function() {
    this.adjustFrame('task_frame');
  },

  adjustFrame: function(ifr) {
    // Adjust lower frame to expand and fit the reminder of the window.
    // Do it once now, and each time the window is resized.
    if (ifr = $(ifr)) {
      var adjust = function() {
        ifr.style.height = window.innerHeight - ifr.offsetTop;
      }
      Event.observe(window, 'resize', adjust);
      adjust();
    }
  }
});
