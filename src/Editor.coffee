Paragraph = require('./Paragraph.coffee')
Range = require('./Range.coffee')
Bold = require('./Bold.coffee')

module.exports = class Editor
	constructor:(@input = input) ->
		@element = document.createElement(@tag)
		@element.contentEditable = true
		@element.className = @className

		@element.innerHTML = @input.value
		for node in @element.childNodes
			section = null
			if node.tagName is 'p'
				section = new Paragraph(node)
			@add(@sections.length, section)

		#@element.addEvent

		@element.addEventListener 'keydown', (e) =>
			if e.metaKey && e.keyCode is 66
				@sections[@currentSection].applyHighlight(@currentRange, 'bold')
				e.preventDefault()

		@element.addEventListener 'keypress', (e) =>
			@sections[@currentSection].insert(@currentRange.start, String.fromCharCode(e.charCode), @currentRange.length)
			@currentRange.start = @currentRange.start + 1
			@currentRange.length = 0
			e.preventDefault()

		@add(0, new Paragraph()) if @sections.length is 0
		@input.parentNode.insertBefore(@element, @input.nextSibling)
		@input.style.display = 'none'
	tag: "div"
	className: "chronicler-editor"
	sections: []
	currentSection: 0
	currentRange: new Range(),

	add: (at, section) ->
		@sections.splice(at, 0, section)
		@element.insertBefore(section.element, @element.childNodes[at])
	remove: (at) ->
		removed = @sections.splice(at, 1)
		@element.removeChild(removed[0].element)
	move: (at, to) ->
		section = @sections[at]
		@sections.splice(at, 1)
		@sections.splice(to, 0, section)
		@element.removeChild(section.element)
		@element.insertBefore(section.element, @element.childNodes[to])

	@availableHighlights:
		"bold": Bold
	@registerHighlight: (highlight) ->
		if highlight.key?
			@availableHighlihgts[highlight.key] = highlight
