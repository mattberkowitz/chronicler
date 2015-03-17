Paragraph = require('./Paragraph.coffee')
Range = require('./Range.coffee')
KeyUtils = require('./utils/KeyUtils.coffee')
DomUtils = require('./utils/DomUtils.coffee')

module.exports = class Editor
	constructor:(@input = input) ->
		@element = document.createElement(@tag)
		@element.contentEditable = true

		@element.className = @className
		@element.innerHTML = @input.value
		for node in @element.childNodes
			section = null
			if node.tagName is 'p'
				section = new Paragraph(node.innerHTML)
			@add(@sections.length, section)

		#@element.addEvent

		@element.addEventListener 'keydown', (e) =>
			if e.keyCode is KeyUtils.keyCodes.DOM_VK_BACK_SPACE
				if @currentRange.isCollapsed()
					@sections[@currentSection].delete(@currentRange.start - 1, 1)
					@currentRange.start--
				else
					@sections[@currentSection].delete(@currentRange.start - 1, @currentRange.length)
				@currentRange.length = 0
				e.preventDefault()


			if e.metaKey && e.keyCode is KeyUtils.keyCodes.DOM_VK_B
				@sections[@currentSection].applyHighlight(@currentRange, 'bold')
				e.preventDefault()
			if e.metaKey && e.keyCode is KeyUtils.keyCodes.DOM_VK_I
				@sections[@currentSection].applyHighlight(@currentRange, 'italic')
				e.preventDefault()


		@element.addEventListener 'keypress', (e) =>
			#console.log('p', e.keyCode, e)
			@sections[@currentSection].insert(@currentRange.start, String.fromCharCode(e.charCode), @currentRange.length)
			@currentRange.start = @currentRange.start + 1
			@currentRange.length = 0
			e.preventDefault()


		# user moved cursor, reset internal tracking
		@element.addEventListener 'keyup', (e) =>
			#console.log('u', e.keyCode, e)
			if e.keyCode in KeyUtils.movementKeys
				@setCursorPosition()

		@element.addEventListener 'mouseup', (e) =>
			@setCursorPosition()

		@element.addEventListener 'keyup', (e) =>

		@add(0, new Paragraph()) if @sections.length is 0
		@input.parentNode.insertBefore(@element, @input.nextSibling)
		@input.style.display = 'none'

	tag: "div"
	className: "chronicler-editor"
	sections: []
	currentSection: 0
	currentRange: new Range()

	setCursorPosition: (section, char, length) ->
		if section? and char? #if these two params are passed user is setting position

		else #otherwise, figure out where it's at based on browser cursor position
			selection = window.getSelection()
			range = selection.getRangeAt(0)

			startSection = DomUtils.closest(range.startContainer, (node) => node.parentNode is @element)
			startSectionNum = @sections.map((section) -> section.element).indexOf(startSection)
			startOffset = @sections[startSectionNum].pointInSectionForPointInTextNode(range.startContainer, range.startOffset)
			length = 0

			if !range.collapsed
				endOffset = @sections[startSectionNum].pointInSectionForPointInTextNode(range.endContainer, range.endOffset)
				length = endOffset - startOffset
				console.log(endOffset, length)

			section = startSectionNum
			char = startOffset

		#return if section is @currentSection and char is @currentRange.start and length is @currentRange.length

		@currentSection = section
		@currentRange = new Range(char, length)
		@sections[section].setCursorPosition(char, length)

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
