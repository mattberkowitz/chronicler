
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
		first = @getNextTextNode(first, node) if first.nodeType isnt 3
		return first

	@getLastTextNode: (node) ->
		last = @getLastDecendant(node)
		last = @getPreviousTextNode(first, node) if first.nodeType isnt 3
		return last

	@getPreviousTextNode: (node, root='p') ->

		if node is root
			return null


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
				return @getPreviousTextNode(node.previousSibling, root)


		previousLastDecendant =  @getLastDecendant(node.previousSibling)
		if previousLastDecendant.nodeType is 3 and previousLastDecendant.textContent?.length > 0
			return previousLastDecendant
		else
			return @getPreviousTextNode(previousLastDecendant, root)

	@getNextTextNode: (node, root='p') ->

		if node is root
			return null

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
				return @getNextTextNode(node.nextSibling, root)

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
		[].forEach.call node.childNodes, (child) =>
			if child.nodeType is 3
				ret.push(child)
			else
				ret = ret.concat(@getChildTextNodes(child) || [])
		return ret

	@indexInAncestorForIndexInTextNode: (ancestor, textNode, index) ->
		while(textNode = DomUtils.getPreviousTextNode(textNode, ancestor))
			index += textNode.textContent.length
		return index

	@textNodeAndIndexForElementIndex: (element, index) ->
		curPos = 0
		curNode = DomUtils.getFirstTextNode(element)

		while(curPos + curNode.textContent.length < index)
			curPos += curNode.textContent.length
			curNode = DomUtils.getNextTextNode(curNode, element)

		return {
			index: index - curPos
			node: curNode
		}

	@textNodeContainingIndex: (element, index) ->
		return DomUtils.textNodeAndIndexForElementIndex(@element, index).node

	@textNodesForRange: (element, range) ->
		curPos = 0
		curNode = DomUtils.getFirstTextNode(element)
		rangeLength = range.length

		ret = []

		while(curPos + curNode.textContent.length < range.start)
			curPos += curNode.textContent.length
			curNode = DomUtils.getNextTextNode(curNode, element)

		while(rangeLength > 0)
			rangeStart = Math.max(curPos, range.start) - curPos
			curNodeLength = curNode.textContent.length
			rangeEnd = Math.min(rangeLength, curNodeLength - rangeStart) + rangeStart

			ret.push
				node: curNode
				start: rangeStart
				end: rangeEnd

			rangeLength -= (rangeEnd - rangeStart)

			curPos += curNodeLength
			curNode = DomUtils.getNextTextNode(curNode, element)

		return ret

	@nodeDirection: (node, comparedTo) ->
		parent = comparedTo.parentNode
		nodeSiblingOfComparedTo = @closest node, (n) -> n.parentNode is parent
		return 0 if nodeSiblingOfComparedTo is comparedTo
		compareIndex = null
		compareSiblingIndex = null
		for child, i in parent.childNodes
			if child is comparedTo
				compareIndex = i
			else if child is nodeSiblingOfComparedTo
				compareSiblingIndex = i

		if !compareIndex? or !compareSiblingIndex?
			return null
		else if compareIndex > compareSiblingIndex
			return -1
		else
			return 1
