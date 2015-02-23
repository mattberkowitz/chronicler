module.exports = class Editor
	constructor:(input) ->
		@element = document.createElement(@tag)
		@element.innerHTML = input.value
		for node in @element.childNodes
			section = null
			if node.tagName is 'p'
				section = new Section(node)
			@insert(@sections.length, section)
	tag: "div",
	className: "remington-editor"
	sections: []
	currentSection: 0
	insert: (at, section) ->
		@sections.splice(at, 0, section)
		if @element.childNodes.length < at
			@element.appendChild(section.element)
		else
			@element.insertBefore(@element.childNodes[at], section.element)
	remove: (at) ->
		removed = @sections.splice(at, 1)
		@element.removeChild(removed[0].element)
	move: (at, to) ->
		section = @sections[at]
		@sections.splice(at, 1)
		@sections.splice(to, 0, section)
		@element.removeChild(section.element)
		@element.insertBefore(@element.childNodes[to], section.element)
