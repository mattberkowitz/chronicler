(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var Bold, Highlight,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

Highlight = require('./Highlight.coffee');

module.exports = Bold = (function(superClass) {
  extend(Bold, superClass);

  function Bold() {
    return Bold.__super__.constructor.apply(this, arguments);
  }

  Bold.prototype.tag = "strong";

  return Bold;

})(Highlight);



},{"./Highlight.coffee":3}],2:[function(require,module,exports){
var Editor;

module.exports = Editor = (function() {
  function Editor(input) {
    var i, len, node, ref, section;
    this.element = document.createElement(this.tag);
    this.element.innerHTML = input.value;
    ref = this.element.childNodes;
    for (i = 0, len = ref.length; i < len; i++) {
      node = ref[i];
      section = null;
      if (node.tagName === 'p') {
        section = new Section(node);
      }
      this.insert(this.sections.length, section);
    }
  }

  Editor.prototype.tag = "div";

  Editor.prototype.className = "remington-editor";

  Editor.prototype.sections = [];

  Editor.prototype.currentSection = 0;

  Editor.prototype.insert = function(at, section) {
    this.sections.splice(at, 0, section);
    if (this.element.childNodes.length < at) {
      return this.element.appendChild(section.element);
    } else {
      return this.element.insertBefore(this.element.childNodes[at], section.element);
    }
  };

  Editor.prototype.remove = function(at) {
    var removed;
    removed = this.sections.splice(at, 1);
    return this.element.removeChild(removed[0].element);
  };

  Editor.prototype.move = function(at, to) {
    var section;
    section = this.sections[at];
    this.sections.splice(at, 1);
    this.sections.splice(to, 0, section);
    this.element.removeChild(section.element);
    return this.element.insertBefore(this.element.childNodes[to], section.element);
  };

  return Editor;

})();



},{}],3:[function(require,module,exports){
var Highlight, Selection,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

Selection = require('./Selection.coffee');

module.exports = Highlight = (function(superClass) {
  extend(Highlight, superClass);

  function Highlight() {
    return Highlight.__super__.constructor.apply(this, arguments);
  }

  Highlight.prototype.className = "";

  Highlight.prototype.tag = "span";

  return Highlight;

})(Selection);



},{"./Selection.coffee":5}],4:[function(require,module,exports){
var Section;

module.exports = Section = (function() {
  function Section(text) {
    this.element = document.createElement(this.tag);
    this.content = text;
    this.updateElement();
  }

  Section.prototype.updateElement = function() {
    return this.element.innerHTML = this.content;
  };

  Section.prototype.content = "";

  Section.prototype.tag = "p";

  Section.prototype.insert = function(start, str, len) {
    if (len == null) {
      len = 0;
    }
    return this.content = this.content.slice(0, start) + str + this.content.slice(start + len);
  };

  Section.prototype.remove = function(start, len) {
    return this.content = this.content.slice(0, start) + this.content.slice(start + len);
  };

  Section.prototype.render = function() {
    var ele;
    ele = document.createElement(this.tag);
    return ele.innerHTML = this.content;
  };

  return Section;

})();



},{}],5:[function(require,module,exports){
var Selection;

module.exports = Selection = (function() {
  function Selection() {}

  Selection.prototype.start = 0;

  Selection.prototype.length = 0;

  Selection.prototype.section = null;

  Selection.prototype.isRange = function() {
    return this.length > 0;
  };

  Selection.prototype.content = function() {
    return this.section.content.slice(this.start, this.length);
  };

  return Selection;

})();



},{}]},{},[1,2,3,4,5]);
