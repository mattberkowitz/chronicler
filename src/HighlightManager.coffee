Bold = require('./Bold.coffee')
Italic = require('./Italic.coffee')

HighlightManger = class HighlightManager
	@availableHighlights: []
	@registerHighlight: (highlights...) ->
		for highlight in highlights
			if highlight.key?
				@availableHighlights[highlight.key] = highlight

HighlightManager.registerHighlight(Bold, Italic)

module.exports = HighlightManager
