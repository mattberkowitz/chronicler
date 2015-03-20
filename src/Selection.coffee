Range = require('./Range.coffee')
DomUtils = require('./utils/DomUtils.coffee')
Selection = class Selection
	section: null
	range: null
	constructor: (@section, rangeStart, rangeLength = 0) ->
		if rangeStart instanceof Range
			@range = rangeStart
		else
			@range = new Range(rangeStart, rangeLength)

		throw "selections must have a section and a range" if !@section or !@range

	clear: () -> @section.delete(@range.start, @range.length)

	applyHighlight: (key) -> @section.applyHighlight(@range, key)

	#Range methods
	isCollapsed: -> @range.isCollapsed()

	intersects: (compareTo) ->
		if compareTo instanceof Range
			return @range.intersects compareTo
		else if compareTo instanceof Selection
			if compareTo.section isnt @section
				return false
			return @range.intersects compareTo.range

	contains: (compareTo) ->
		if compareTo instanceof Range
			return @range.contains compareTo
		else if range instanceof Selection
			if compareTo.section isnt @section
				return false
			return @range.contains compareTo.range

	merge: (other) ->
		if other instanceof Range
			return @range.merge other
		else if other instanceof Selection
			if other.section isnt @section
				throw "can't merge selections from different sections"
			return @range.merge other.range

	containsPoint: (point) -> @range.containsPoint p


Object.defineProperty Selection.prototype, 'content',
	get: () ->
		@section.content.substr(@range.start, @range.length)



# Range Property passthrough
Object.defineProperty Selection.prototype, 'start',
	get: () -> @range.start
	set: (val) -> @range.start = val

Object.defineProperty Selection.prototype, 'length',
	get: () -> @range.length
	set: (val) -> @range.length = val

Object.defineProperty Selection.prototype, 'end',
	get: () -> @range.end

module.exports = Selection
