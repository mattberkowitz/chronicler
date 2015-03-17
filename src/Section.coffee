Bold = require('./Bold.coffee')
DomUtils = require('./utils/DomUtils.coffee')
HighlightManager = require('./HighlightManager.coffee')
Range = require('./Range.coffee')

module.exports = class Section
	constructor: (text) ->
		@element = document.createElement(@tag)

		# create an observer instance
		@observer = new MutationObserver (mutations) ->
			mutations.forEach (mutation) ->
				#console.log(mutation)
				if mutation.type is 'characterData' and mutation.target.nodeType is 3
					console.log(mutation.target, 'changed... old:', mutation.oldValue, ' new:', mutation.target.textContent)
				else if mutation.type is 'childList'
					[].forEach.call mutation.addedNodes, (node) ->
						if node.nodeType is 3
							console.log('added text node ', node, ' with value:', node.textContent, mutation)
						else
							childTextNodes = DomUtils.getChildTextNodes(node)
							for textNode in childTextNodes
								console.log('added child text node ', textNode, ' with value:', node.textNode, mutation)


					[].forEach.call mutation.removedNodes, (node) ->
						if node.nodeType is 3
							console.log('removed text node ', node, ' with value:', node.textContent, mutation)
						else
							childTextNodes = DomUtils.getChildTextNodes(node)
							for textNode in childTextNodes
								console.log('added child text node ', textNode, ' with value:', node.textNode, mutation)


		# configuration of the observer:
		@observerConfig =
			attributes: true
			childList: true
			characterData: true
			characterDataOldValue: true
			attributeOldValue: true
			subtree: true

		@observer.observe(@element, @observerConfig)

		@content = text
		@updateElement()

	content: ""
	tag: "section"

	insert: (start, str, len = 0) ->
		#if it's at the end of string, use &nbsp; or it will get ignored
		#str = '\u00a0' if start + len is @content.length and str is ' ' #use nbsp if it's the end

		#if the previous char was &nbsp; and this one isn't turn the previous into a normal space

		if len > 0
			@delete(start, len)

		pre = @content.substring(0, start)
		post = @content.substring(start)

		@content = pre + str + post


		for highlight in @highlights
			if highlight.containsPoint(start)
				highlight.length += str.length



		@updateElement()
		@setCursorPosition(start + str.length)



	delete: (start, len) ->
		@content = @content.slice(0, start) + @content.slice(start + len)

		cursorRange = new Range(start, len)
		newHighlights = []
		for highlight in @highlights
			if highlight.contains(cursorRange)
				highlight.length -= cursorRange.length
			else if cursorRange.contains(highlight)
				continue
			else if highlight.intersects(cursorRange)
				if cursorRange.start < highlight.start
					highlight.length -= (cursorRange.end - highlight.start)
				else
					highlight.length -= (highlight.end - cursorRange.start)

			if start < highlight.start
				highlight.start -= len
				if cursorRange.intersects(highlight)
					highlight.start += (cursorRange.end - highlight.start)


			newHighlights.push(highlight)
		@highlights = newHighlights

		@updateElement()
		@setCursorPosition(start)
	setCursorPosition: (pos, len = 0) ->
		range = document.createRange()

		start = @textNodeAndPointContainingPoint(pos)
		end = @textNodeAndPointContainingPoint(pos + len)

		range.setStart(start.node, start.point)
		range.setEnd(end.node, end.point)

		selection = window.getSelection()
		selection.removeAllRanges()
		selection.addRange(range)

	highlights: []
	applyHighlight: (range, name) ->
		highlight = HighlightManager.availableHighlights[name]
		if !highlight?
			console.error('highlight not registered')
			return

		newHighlight = new highlight(range.start, range.length)

		for existingHighlight in @highlights
			if existingHighlight instanceof highlight
				if existingHighlight.contains(newHighlight)
					return
				else if existingHighlight.intersects(newHighlight)
					existingHighlight.merge(newHighlight)
					@updateElement()
					return

		@highlights.push(newHighlight)

		@updateElement()

	render: () ->
		@element.outerHTML

	pointInSectionForPointInTextNode: (textNode, point) ->
		while(textNode = DomUtils.getPreviousTextNode(textNode, @element))
			point += textNode.textContent.length
		return point

	textNodeAndPointContainingPoint: (point) ->
		curPos = 0
		curNode = DomUtils.getFirstTextNode(@element)

		while(curPos + curNode.textContent.length < point)
			curPos += curNode.textContent.length
			curNode = DomUtils.getNextTextNode(curNode, @element)

		return {
			point: point - curPos
			node: curNode
		}

	textNodeContainingPoint: (point) ->
		return @textNodeAndPointContainingPoint(point).node

	textNodesForRange: (highlight) ->
		curPos = 0
		curNode = DomUtils.getFirstTextNode(@element)
		highlightLength = highlight.length

		ret = []

		while(curPos + curNode.textContent.length < highlight.start)
			curPos += curNode.textContent.length
			curNode = DomUtils.getNextTextNode(curNode, @element)


		while(highlightLength > 0)
			highlightStart = Math.max(curPos, highlight.start) - curPos
			curNodeLength = curNode.textContent.length
			highlightEnd = Math.min(highlightLength, curNodeLength - highlightStart) + highlightStart

			ret.push
				node: curNode
				start: highlightStart
				end: highlightEnd

			highlightLength -= (highlightEnd - highlightStart)

			curPos += curNodeLength
			curNode = DomUtils.getNextTextNode(curNode, @element)

		return ret

	updateElement: ->
		wrapText = (highlight) =>
			toHighlight = @textNodesForRange(highlight)

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

		if @content?
			text = @content
			r2space = /\u0020\u0020/g
			while(r2space.test(text))
				text = text.replace(r2space, '\u00a0 ')
			text = text.replace(/\u0020$/g, '\u00a0')
			@element.innerHTML = text

			for highlight in @highlights
				wrapText(highlight)


		else
			@element.childNodes.forEach (child) -> @element.removeChild(child)
			@element.appendChild(document.createTextNode(''))
