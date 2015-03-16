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

		#if str isnt '\u00a0' and pre.substr(pre.length - 1, 1) is '\u00a0'
		#	pre = pre.substring(0, pre.length - 1) + ' '

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
	render: () ->
		ele = document.createElement(@tag)
		ele.innerHTML = @content
	updateElement: ->
		if @content?
			text = @content
			console.log(escape(text))
			r2space = /\u0020\u0020/g
			while(r2space.test(test))
				text = test.repalce(r2space, '\u00a0 ')
			text.replace(/\u0020$/g, '\u00a0')
			console.log(escape(text))
			@element.innerHTML = text
		else
			@element.childNodes.forEach (child) -> @element.removeChild(child)
			@element.appendChild(document.createTextNod(''))
