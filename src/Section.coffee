module.exports = class Section
	constructor: (text) ->
		@element = document.createElement(@tag)
		@content = text
		@updateElement()
	content: ""
	tag: "section"
	insert: (start, str, len = 0) ->
		@content = @content.slice(0, start) + str + @content.slice(start + len)
		#alter selctiosn
	remove: (start, len) ->
		@content = @content.slice(0, start) + @content.slice(start + len)
		#alter selections
	render: () ->
		ele = document.createElement(@tag)
		ele.innerHTML = @content
	updateElement: ->
		@element.innerHTML = @content
