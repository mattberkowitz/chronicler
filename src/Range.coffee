Range = class Range
	constructor: (start, length) ->
		@start = start if start?
		@length = length if length?
	start: 0
	length: 0
	isCollapsed: -> @length is 0
	intersects: (range) ->
		@start > range.start and @end < range.end
	contains: (range) ->
		@start <= range.start and @end >= range.end
	merge: (range) ->
		if range.start < @start
			@start = range.end
		if range.end > @end
			@length = range.end - @start
	containsPoint: (point) ->
		@start <= point and @end >= point

Object.defineProperty Range.prototype, 'end',
	get: () ->
		@start + @length


module.exports = Range
