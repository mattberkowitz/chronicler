

module.exports = class Section
	constructor: () ->
		@element = document.createElement(@tag)

	destroy: () ->
		@element.parentNode.removeChild(@element)
