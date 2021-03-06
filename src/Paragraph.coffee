Section = require('./Section.coffee')
Bold = require('./Bold.coffee')
DomUtils = require('./utils/DomUtils.coffee')
KeyUtils = require('./utils/KeyUtils.coffee')
RenderUtils = require('./utils/RenderUtils.coffee')
StringUtils = require('./utils/StringUtils.coffee')
HighlightManager = require('./HighlightManager.coffee')
Range = require('./Range.coffee')
Selection = require('./Selection.coffee')

module.exports = class Paragraph extends Section
	tag: 'p'
	constructor: (text) ->
		super()
		@element.style.whiteSpace = 'pre'
		@highlights = []
		# create an observer instance
		###
		@observer = new MutationObserver (mutations) =>
			mutations.forEach (mutation) =>
				#console.log(mutation)
				if mutation.type is 'characterData' and mutation.target.nodeType is 3
					oldVal = mutation.oldValue.replace(/\u00a0/g, ' ')
					newVal = mutation.target.textContent.replace(/\u00a0/g, ' ')
					#console.log(mutation.target, 'changed... old:', mutation.oldValue, ' new:', mutation.target.textContent)

					diff = StringUtils.diff(oldVal, newVal)
					console.log(oldVal, newVal, diff)
					index =  DomUtils.indexInAncestorForIndexInTextNode(@element, mutation.target, 0)
					for change in diff
						if !change.added && !change.removed
							index += change.value.length
						else if change.added
							@insert(index, change.value)
							index += change.value.length
						else if change.removed
							@delete(index, change.value.length)
							index -= change.value.length
					console.log('content: ', @content)

				else if mutation.type is 'childList'
					[].forEach.call mutation.addedNodes, (node) ->
						if node.nodeType is 3
							console.log('added text node ', node, ' with value:', node.textContent, mutation)
						else
							childTextNodes = DomUtils.getChildTextNodes(node)
							for textNode in childTextNodes
								console.log('added child text node ', textNode, ' with value:', node.textNode, mutation)


					[].forEach.call mutation.removedNodes, (node) =>
						if node.nodeType is 3
							console.log('removed text node ', node, ' with value:', node.textContent, mutation)
							@_ensureTextNode()
						else
							childTextNodes = DomUtils.getChildTextNodes(node)
							for textNode in childTextNodes
								console.log('added child text node ', textNode, ' with value:', node.textNode, mutation)


		# configuration of the observer:
		@observerConfig =
			attributes: false
			childList: true
			characterData: true
			characterDataOldValue: true
			attributeOldValue: false
			subtree: true

		@observer.observe(@element, @observerConfig)
		###

		@content = text
		@updateElement()

	destroy: () ->
		#@observer.disconnect()
		super()

	content: ""
	tag: "section"

	insert: (start, str, len = 0) ->
		if len > 0
			@delete(start, len)

		pre = @content.substring(0, start)
		post = @content.substring(start)

		@content = pre + str + post


		for highlight in @highlights
			if highlight.range.containsPoint(start)
				highlight.range.length += str.length
			else if start < highlight.range.start
				highlight.range.start += str.length



		@updateElement()

	delete: (start, len) ->
		@content = @content.slice(0, start) + @content.slice(start + len)

		cursorRange = new Range(start, len)
		newHighlights = []
		for highlight in @highlights
			if highlight.range.contains(cursorRange)
				highlight.length -= cursorRange.length
			else if cursorRange.contains(highlight)
				continue
			else if highlight.range.intersects(cursorRange)
				if cursorRange.start < highlight.start
					highlight.length -= (cursorRange.end - highlight.start)
				else
					highlight.length -= (highlight.end - cursorRange.start)

			if start < highlight.start
				highlight.start -= len
				if cursorRange.intersects(highlight.range)
					highlight.start += (cursorRange.end - highlight.start)


			newHighlights.push(highlight)
		@highlights = newHighlights

		@updateElement()

	setCursorPosition: (pos, len = 0) ->
		range = document.createRange()

		start = DomUtils.textNodeAndIndexForElementIndex(@element, pos)
		end = DomUtils.textNodeAndIndexForElementIndex(@element, pos + len)

		range.setStart(start.node, start.index)
		range.setEnd(end.node, end.index)

		selection = window.getSelection()
		selection.removeAllRanges()
		selection.addRange(range)

	applyHighlight: (range, name) ->
		console.log name, ' from ', range.start, ' to ', range.end, range
		highlight = HighlightManager.availableHighlights[name]
		if !highlight?
			console.error('highlight not registered')
			return

		newHighlight = new highlight(@, range)

		for existingHighlight in @highlights
			if existingHighlight instanceof highlight
				if existingHighlight.range.contains(newHighlight.range)
					return
				else if existingHighlight.range.intersects(newHighlight.range)
					existingHighlight.range.merge(newHighlight.range)
					@updateElement()
					return

		@highlights.push(newHighlight)

		@updateElement()

	render: (mode) ->
		switch mode
			when "html-dom"
				wrapText = (highlight) =>
					toHighlight = DomUtils.textNodesForRange(container, highlight.range)

					for highlightMe in toHighlight
						parent = highlightMe.node.parentNode
						split = DomUtils.splitTextNode(highlightMe.node, highlightMe.start, highlightMe.end)
						ele = document.createElement(highlight.tag)
						if split[0]
							parent.insertBefore(split[0], highlightMe.node)
						if split[1]
							parent.insertBefore(ele, highlightMe.node)
							ele.appendChild(split[1])
						if split[2]
							parent.insertBefore(split[2], highlightMe.node)
						parent.removeChild(highlightMe.node)

				container = document.createElement('div')

				text = @content
				r2space = /\u0020\u0020/g
				while(r2space.test(text))
					text = text.replace(r2space, '\u00a0 ')
				text = text.replace(/\u0020$/g, '\u00a0')
				container.innerHTML = text

				for highlight in @highlights
					wrapText(highlight)

				return container.innerHTML

			when "html-string"
				buffer = ""
				orderedHighlights = @highlights.sort (a, b) ->
					if a.range.start < b.range.start
						return -1
					else if a.range.start > b.range.start
						return 1
					else
						return 0

				text = @content

				openHighlights = []
				for char, i in text
					for highlight in orderedHighlights
						if highlight.range.start is i
							buffer += RenderUtils.renderObjectElementString(highlight, RenderUtils.types.OPEN)
							openHighlights.push(highlight)
						else if highlight.range.start > i
							break

					reverseOpenHighlights = openHighlights.reverse()
					openHighlights = []
					for highlight in reverseOpenHighlights
						if highlight.range.end is i
							for reopenedHighlight in openHighlights
								buffer += RenderUtils.renderObjectElementString(reopenedHighlight, RenderUtils.types.CLOSE)
							buffer += RenderUtils.renderObjectElementString(highlight, RenderUtils.types.CLOSE)
							for reopenedHighlight in openHighlights
								buffer += RenderUtils.renderObjectElementString(reopenedHighlight, RenderUtils.types.OPEN)
						else
							openHighlights.unshift(highlight)

					### Don't need this with whiteSpace = 'pre'
						if char is a space and
							-this is the end of the text
							-the previous buffer character is also a sapce
							-there is an opening or closing tag at the next char
						then use nbsp
					if char is ' ' and (buffer[buffer.length - 1] is ' ' or i is text.length - 1 or openHighlights.filter((h) -> i + 1 in [h.start, h.end]).length > 0)
						char = '\u00a0'
					###
					buffer += char

				return buffer

		console.error('invalid render mode')


	merge: (otherSection) ->
		offset = @content.lenth
		@content += otherSection.content
		for highlight in otherSection.highlights
			console.log highlight
			highlight.start += offset
			@applyHighlight highlight, highlight.constructor.key
		@updateElement()

	splitAtIndex: (index) ->
		newSection = new Paragraph()
		newSection.content = @content.slice(index)

		newHighlights = []
		for highlight in @highlights
			if highlight.start > index
				newSection.applyHighlight(new Range(highlight.start - index, highlight.length), highlight.constructor.key)
			else if highlight.end < index
				newHighlights.push(highlight)
			else
				diff = highlight.end - index
				newSection.applyHighlight(new Range(0, diff), highlight.constructor.key)
				highlight.length -= diff
				newHighlights.push(highlight)

		@highlights = newHighlights
		@content = @content.slice(0, index)
		@updateElement()
		newSection.updateElement()
		return newSection

	getSelection: () ->
		selection = window.getSelection()
		range = selection.getRangeAt(0)
		startDir = DomUtils.nodeDirection(range.startContainer, @element)
		endDir = DomUtils.nodeDirection(range.endContainer, @element)
		start = null
		end = null

		# selection is somewhere outside of the content editable
		return null if !startDir? or !endDir?

		# entire selection is outside of here
		return null if startDir is 1 or endDir is -1

		if startDir is -1
			start = 0
		else
			start = DomUtils.indexInAncestorForIndexInTextNode(@element, range.startContainer, range.startOffset)

		if endDir is 1
			end = @content.length
		else
			end = DomUtils.indexInAncestorForIndexInTextNode(@element, range.endContainer, range.endOffset)

		return new Selection(@, start, end-start)



	updateElement: ->
		@element.innerHTML = ''

		if !@content?
			@content = ''

		@element.innerHTML = @render('html-string')

		@_ensureTextNode()

	_ensureTextNode: ->
		return if DomUtils.getChildTextNodes(@element).length > 0
		@element.insertBefore(document.createTextNode(''), @element.firstChild)
