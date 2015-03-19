JsDiff = require('diff')

StringUtils =
	diff: (a, b) -> JsDiff.diffChars(a, b)

module.exports = StringUtils
