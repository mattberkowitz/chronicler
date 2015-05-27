Range = require('./Range.coffee')
DomUtils = require('./utils/DomUtils.coffee')
RenderUtils = require('./utils/RenderUtils.coffee')

Insertion = class Insertion
	section: null
	range: null
	classNames: ['insertion']
	tag: 'span'
	value: 0
	constructor: (@section, rangeStart) ->
		@range = new Range(rangeStart, 0)
	render: () ->
		RenderUtils.renderObjectElementString(@, RenderUtils.types.SELFCLOSING)

module.exports = Insertion
