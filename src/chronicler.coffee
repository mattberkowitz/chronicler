window.Chronicler =
	Editor: require('./Editor.coffee')
	Paragraph: require('./Paragraph.coffee')
	HighlightManager: require('./HighlightManager.coffee')
	Utils:
		Dom: require('./utils/DomUtils.coffee')
		Key: require('./utils/KeyUtils.coffee')
		String: require('./utils/StringUtils.coffee')
