JsDiff = require('diff')

StringUtils =
	diff: (a, b) -> JsDiff.diffChars(a, b)
	diffWords: (a, b) -> JsDiff.diffWords(a, b)

module.exports = StringUtils
