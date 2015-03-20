Selection = require('./Selection.coffee')

module.exports = class Highlight extends Selection
	classNames: []
	tag: "span"
	@matchesElement: (ele) ->
		return if ele.tagName.toLowerCase isnt @tag.toLowerCase()
		eleClassNames = ele.className.split(' ')
		for cls in @classNames
			return false if !(cls in eleClassNames)
		return true
