Bold = require('./Bold.coffee')

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
	applyHighlight: (range, highlight) ->

		### Need to figure out how to handle this circular dependance differently...
		if !Editor.availableHighlights[highlight]?
			console.error('highlight not registered')
			return
		@highlights.push(new Editor.availableHighlights[highlight](range.start, range.length))
		###
		if highlight is "bold"
			@highlights.push(new Bold(range.start, range.length))

		@updateElement()
	render: () ->
		@element.outerHTML
	updateElement: ->

		wrapText = (textNode, highlight) ->
			pre = textNode.textContent.substr(0, highlight.start)
			text = textNode.textContent.substr(highlight.start, highlight.length)
			post = textNode.textContent.substr(highlight.start + highlight.length)


			textNode.textContent = pre
			newNode = document.createElement(highlight.tagName)
			newNode.innerText = text

			textNode.parentNode.insertBefore(newNode, textNode.nextSibling)
			newNode.parentNode.insertBefore(document.createTextNode(post), newNode.nextSibling)

		if @content?
			text = @content
			r2space = /\u0020\u0020/g
			while(r2space.test(test))
				text = test.repalce(r2space, '\u00a0 ')
			text.replace(/\u0020$/g, '\u00a0')
			@element.innerHTML = text
			for highlight in @highlights
				wrapText(@element.firstChild, highlight)
		else
			@element.childNodes.forEach (child) -> @element.removeChild(child)
			@element.appendChild(document.createTextNode(''))
