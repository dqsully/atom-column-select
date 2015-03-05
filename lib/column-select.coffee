module.exports =

  activate: ->
    atom.commands.add 'atom-text-editor', 'column-select:up', =>
      @columnSelect false, 1
    atom.commands.add 'atom-text-editor', 'column-select:down', =>
      @columnSelect true, 1
    atom.commands.add 'atom-text-editor', 'column-select:pageup', =>
      @columnSelect false, 'page'
    atom.commands.add 'atom-text-editor', 'column-select:pagedown', =>
      @columnSelect true, 'page'
    atom.commands.add 'atom-text-editor', 'column-select:top', =>
      @columnSelect false, 0
    atom.commands.add 'atom-text-editor', 'column-select:bottom', =>
      @columnSelect true, 0

  allSelectionsAtEnd: (editor, selections) ->
    # ranges = for i in [0...Math.max(selections.length, 1000)]
    #   selections[i].getBufferRange()
    ranges = (selection.getBufferRange() for selection in selections)
    # Make sure they are not all at the beginning of empty lines.
    return false if ranges.every (r) ->
      r.isEmpty() and r.start.column == 0
    return ranges.every (r) ->
      r.isEmpty() and r.start.column == editor.buffer.lineLengthForRow(r.start.row)

  doSelect: (editor, tabRanges, forward, numLines, atEnd) ->
    # Determine the range of lines we are allowed to look at.
    tailRange = tabRanges[tabRanges.length-1]
    range = tailRange.range.copy()
    if forward
      startRow = range.end.row + 1
      endRow = editor.getLastBufferRow()
      return if startRow > endRow
    else
      startRow = range.start.row - 1
      endRow = 0
      return if startRow < 0

    # Count of lines checked.
    lineCount = 0
    # Count of selections added.
    selCount = 0
    previousRow = range.start.row
    visualColumnStart = tailRange.tabColumnStart
    visualColumnEnd = tailRange.tabColumnEnd

    rangesToAdd = []

    for row in [startRow..endRow]
      lineCount += 1
      range.start.row = row
      range.end.row = row

      if atEnd
        # Force selection to end of line.
        range.start.column = editor.buffer.lineLengthForRow(range.start.row)
        range.end.column = range.start.column
      else
        # Skip lines that are too short.
        # Adjust column for tabs.
        continue if @fixTabRange(
          editor, range, visualColumnStart, visualColumnEnd)

      rangesToAdd.push(range)
      # editor.addSelectionForBufferRange(range)
      selCount += 1
      # Must add at least 1 selection.
      break if numLines and lineCount >= numLines and selCount > 0
      range = range.copy()
      previousRow = row
    editor.mergeIntersectingSelections ->
      editor.addSelectionForBufferRange(range) for range in rangesToAdd
      return
    return

  undoSelect: (editor, tabRanges, forward, numLines) ->
    total = Math.min(numLines, tabRanges.length-1)
    rangeIndex = tabRanges.length-1
    for _ in [0...total]
      tabRange = tabRanges[rangeIndex]
      tabRange.selection.destroy()
      rangeIndex -= 1
    lastRange = tabRanges[rangeIndex]
    editor.scrollToBufferPosition(lastRange.range.start)

  # Perform the column select command.
  #
  # forward - True if the motion is forward (down), false for backward (up).
  # numLines - The number of lines to select.  'page' means one screenful,
  #            0 means till the beginning/end.
  columnSelect: (forward, numLines) ->
    # start = process.hrtime()
    if editor = atom.workspace.getActiveTextEditor()
      selections = editor.getSelections()
      groupedRanges = @selectionsToColumns(editor, selections)
      if numLines == 'page'
        numLines = editor.getRowsPerPage()
      else if numLines == 0
        numLines = editor.getLineCount()
      atEnd = @allSelectionsAtEnd(editor, selections)
      for _, tabRanges of groupedRanges
        if @isUndo(tabRanges, forward)
          @undoSelect(editor, tabRanges, forward, numLines)
        else
          @doSelect(editor, tabRanges, forward, numLines, atEnd)
    # diff = process.hrtime(start)
    # console.log("#{diff}")

  isUndo: (tabRanges, forward) ->
    return false if tabRanges.length == 1
    if tabRanges[0].row > tabRanges[1].row
      # Rows are decreasing (moving up/backwards) in order.
      return forward
    else
      # Rows are increasing (moving down/forwards) in order.
      return not forward

  # Groups the selections into arrays of selections that share the same
  # column range.
  #
  # NOTE: This does not consider discontiguous rows.  That's a bizarre use
  # case, and I'm not even sure what the expected behavior should be.
  #
  # Key is 'x,y' where x and y are the start/end column numbers.
  # Value is a list of "TabRange" objects in that column (see makeTabRange).
  selectionsToColumns: (editor, selections) ->
    result = {}
    for selection in selections
      range = selection.getBufferRange()
      if range.start.row != range.end.row
        # Skip selections that span multiple lines.
        continue
      tabRange = @makeTabRange(editor, selection)
      key = [tabRange.tabColumnStart, tabRange.tabColumnEnd]
      rangesInCol = (result[key] or (result[key] = [])).push(tabRange)
    return result

  # Calculates the visual column number considering tabs.
  #
  # selection - The Selection object, should start and end on the same line.
  #
  # Returns a an object with these keys:
  # - tabColumnStart
  # - tabColumnEnd
  # - row - The row value (should match start and end).
  # - range - The original Range.
  # - selection - The original Selection.
  makeTabRange: (editor, selection) ->
    range = selection.getBufferRange()
    line = editor.lineTextForBufferRow(range.start.row)
    tabLength = editor.getTabLength()
    visualColumn = 0
    result =
      row: range.start.row
      range: range
      selection: selection
    for x in [0..range.end.column]
      if x == range.start.column
        result.tabColumnStart = visualColumn
      if x == range.end.column
        result.tabColumnEnd = visualColumn
      if line[x] == '\t'
        visualColumn += tabLength - (visualColumn % tabLength)
      else
        visualColumn += 1
    return result

  # Compute the actual column from a visual column.
  columnFromTabColumn: (editor, column, row) ->
    line = editor.lineForBufferRow(row)
    tabLength = editor.getTabLength()
    visualColumn = 0
    for actualColumn in [0...line.length]
      if visualColumn >= column
        break
      if line[actualColumn] == '\t'
        visualColumn += tabLength - (visualColumn % tabLength)
      else
        visualColumn += 1
    return actualColumn

  # Mutates the range object so that its columns match the given visual columns.
  #
  # Returns true if the range was completely clipped.
  fixTabRange: (editor, range, visualColumnStart, visualColumnEnd) ->
    line = editor.lineTextForBufferRow(range.start.row)
    tabLength = editor.getTabLength()
    visualColumn = 0
    found = 0
    for actualColumn in [0..line.length]
      if visualColumn == visualColumnStart
        range.start.column = actualColumn
        found = 1
      if visualColumn == visualColumnEnd
        range.end.column = actualColumn
        found = 2
        break
      if line[actualColumn] == '\t'
        visualColumn += tabLength - (visualColumn % tabLength)
      else
        visualColumn += 1
    switch found
      when 0
        # Start got clipped.
        return true
      when 1
        # End got clipped.
        range.end.column = line.length
    return false
