Bold = require('./Bold.coffee')
Italic = require('./Italic.coffee')
Addition = require('./Addition.coffee')

HighlightManger = class HighlightManager
	@availableHighlights: []
	@registerHighlight: (highlights...) ->
		for highlight in highlights
			if highlight.key?
				@availableHighlights[highlight.key] = highlight

HighlightManager.registerHighlight(Bold, Italic, Addition)

module.exports = HighlightManager
