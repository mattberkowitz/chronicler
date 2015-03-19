RenderUtils =
	types:
		OPEN: 0,
		CLOSE: 1,
		SELFCLOSING: 2
	renderObjectElementString: (obj, type=RenderUtils.types.OPEN) ->
		buffer = "<"
		if type is this.types.CLOSE
			buffer += '/'
		buffer += obj.tag
		if type is this.types.OPEN and obj.classNames?
			buffer += (' class="' + obj.classNames.join(' ') + '"')
		if type is this.types.SELFCLOSING
			buffer += ' /'
		buffer += '>'
		
		return buffer


module.exports = RenderUtils
