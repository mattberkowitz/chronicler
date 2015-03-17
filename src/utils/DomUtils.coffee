
module.exports = class DomUtils
	###
	Gets the decendant which displays last

	ie:
	getLastDecendant(<a>This is <span>something</span> <strong>te<em>st</em></strong></a>)
	would return the text node st (inside <em></em>)
	###
	@getLastDecendant: (node) ->
		while node.lastChild?
			node = node.lastChild
		return node

	###
	Gets the decendant which displays first
	###
	@getFirstDecendant: (node) ->
		while node.firstChild?
			node = node.firstChild
		return node

	@getFirstTextNode: (node) ->
		first = @getFirstDecendant(node)
		first = @getNextTextNode(first) if first.nodeType isnt 3
		return first

	@getLastTextNode: (node) ->
		last = @getLastDecendant(node)
		last = @getPreviousTextNode(first) if first.nodeType isnt 3
		return last

	@getPreviousTextNode: (node, root='p') ->



		#no previous sibling
		if !node.previousSibling?
			#if parent is <p> we're done
			if node is root or node.parentNode is null or (typeof root is "string" and node.parentNode.matches(root))
				return null
			else
				#recurse on parent
				return @getPreviousTextNode(node.parentNode, root)

		#if it's a text node, return it
		if node.previousSibling.nodeType is 3
			if node.previousSibling.textContent?.length > 0
				return node.previousSibling
			else
				return @getPreviousTextNode(node.previousSibling)


		previousLastDecendant =  @getLastDecendant(node.previousSibling)
		if previousLastDecendant.nodeType is 3 and previousLastDecendant.textContent?.length > 0
			return previousLastDecendant
		else
			return @getPreviousTextNode(previousLastDecendant, root)

	@getNextTextNode: (node, root='p') ->
		#no next sibling
		if !node.nextSibling?
			if node is root or node.parentNode is null or (typeof root is "string" and node.parentNode.matches(root))
				return null
			else
				return @getNextTextNode(node.parentNode, root)

		#if it's a text node, return it
		if node.nextSibling.nodeType is 3
			if node.nextSibling.textContent?.length > 0
				return node.nextSibling
			else
				return @getNextTextNode(node.nextSibling)

		nextFirstDecendant = @getFirstDecendant(node.nextSibling)
		if nextFirstDecendant.nodeType is 3 and nextFirstDecendant.textContent?.length > 0
			return nextFirstDecendant
		else
			return @getNextTextNode(nextFirstDecendant, root)

	###
	@wrapNode: (node, withNode) ->
		dummyNode = document.createTextNode('')
		parentNode = node.parentNode
		parentNode.replaceChild(dummyNode, node)
		withNode.appendChild(node)
		parentNode.replaceChild(withNode, dummyNode)
		return withNode
	###


	@splitTextNode: (textNode, points...) ->
		newNodes = [document.createTextNode(textNode.textContent.substring(0, points[0]))]
		for point, i in points
			endPoint = if i is points.length - 1 then undefined else points[i+1]
			newText = textNode.textContent.substring(point, endPoint)
			newTextNode = document.createTextNode(newText)
			newNodes.push(newTextNode)
		return newNodes

	@closest: (node, condition) ->
		while(node)
			if "string" is typeof condition and node.matches and node.matches(condition)
				return node
			else if "function" is typeof condition and condition(node)
				return node
			node = node.parentNode
		return null

	@getChildTextNodes: (node) ->
		ret = []
		[].forEach.call node.childNodes, (child) ->
			if child.nodeType is 3
				ret.push(child)
			else
				ret = ret.concat(@getChildTextNode(child))
		return ret
