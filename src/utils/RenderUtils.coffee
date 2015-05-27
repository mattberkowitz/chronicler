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
		if type isnt this.types.CLOSE and obj.classNames?
			buffer += (' class="' + obj.classNames.join(' ') + '"')
			for k, v of obj.attributes?
				buffer += " #{k}=\"#{v}\""
		if type is this.types.SELFCLOSING
			buffer += ' /'
		buffer += '>'

		return buffer


module.exports = RenderUtils
