Paragraph = require('./Paragraph.coffee')
Range = require('./Range.coffee')
KeyUtils = require('./utils/KeyUtils.coffee')
DomUtils = require('./utils/DomUtils.coffee')

Editor = class Editor
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


		@element.addEventListener 'keydown', (e) =>
			# @sections[@currentSection].element.dispatchEvent(e)

			if e.keyCode is KeyUtils.keyCodes.DOM_VK_BACK_SPACE
				selections = @getSelectionBySection()
				first = selections[0]
				if first.selection.isCollapsed()
					first.section.delete(first.selection.start - 1, 1)
					first.section.setCursorPosition(first.selection.start - 1)
				else
					@multisectionDelete(selections)
					first.section.setCursorPosition(first.selection.start)
				e.preventDefault()

			if e.metaKey && e.keyCode is KeyUtils.keyCodes.DOM_VK_B
				selections = @getSelectionBySection()
				start = selections[0]
				end = selections[selections.length - 1]
				for selection in selections
					selection.section.applyHighlight(selection.selection, 'bold')
				@setSelection(start.section, start.selection.start, end.section, end.selection.end)
				e.preventDefault()
			if e.metaKey && e.keyCode is KeyUtils.keyCodes.DOM_VK_I
				selections = @getSelectionBySection()
				start = selections[0]
				end = selections[selections.length - 1]
				for selection in selections
					selection.section.applyHighlight(selection.selection, 'italic')
				@setSelection(start.section, start.selection.start, end.section, end.selection.end)
				e.preventDefault()


		@element.addEventListener 'keypress', (e) =>
			if e.keyCode is 13
				@add(@currentSection + 1, new Paragraph(''))
				@setCursorPosition(@currentSection + 1, 0)
				e.preventDefault()
			else
				char = String.fromCharCode(e.charCode)
				if char.length > 0
					selections = @getSelectionBySection()

					first = selections[0]
					if !first.selection.isCollapsed()
						@multisectionDelete(selections)
					first.section.insert(first.selection.start, char)
					first.section.setCursorPosition(first.selection.start + char.length)
					e.preventDefault()

		# user moved cursor, reset internal tracking
		###
		@element.addEventListener 'keyup', (e) =>
			#console.log('u', e.keyCode, e)
			if e.keyCode in KeyUtils.movementKeys
				@setCursorPosition()

		@element.addEventListener 'mouseup', (e) =>
			#debugger;
			@setCursorPosition()
		###

		@add(0, new Paragraph('')) if @sections.length is 0
		@input.parentNode.insertBefore(@element, @input.nextSibling)
		@input.style.display = 'none'

	tag: "div"
	className: "chronicler-editor"
	sections: []
	currentSection: 0
	currentRange: new Range()

	getSelectionBySection: () ->
		selection = window.getSelection()
		range = selection.getRangeAt(0)
		startSection = DomUtils.closest(range.startContainer, (node) => node.parentNode is @element)
		endSection = DomUtils.closest(range.endContainer, (node) => node.parentNode is @element)
		add = false
		ret = []

		for section, i in @sections
			add = true if section.element is startSection
			if add
				ret.push {
					section: section
					index: i
					selection: section.getSelection()
				}
			add = false if section.element is endSection

		return ret


	setSelection: (startSection, startIndex, endSection, endIndex) ->
		selection = window.getSelection()
		selection.removeAllRanges()
		range = document.createRange()

		start = DomUtils.textNodeAndIndexForElementIndex(startSection.element, startIndex)
		range.setStart(start.node, start.index)
		if endSection? and endIndex?
			end = DomUtils.textNodeAndIndexForElementIndex(endSection.element, endIndex)
			range.setEnd(end.node, end.index)
		selection.addRange(range)

	setCursorPosition: (section, char, length) ->
		if !section? or !char? #if these two params are passed user is setting position
			selection = window.getSelection()
			range = selection.getRangeAt(0)

			startSection = DomUtils.closest(range.startContainer, (node) => node.parentNode is @element)
			startSectionNum = @sections.map((section) -> section.element).indexOf(startSection)
			startOffset = DomUtils.indexInAncestorForIndexInTextNode(@sections[startSectionNum].element, range.startContainer, range.startOffset)
			length = 0

			if !range.collapsed
				endOffset = DomUtils.indexInAncestorForIndexInTextNode(@sections[startSectionNum].element, range.endContainer, range.endOffset)
				length = endOffset - startOffset

			section = startSectionNum
			char = startOffset

		#return if section is @currentSection and char is @currentRange.start and length is @currentRange.length

		@currentSection = section
		@currentRange = new Range(char, length)
		@sections[section].setCursorPosition(char, length)

	add: (at, section) ->
		@sections.splice(at, 0, section)
		@element.insertBefore(section.element, @element.childNodes[at])
	remove: (at, keepElement = true) ->
		removed = @sections.splice(at, 1)
		if !keepElement
			removed[0].destroy()
	move: (at, to) ->
		section = @sections[at]
		@sections.splice(at, 1)
		@sections.splice(to, 0, section)
		@element.removeChild(section.element)
		@element.insertBefore(section.element, @element.childNodes[to])
	multiSectionDelete: (selections) ->
		first = selections[0]
		last = selections[selections.length - 1]
		if selections.length > 1
			last.section.delete(last.selection.start, last.selection.length)
			first.section.merge(last.section)

			for selection,i in selections.reverse()[0...selections.length - 1]
				@remove(selection.index)

			if selections.length > 0
				first.section.delete(first.selection.start, first.selection.length)

Object.defineProperty Editor.prototype, 'content',
	get: () ->
		contents = @sections.map (section) -> section.content
		contents.join('\n\n')



module.exports = Editor
