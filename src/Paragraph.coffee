Section = require('./Section.coffee')
Bold = require('./Bold.coffee')
DomUtils = require('./utils/DomUtils.coffee')
KeyUtils = require('./utils/KeyUtils.coffee')
RenderUtils = require('./utils/RenderUtils.coffee')
StringUtils = require('./utils/StringUtils.coffee')
HighlightManager = require('./HighlightManager.coffee')
Range = require('./Range.coffee')
Selection = require('./Selection.coffee')
Deletion = require('./Deletion.coffee')
Addition = require('./Addition.coffee')

module.exports = class Paragraph extends Section
	tag: 'p'
	constructor: (text) ->
		super()
		@element.style.whiteSpace = 'pre'
		@highlights = []
		@insertions = []
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

	insert: (start, str, len = 0, silent=false) ->
		if len > 0
			@delete(start, len, true)

		pre = @content.substring(0, start)
		post = @content.substring(start)

		@content = pre + str + post

		for insertion in @insertions
			if insertion.start > start
				console.log 'shift inesertion'
				insertion.start += str.length


		for highlight in @highlights
			if highlight.range.containsPoint(start)
				highlight.range.length += str.length
			else if start < highlight.range.start
				highlight.range.start += str.length

		if !silent
			@addChange(@content)
			@updateElement()

	delete: (start, len, silent=false) ->
		@content = @content.slice(0, start) + @content.slice(start + len)

		cursorRange = new Range(start, len)

		newInsertions = []
		for insertion in @insertions

			continue if cursorRange.containsPoint(insertion.start)

			if cursorRange.start < insertion.start
				console.log 'shift inesertion', insertion
				insertion.start -= cursorRange.length

			newInsertions.push(insertion)
		@insertions = newInsertions

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

		if !silent
			@addChange(@content)
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

	trackChangesOn: () -> @previousVersions? and @previousVersions.length


	setChangeSet: (changes) ->
		@previousVersions = [].concat(changes, [{value:@content}])
		@calcTrackChanges()
		console.log([].concat(@previousVersions).map (i) -> i.value)

	addChange: (val) ->
		@previousVersions = [] if !@previousVersions?
		@previousVersions.push
			value: val
		@calcTrackChanges()
		console.log([].concat(@previousVersions).map (i) -> i.value)

	calcTrackChanges: () ->
		if !@trackChangesOn()
			return

		changeList = @previousVersions#[].concat(@previousVersions, [{value:@content}])

		tempPara = new Paragraph(changeList[0].value);
		for i in [1...changeList.length]
			diff = StringUtils.diff(tempPara.content, changeList[i].value)
			index = 0
			for change in diff
				if change.added
					tempPara.insert(index, change.value, 0, true)
					tempPara.applyHighlight(new Range(index, change.value.length), "addition")
					index+=change.value.length
				if change.removed
					tempPara.delete(index, change.value.length, true)
					tempPara.addInsertion(index, "delete", value: change.value)
					#index-=change.value.length;
				if !change.removed and !change.added
					index+=change.value.length;

		@insertions = @insertions.filter (insertion) -> !(insertion instanceof Deletion)
		@insertions = @insertions.concat(tempPara.insertions)
		@highlights = @highlights.filter (highlight) -> !(highlight instanceof Addition)
		@highlights = @highlights.concat(tempPara.highlights)

		@updateElement()

	addInsertion: (start, name, options) ->
		console.log('!',start)
		deletion = new Deletion(@, start)
		deletion.value = options?.value || ''
		insertAt = 0
		@insertions.forEach (insertion, index) ->
			insertAt = index if insertion.start < deletion.start
		@insertions.splice(insertAt, 0, deletion)

	applyHighlight: (range, name) ->
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
				orderedHighlights = @highlights.sort (a, b) -> (a.range.start - b.range.start) / Math.abs(a.range.start - b.range.start)
				orderedInsertions = @insertions.sort (a, b) -> (a.range.start - b.range.start) / Math.abs(a.range.start - b.range.start)

				text = @content

				openHighlights = []
				for char, i in text

					for insertion in @insertions
						if insertion.range.start is i
							buffer += insertion.render()
						else if insertion.range.start > i
							break

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
