###
# Nested Tree based with data and rational number support
# based on jQuery sortable
# Written in CoffeeScript, as the syntax is nice.
#
# For debugging/ development it requires log4javascript
# 
# Derived from Manuele J Sarfattis work (https://github.com/mjsarfatti)
#
# Still under MIT license.
#
# Source can be found here:
#
# https://github.com/leifcr/nestedSortableTree
#
# Current version : v0.1.1
###

# Reference jQuery
$ = jQuery

# Extend ui.sortable
$.widget "ui.nestedSortableTree", $.ui.sortable,
  options:
    errorClass: "tree-error"
    listType: "ol"
    maxLevels: 0
    nested_debug: true
    tabSize: 20
    rtl: false
    use_rational_numbers: true
    doNotClear: false
    disableNesting: "no-nest"
    protectRoot: false
    rootID: null
    isAllowed: (item, parent) ->
      true  

  # TODO: verify that this will still be called even if overridden
    start: (event, ui) ->
        ui.item.data('startIndex', ui.item.index());

    stop: (event, ui) ->
        ui.item.data('stopIndex', ui.item.index());

    # rootID: null
    # FIX TODO: options = $.extend $ui.sortable::options, options

  _create: ->
    @element.data "sortable", @element.data("nestedSortableTree")
    
    if (@options.nested_debug)
      @nestedLogger = log4javascript.getLogger()
      appender = new log4javascript.InPageAppender("logger")
      appender.setWidth("100%")
      appender.setHeight("100%")
      appender.setThreshold(log4javascript.Level.ALL)
      @nestedLogger.addAppender(appender)
    
    @log("nestedSortableTree create", false)
    #log("options: #{}")
    if !@element.is(@options.listType)
        throw new Error("nestedSortableTree: Wrong listtype... #{@element.get(0).tagname} is not #{options.listtype}");

    $.ui.sortable::_create.apply this, arguments
  
  destroy: ->
    @log("nestedSortableTree destroy")
    @element.removeData("nestedSortableTree").unbind ".nestedSortableTree"
    $.ui.sortable::destroy.apply this, arguments

  log: (msg, node_text = true) ->
    #console.log msg if @options.nested_debug
    if (@options.nested_debug)
      if node_text
        @nestedLogger.debug "#{@element_text_without_children(@currentItem)}: ", msg 
      else
        @nestedLogger.debug msg 

  element_text_without_children: (node) ->
    return "undefined" if typeof node == 'undefined'
    return "" if !@options.nested_debug
    return "null-object" if node == null
    rettext = node.clone().find("li").remove().end().text().replace(/(\r\n|\n|\r)/gm,"");
    rettext = rettext.replace(/(^\s*)|(\s*$)/gi,"");
    rettext = rettext.replace(/[ ]{2,}/gi," ");
    # text = text.replace(/\n /,"\n");

  _mouseDrag: (event) ->
    #Compute the helpers position
    @position = @_generatePosition(event)
    @positionAbs = @_convertPositionTo("absolute")
    @lastPositionAbs = @positionAbs  unless @lastPositionAbs

    # call scrolling
    @_internal_do_scrolling(event)

    #Regenerate the absolute position used for position checks
    @positionAbs = @_convertPositionTo("absolute")
    
    # Find the top offset before rearrangement,
    @previousTopOffset = @placeholder.offset().top

    #Set the helper position
    @helper[0].style.left = @position.left + "px"  if not @options.axis or @options.axis isnt "y"
    @helper[0].style.top = @position.top + "px"  if not @options.axis or @options.axis isnt "x"

    # rearrange
    @_internal_rearrange(event)

    #Post events to containers
    @_contactContainers(event)

    #Interconnect with droppables
    $.ui.ddmanager.drag(this, event) if $.ui.ddmanager

    #Call callbacks
    @_trigger("sort", event, @_uiHash())
    @lastPositionAbs = @positionAbs
    false

  _mouseStop: (event, noPropagation) ->
    
    # If the item is in a position not allowed, send it back
    if @beyondMaxLevels
      @placeholder.removeClass @options.errorClass
      if @domPosition.prev
        $(@domPosition.prev).after @placeholder
      else
        $(@domPosition.parent).prepend @placeholder
      @_trigger "revert", event, @_uiHash()
    
    # Clean last empty ul/ol

    while i >= 0
      i = @items.length - 1
      item = @items[i].item[0]
      @_clearEmpty item
      i--

    $.ui.sortable::_mouseStop.apply this, arguments
    # store previous ancestor keys
    @previous_anc_keys = @_get_ancestor_keys(@currentItem[0])
    false

  _clear: (event) ->
    retval = $.ui.sortable::_clear.apply this, arguments
    @_update_nv_dv() if @options.use_rational_numbers
    retval

  _update_nv_dv: (event) ->
    #
    # @log "_update_nv_dv #{JSON.stringify @currentItem[0]}"
    # @log "_update_nv_dv #{JSON.stringify $(@currentItem.data())}"
    # get ancestor keys

    new_anc_keys  = @_get_ancestor_keys(@currentItem[0])
    startIndex    = @currentItem.data("startIndex")
    stopIndex     = @currentItem.data("stopIndex")
    # @log "_update_nv_dv: new ancestor: #{JSON.stringify(new_anc_keys)}"
    # @log "startidx: #{startIndex} stopidx: #{stopIndex}"
    # if both ancestor keys and startIndex/stopIndex is equal. return...
    if (@_compare_keys(@previous_anc_keys, new_anc_keys)) and (startIndex == stopIndex)
      @log "_update_nv_dv: Same position. Item not moved"
      return false

    # calculate new nv/dv/snv/sdv
    new_keys =  @_create_keys_from_ancestor_keys( new_anc_keys, (stopIndex + 1) )

    @log "_update_nv_dv: New keys #{JSON.stringify(new_keys)}"

    # set new nv dv
    @_set_nv_dv(@currentItem, new_keys, new_anc_keys)
    true

  _create_keys_from_ancestor_keys: (ancestor_keys, position) ->
    @_create_key_array(
      ancestor_keys["nv"] + (ancestor_keys["snv"] * (position)),
      ancestor_keys["dv"] + (ancestor_keys["sdv"] * (position)),
      ancestor_keys["nv"] + (ancestor_keys["snv"] * (position + 1)),
      ancestor_keys["dv"] + (ancestor_keys["sdv"] * (position + 1))
    )
  
  _compare_keys: (keyset1, keyset2) ->
    if keyset1["nv"] is keyset2["nv"] and
    keyset1["dv"] is keyset2["dv"] and
    keyset1["snv"] is keyset2["snv"] and
    keyset1["sdv"] is keyset2["sdv"]
      return true
    return false

  _check_if_correct_ancestor: (node) ->
    @log "_check_if_correct_ancestor"
    false

  _check_if_conflicting_items: (keys) ->
    @log "_check_if_conflicting_items"
    # get parent node
    # iterate over children to see if any has same nv/dv as we want to set
    false

  _get_conflicting_items: (node) ->
    @log "_get_conflicting_items"

  _get_ancestor_keys: (node) ->
    parentItem = (if (node.parentNode.parentNode and $(node.parentNode.parentNode).closest(".ui-sortable").length) then $(node.parentNode.parentNode) else null)
    parent_keys = @_create_key_array(0,1,1,0) if parentItem is null
    parent_keys = @_create_key_array_from_data_attr(parentItem.data()) if parentItem isnt null
#    @log "_get_ancestor_keys #{@element_text_without_children parentItem} - #{JSON.stringify parent_keys }"
    parent_keys
  
  _sibling_count: (node) ->
    0

  _position_from_nv_dv: (node) ->
    0 

  _position_from_parent: (node) ->
    # UNUSED #
    # UNUSED #

    #@log "_position_from_parent on #{@element_text_without_children(node)}"

    # position = 0
    # previousItem = (if node.previousSibling then $(node.previousSibling) else null)
    # if previousItem isnt null
    #   @log "_position_from_parent previousItem: #{@element_text_without_children(previousItem)}" 
    # else 
    #   @log "_position_from_parent previousItem: null"
    # if previousItem?
    #   while previousItem isnt null
    #     position++ if (previousItem[0] isnt node) and (previousItem[0] isnt @helper[0])
    #     previousItem = (if previousItem[0].previousSibling then $(previousItem[0].previousSibling) else null)
    #     if previousItem isnt null
    #       @log "_position_from_parent previousItem: #{previousItem[0].id} #{@element_text_without_children(previousItem)}" 
    #     else 
    #       @log "_position_from_parent previousItem: null"

    # parentItem = node.parentNode
    # @log parentItem


    # @log "_position_from_parent: #{position}"
    # position = 1


  _set_nv_dv: (node, keys, ancestor_keys, check_conflict = true) ->
    node.attr("data-nv", keys["nv"])
    node.attr("data-dv", keys["dv"])
    node.attr("data-snv", keys["snv"])
    node.attr("data-sdv", keys["sdv"])
    @log "#{@element_text_without_children(node)}: _set_nv_dv #{JSON.stringify(keys)}", false

    # if conflicting sibling see if conflict is above or below.
    if (check_conflict)
      items = $("li[data-nv=\"#{keys["nv"]}\"][data-dv=\"#{keys["dv"]}\"][id != \"#{node.attr("id")}\"]")
      @log "Number of conflicting items: #{items.length}"

      # TODO: implement support for multiple conflicts ?
      # while i >= 0
      #   i = @items.length - 1
      #   item = @items[i].item[0]
      #   @_clearEmpty item
      #   i--

      if items.length > 0
        @log "Conflicting item #{@element_text_without_children($(items[0]))} Index: #{$(items[0]).index()}"
        # there are conflicting items.
        # if below, move to next position
        @log "Node idx #{node.index()}"
        conflict_node = $(items[0]);
        new_keys = @_create_keys_from_ancestor_keys(ancestor_keys, conflict_node.index() + 1)
        @log "Conflicting node New keys #{JSON.stringify(new_keys)}"
        @_set_nv_dv(conflict_node, new_keys, ancestor_keys)

    # See if there are any children
    # process children since "node has moved!"
    # should not check for conflicts on children, as conflicting items on same level will move their children as well
    @_set_nv_dv_xl_child $(child), keys for child in node.children(@options.listType)
    true

  _set_nv_dv_xl_child: (node, parent_keys) ->
    @_set_nv_dv_li_child $(child), parent_keys, i + 1 for child, i in node.children("li")
    true

  _set_nv_dv_li_child: (node, parent_keys, idx) ->
    @log("#{@element_text_without_children($(node))}: Moving child item, idx: #{idx}", false)
    new_keys = @_create_keys_from_ancestor_keys(parent_keys, idx)
    @_set_nv_dv(node, new_keys, parent_keys, false)
    @_set_nv_dv_xl_child $(child), new_keys for child in node.children(@options.listType)
    true

  _create_key_array: (nv, dv, snv, sdv) ->
    key_array = # initally set root keys
      nv: nv
      dv: dv
      snv: snv
      sdv: sdv

  _create_key_array_from_data_attr: (data_attr) ->
    @_create_key_array(data_attr["nv"], data_attr["dv"], data_attr["snv"], data_attr["sdv"])

  # customized rearrange
  _internal_rearrange: (event)->
    #Rearrange 
    # this is converted to coffee directly from jquery-ui sortables source
    o = @options
    i = @items.length
    while i > 0
      i-- 
#      i for i in [@items.length..0] ->
      #Cache variables and intersection, continue if no intersection
      item = @items[i]
      itemElement = item.item[0]
      intersection = @_intersectsWithPointer(item)
      continue  unless intersection      
      
      if itemElement isnt @currentItem[0] and
      @placeholder[if intersection is 1 then "next" else "prev"]()[0] isnt itemElement and
      not $.contains(@placeholder[0], itemElement) and 
      ((if o.type is "semi-dynamic" then not $.contains(@element[0], itemElement) else true))
        $(itemElement).mouseenter()
        @direction = (if intersection is 1 then "down" else "up")
        if o.tolerance is "pointer" or @_intersectsWithSides(item)
          $(itemElement).mouseleave();
          @_rearrange event, item
        else
          break
        # # Clear emtpy ul's/ol's
        @_clearEmpty(itemElement);
        @_trigger "change", event, @_uiHash()
        break
      #i--
      
    # do nested rearrange stuff

    # find parent item
    parentItem = (if (@placeholder[0].parentNode.parentNode and $(@placeholder[0].parentNode.parentNode).closest(".ui-sortable").length) then $(@placeholder[0].parentNode.parentNode) else null)
    level = @_getLevel(@placeholder)
    childLevels = @_getChildLevels(@helper)
    
    # To find the previous sibling in the list, keep backtracking until we hit a valid list item.
    previousItem = (if @placeholder[0].previousSibling then $(@placeholder[0].previousSibling) else null)
    if previousItem?
      while previousItem[0].nodeName.toLowerCase() isnt "li" or previousItem[0] is @currentItem[0] or previousItem[0] is @helper[0]
        if previousItem[0].previousSibling
          previousItem = $(previousItem[0].previousSibling)
        else
          previousItem = null
          break
    
    # To find the next sibling in the list, keep stepping forward until we hit a valid list item.
    nextItem = (if @placeholder[0].nextSibling then $(@placeholder[0].nextSibling) else null)
    if nextItem?
      while nextItem[0].nodeName.toLowerCase() isnt "li" or nextItem[0] is @currentItem[0] or nextItem[0] is @helper[0]
        if nextItem[0].nextSibling
          nextItem = $(nextItem[0].nextSibling)
        else
          nextItem = null
          break
    @beyondMaxLevels = 0
    
    # If the item is moved to the left, send it to its parent's level unless there are siblings below it.
    if parentItem? and not nextItem? and
    (o.rtl and (@positionAbs.left + @helper.outerWidth() > parentItem.offset().left + parentItem.outerWidth()) or
    not o.rtl and (@positionAbs.left < parentItem.offset().left))
      parentItem.after @placeholder[0]
      @_clearEmpty parentItem[0]
      @_trigger "change", event, @_uiHash()
    
    # If the item is below a sibling and is moved to the right, make it a child of that sibling.
    else if previousItem? and (o.rtl and (@positionAbs.left + @helper.outerWidth() < previousItem.offset().left + previousItem.outerWidth() - o.tabSize) or not o.rtl and (@positionAbs.left > previousItem.offset().left + o.tabSize))
      @_isAllowed previousItem, level, level + childLevels + 1
      previousItem[0].appendChild document.createElement(o.listType)  unless previousItem.children(o.listType).length
      # If this item is being moved from the top, add it to the top of the list.
      if @previousTopOffset and (@previousTopOffset <= previousItem.offset().top)
        previousItem.children(o.listType).prepend @placeholder
      
      # Otherwise, add it to the bottom of the list.
      else
        previousItem.children(o.listType)[0].appendChild @placeholder[0]
      @_trigger "change", event, @_uiHash()
    else
      @_isAllowed parentItem, level, level + childLevels

    true
  
  # from jquery.ui.sortables copy/paste/converted
  _internal_do_scrolling: (event)->
    #Do scrolling
    # this is part of mouse drag, but taken out to make source readable
    if @options.scroll
      o = @options
      scrolled = false
      if @scrollParent[0] isnt document and @scrollParent[0].tagName isnt "HTML"
        if (@overflowOffset.top + @scrollParent[0].offsetHeight) - event.pageY < o.scrollSensitivity
          @scrollParent[0].scrollTop = scrolled = @scrollParent[0].scrollTop + o.scrollSpeed
        else @scrollParent[0].scrollTop = scrolled = @scrollParent[0].scrollTop - o.scrollSpeed  if event.pageY - @overflowOffset.top < o.scrollSensitivity
        if (@overflowOffset.left + @scrollParent[0].offsetWidth) - event.pageX < o.scrollSensitivity
          @scrollParent[0].scrollLeft = scrolled = @scrollParent[0].scrollLeft + o.scrollSpeed
        else @scrollParent[0].scrollLeft = scrolled = @scrollParent[0].scrollLeft - o.scrollSpeed  if event.pageX - @overflowOffset.left < o.scrollSensitivity
      else
        if event.pageY - $(document).scrollTop() < o.scrollSensitivity
          scrolled = $(document).scrollTop($(document).scrollTop() - o.scrollSpeed)
        else scrolled = $(document).scrollTop($(document).scrollTop() + o.scrollSpeed)  if $(window).height() - (event.pageY - $(document).scrollTop()) < o.scrollSensitivity
        if event.pageX - $(document).scrollLeft() < o.scrollSensitivity
          scrolled = $(document).scrollLeft($(document).scrollLeft() - o.scrollSpeed)
        else scrolled = $(document).scrollLeft($(document).scrollLeft() + o.scrollSpeed)  if $(window).width() - (event.pageX - $(document).scrollLeft()) < o.scrollSensitivity
      $.ui.ddmanager.prepareOffsets this, event  if scrolled isnt false and $.ui.ddmanager and not o.dropBehaviour
      true

  _clearEmpty: (item) ->
    emptyList = $(item).children(@options.listType)
    emptyList.remove() if emptyList.length and not emptyList.children().length and not @options.doNotClear

  _getLevel: (item) ->
    level = 1
    if @options.listType
      list = item.closest(@options.listType)
      until list.is(".ui-sortable")
        level++
        list = list.parent().closest(@options.listType)
    level

  _getChildLevels: (parent, depth) ->
    self = this
    o = @options
    result = 0
    depth = depth or 0
    $(parent).children(o.listType).children(o.items).each (index, child) ->
      result = Math.max(self._getChildLevels(child, depth + 1), result)

    (if depth then result + 1 else result)

  _isAllowed: (parentItem, level, levels) ->
    o = @options

    # NOTE: level isn't used. can probably be removed

    # protectRoot and custom isAllowed is removed. dont' need it yet
    # if not o.isAllowed(@placeholder, parentItem) or 
    #   parentItem and parentItem.hasClass(o.disableNesting) or 
    #   o.protectRoot and (not parentItem? and not isRoot or isRoot and level > 1)

    #Are we trying to nest under a no-nest 
    # or are we nesting too deep?
    if not parentItem? or not (parentItem.hasClass(o.disableNesting))
      if o.maxLevels < levels and o.maxLevels isnt 0
        @placeholder.addClass o.errorClass
        @beyondMaxLevels = levels - o.maxLevels
      else
        @placeholder.removeClass o.errorClass
        @beyondMaxLevels = 0
    else
      @placeholder.addClass o.errorClass
      if o.maxLevels < levels and o.maxLevels isnt 0
        @beyondMaxLevels = levels - o.maxLevels
      else
        @beyondMaxLevels = 1      

  serialize: (options) ->
    o = $.extend({}, @options, options)
    items = @_getItemsAsjQuery(o and o.connected)
    str = []
    _master_this = this;
    $(items).each ->
      res = ($(o.item or this).attr(o.attribute or "id") or "").match(o.expression or (/(.+)[-=_](.+)/))
      pid = ($(o.item or this).parent(o.listType).parent(o.items).attr(o.attribute or "id") or "").match(o.expression or (/(.+)[-=_](.+)/))
      # push the parent node
      str.push ((o.key or res[1]) + "[" + ((if o.key and o.expression then res[1] else res[2])) + "][parent]") + "=" + ((if pid then ((if o.key and o.expression then pid[1] else pid[2])) else o.rootID))  if res
      # push the nv
      str.push ((o.key or res[1]) + "[" + ((if o.key and o.expression then res[1] else res[2])) + "][nv]") + "=" + $(o.item or this).attr("data-nv")
      # push the dv
      str.push ((o.key or res[1]) + "[" + ((if o.key and o.expression then res[1] else res[2])) + "][dv]") + "=" + $(o.item or this).attr("data-dv")
      # push the snv
      str.push ((o.key or res[1]) + "[" + ((if o.key and o.expression then res[1] else res[2])) + "][snv]") + "=" + $(o.item or this).attr("data-snv")
      # push the sdv
      str.push ((o.key or res[1]) + "[" + ((if o.key and o.expression then res[1] else res[2])) + "][sdv]") + "=" + $(o.item or this).attr("data-sdv")

    str.push o.key + "="  if not str.length and o.key
    str.join "&"

  toArray: (options) ->
    o = $.extend({}, @options, options)
    @startDepth = o.startDepthCount or 0
    @ret_arr = []
    left = 2
    @ret_arr.push
      item_id: o.rootID
      parent_id: "none"
      depth: @startDepth
      left: 1
      right: ($(o.items, @element).length + 1) * 2
      nv: 0
      dv: 1
      snv: 1
      sdv: 0

    _master_this = this

    $(@element).children(o.items).each ->
      left = _master_this._recursiveArray($(this), _master_this.startDepth + 1, o, _master_this, left)      
    @ret_arr = @ret_arr.sort((a, b) ->
      a.left - b.left
    )
    @ret_arr

  _recursiveArray: (item, depth, o, master, left) ->
    right = left + 1
    id = undefined
    pid = undefined
    if item.children(o.listType).children(o.items).length > 0
      depth++
      item.children(o.listType).children(o.items).each ->
        right = master._recursiveArray($(this), depth, o, master, right)

      depth--
    id = (item.attr(o.attribute or "id")).match(o.expression or (/(.+)[-=_](.+)/))
    if depth is @startDepth + 1
      pid = o.rootID
    else
      parentItem = (item.parent(o.listType).parent(o.items).attr(o.attribute or "id")).match(o.expression or (/(.+)[-=_](.+)/))
      pid = parentItem[2]
    if id
      @ret_arr.push
        item_id: id[2]
        parent_id: pid
        depth: depth
        left: left
        right: right
        nv: item.attr("data-nv")
        dv: item.attr("data-dv")
        snv: item.attr("data-snv")
        sdv: item.attr("data-sdv")

    left = right + 1
    left


$.ui.nestedSortableTree.prototype.options = $.extend({}, $.ui.sortable.prototype.options, $.ui.nestedSortableTree.prototype.options);