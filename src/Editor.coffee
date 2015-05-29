Paragraph = require('./Paragraph.coffee')
Range = require('./Range.coffee')
KeyUtils = require('./utils/KeyUtils.coffee')
DomUtils = require('./utils/DomUtils.coffee')

Editor = class Editor
	constructor:(@input = input) ->
		@element = document.createElement(@tag)
		@element.contentEditable = true
		@sections = []
		@_sectionIsCurrent = false
		@_currentSection = null

		@element.className = @className

		div = document.createElement('div')
		div.innerHTML = @input.value

		for node in div.childNodes
			section = null
			if node.tagName is 'P'
				section = new Paragraph(node.innerHTML)
			@add(@sections.length, section)

		@_events()

		div = null

		@add(0, new Paragraph('')) if @sections.length is 0
		@input.parentNode.insertBefore(@element, @input.nextSibling)
		@input.style.display = 'none'

	_events: () ->
		@element.addEventListener 'keydown', (e) =>

			if e.keyCode is KeyUtils.keyCodes.DOM_VK_BACK_SPACE
				selections = @getSelectionBySection()
				first = selections[0]
				if selections.length is 1 and first.isCollapsed()
					if first.start is 0
						firstIndex = @getSectionIndex(first.section)
						prev = @sections[firstIndex - 1]
						prevEnd = prev.content.length
						prev.merge(first.section)
						first.section.destroy()
						@removeAtIndex(firstIndex)
						prev.setCursorPosition(prevEnd)
					else
						first.section.delete(first.start - 1, 1)
						first.section.setCursorPosition(first.start - 1)
				else
					@multiSectionDelete(selections)
					first.section.setCursorPosition(first.start)
				e.preventDefault()
			else if e.keyCode is KeyUtils.keyCodes.DOM_VK_DELETE
				selections = @getSelectionBySection()
				first = selections[0]
				if selections.length is 1 and first.isCollapsed()
					if first.start is first.section.content.length
						firstIndex = @getSectionIndex(first.section)
						firstLength = first.section.content.length
						if firstIndex < @sections.length - 1
							next = @sections[firstIndex + 1]
							first.section.merge(next)
							next.destroy()
							@remove(next)
							first.section.setCursorPosition(firstLength)
					else
						first.section.delete(first.start, 1)
						first.section.setCursorPosition(first.start)
				else
					@multiSectionDelete(selections)
					first.section.setCursorPosition(first.start)
				e.preventDefault()

			if e.metaKey && e.keyCode is KeyUtils.keyCodes.DOM_VK_B
				selections = @getSelectionBySection()
				start = selections[0]
				end = selections[selections.length - 1]
				for selection in selections
					selection.applyHighlight('bold')
				@setSelection(start.section, start.range.start, end.section, end.range.end)
				e.preventDefault()

			if e.metaKey && e.keyCode is KeyUtils.keyCodes.DOM_VK_I
				selections = @getSelectionBySection()
				start = selections[0]
				end = selections[selections.length - 1]
				for selection in selections
					selection.applyHighlight('italic')
				@setSelection(start.section, start.range.start, end.section, end.range.end)
				e.preventDefault()


		@element.addEventListener 'keypress', (e) =>
			if e.keyCode is 13
				selections = @getSelectionBySection()

				if !selections[0]?.isCollapsed() or selections.length > 1
					@multiSectionDelete(selections)

				addIndex = @currentSectionIndex + 1
				@add(addIndex, @currentSection.splitAtIndex(selections[0].start))
				@setCursorPosition(addIndex, 0)
				e.preventDefault()
			else
				char = String.fromCharCode(e.charCode)
				if char.length > 0
					selections = @getSelectionBySection()

					first = selections[0]
					if !first.isCollapsed() or selections.length > 0
						@multiSectionDelete(selections)
					first.section.insert(first.start, char)
					first.section.setCursorPosition(first.start + char.length)
					e.preventDefault()



		@element.addEventListener 'keyup', (e) =>
			#console.log('u', e.keyCode, e)
			if e.keyCode in KeyUtils.movementKeys
				@_sectionIsCurrent = false


			selections = @getSelectionBySection()
				for selection in selections
				selection.section.calcTrackChanges(testChanges)
				
		@element.addEventListener 'mouseup', (e) =>
			@_sectionIsCurrent = false


	tag: "div"
	className: "chronicler-editor"

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
				ret.push section.getSelection()
			add = false if section.element is endSection

		# since were getting this anyway, set it maybe save some cycles in the future
		if ret.length > 0
			@_sectionIsCurrent = true
			@_currentSection = ret[0].section

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

		@_sectionIsCurrent = true
		@_currentSection = startSection

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

		@sections[section].setCursorPosition(char, length)
		@_sectionIsCurrent = true
		@_currentSection = @sections[section]

	add: (at, section) ->
		@sections.splice(at, 0, section)
		@element.insertBefore(section.element, @element.childNodes[at])

	remove: (section) -> @removeAtIndex(@getSectionIndex(section))

	removeAtIndex: (at) ->
		removed = @sections.splice(at, 1)

	move: (at, to) ->
		section = @sections[at]
		@sections.splice(at, 1)
		@sections.splice(to, 0, section)
		@element.removeChild(section.element)
		@element.insertBefore(section.element, @element.childNodes[to])

	getSectionIndex: (section) ->
		for s, i in @sections
			return i if s is section
		return null

	multiSectionDelete: (selections) ->
		first = selections[0]
		last = selections[selections.length - 1]
		if selections.length > 1
			last.clear()
			first.section.merge(last.section)

			for selection,i in selections.reverse()[0...selections.length - 1]
				selection.section.destroy()
				@remove(selection.section)

		if selections.length > 0
			first.clear()

Object.defineProperty Editor.prototype, 'content',
	get: () ->
		contents = @sections.map (section) -> section.content
		contents.join('\n\n')

Object.defineProperty Editor.prototype, 'currentSection',
	get: () ->
		if !@_sectionIsCurrent or @_currentSection is null
			selections = @getSelectionBySection()
			if selections.length > 0
				@_sectionIsCurrent = true
				@_currentSection = selections[0].section
			else
				return null
		return @_currentSection

Object.defineProperty Editor.prototype, 'currentSectionIndex',
	get: () ->
		section = @currentSection
		if section?
			return @getSectionIndex(section)
		else
			return null


module.exports = Editor
