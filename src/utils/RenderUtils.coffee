RenderUtils =
	types:
		OPEN: 0,
		CLOSE: 1,
		SELFCLOSING: 2
	renderObjectElementString: (obj, type=RenderUtils.types.OPEN) ->
		if type is this.types.SELFCLOSING
			return @renderObjectElementString(obj, @types.OPEN) + @renderObjectElementString(obj, @types.CLOSE)
		buffer = "<"
		if type is this.types.CLOSE
			buffer += '/'
		buffer += obj.tag
		if type is this.types.OPEN and obj.classNames?
			buffer += (' class="' + obj.classNames.join(' ') + '"')
			if obj.attributes?
				for k, v of obj.attributes
					buffer += " #{k}=\"#{v}\""
		buffer += '>'

		return buffer


module.exports = RenderUtils
