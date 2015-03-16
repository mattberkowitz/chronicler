Bold = require('./Bold.coffee')
DomUtils = require('./utils/DomUtils.coffee')
HighlightManager = require('./HighlightManager.coffee')
Range = require('./Range.coffee')

module.exports = class Section
	constructor: (text) ->
		@element = document.createElement(@tag)
		@content = text
		@updateElement()
	content: ""
	tag: "section"
	insert: (start, str, len = 0) ->
		#if it's at the end of string, use &nbsp; or it will get ignored
		#str = '\u00a0' if start + len is @content.length and str is ' ' #use nbsp if it's the end

		#if the previous char was &nbsp; and this one isn't turn the previous into a normal space
		pre = @content.substring(0, start)
		post = @content.substring(start + len)

		@content = pre + str + post
		@updateElement()
		@setCursorPosition(start + str.length)
		#alter selctions
	delete: (start, len) ->
		@content = @content.slice(0, start) + @content.slice(start + len)
		@updateElement()
		#alter selections
	setCursorPosition: (pos, len = 0) ->
		range = document.createRange()
		range.setStart(@element.firstChild, pos)
		range.setEnd(@element.firstChild, pos)

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
				console.log existingHighlight.contains(newHighlight), existingHighlight.intersects(newHighlight)
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

	textNodeContainingPoint: (point) ->
		return @textNodesForRange(new Range(point,0))[0]

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
				split = DomUtils.splitTextNode(highlightMe.node, highlightMe.start, highlightMe.end)
				ele = document.createElement(highlight.tag)
				DomUtils.wrapNode(split[1], ele)

		if @content?
			text = @content
			r2space = /\u0020\u0020/g
			while(r2space.test(test))
				text = test.repalce(r2space, '\u00a0 ')
			text.replace(/\u0020$/g, '\u00a0')
			@element.innerHTML = text
			for highlight in @highlights
				wrapText(highlight)

		else
			@element.childNodes.forEach (child) -> @element.removeChild(child)
			@element.appendChild(document.createTextNode(''))
