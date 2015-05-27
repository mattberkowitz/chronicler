Insertion = require('./Insertion.coffee')


module.exports = class Deletion extends Insertion
	classNames: ['deletion', 'insertion']
	tag: 'span'
	render: () ->
		@attributes = {}
		@attributes['data-text'] = @value
		super()
