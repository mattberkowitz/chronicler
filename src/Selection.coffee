module.exports = class Selection
	start: 0
	length: 0
	section: null
	isRange: -> @length > 0
	content: -> @section.content.slice(@start, @length)
