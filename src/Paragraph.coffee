Section = require('./Section.coffee')

module.exports = class Paragraph extends Section
	constructor: (text) ->
		super(if text? then text else "")
	tag: 'p'
