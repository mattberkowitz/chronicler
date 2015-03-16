module.exports = class Range
	constructor: (start, length) ->
		@start = start if start?
		@length = length if length?
	start: 0
	length: 0
	isCollapsed: -> @length is 0
