ColumnSelect = require '../lib/column-select'

PAGE_SIZE = 50

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "ColumnSelect", ->
  activationPromise = null
  editor = null
  editorView = null

  checkRange = (range, expectedRange) ->
    expect(range.start.row).toBe(expectedRange[0][0])
    expect(range.start.column).toBe(expectedRange[0][1])
    expect(range.end.row).toBe(expectedRange[1][0])
    expect(range.end.column).toBe(expectedRange[1][1])

  checkSelections = (expectedRanges) ->
    # Create a map for fast checks.
    selMap = {}
    for selection in editor.getSelections()
      range = selection.getBufferRange()
      key = [range.start.row,range.start.column,range.end.row,range.end.column]
      selMap[key] = true
    count = 0
    for {colStart, colEnd, rowStart, rowEnd} in expectedRanges
      for rowIndex in [rowStart..rowEnd]
        key = [rowIndex, colStart, rowIndex, colEnd]
        expect(selMap[key]).toBeTruthy()
        count += 1
    expect(editor.getSelections().length).toBe(count)

  loadBefore = (filename) ->
    beforeEach ->
      waitsForPromise ->
        atom.workspace.open(filename)
      waitsForPromise ->
        atom.packages.activatePackage('column-select')
      runs ->
        editor = atom.workspace.getActiveTextEditor()
        editorView = atom.views.getView(editor)
        expect(editorView).not.toBeUndefined()
        editor.setLineHeightInPixels(10)
        editor.setHeight(PAGE_SIZE*10)
        expect(editor.getRowsPerPage()).toBe(PAGE_SIZE)

  describe "basic tests", ->

    loadBefore('test-basic.txt')

    describe "initial state", ->
      it "should be sane", ->
        checkSelections([
          {colStart:0, colEnd:0, rowStart:0, rowEnd:0}])

    describe "up", ->
      it "should not do anything on first line", ->
        atom.commands.dispatch(editorView, 'column-select:up')
        checkSelections([{colStart:0, colEnd:0, rowStart:0, rowEnd:0}])

      it "should move up in column 0", ->
        editor.setCursorBufferPosition([3, 0])
        checkSelections([
          {colStart:0, colEnd:0, rowStart:3, rowEnd:3}])
        atom.commands.dispatch(editorView, "column-select:up")
        checkSelections([
          {colStart:0, colEnd:0, rowStart:2, rowEnd:3}])
        atom.commands.dispatch(editorView, "column-select:up")
        checkSelections([
          {colStart:0, colEnd:0, rowStart:1, rowEnd:3}])
        atom.commands.dispatch(editorView, "column-select:up")
        checkSelections([
          {colStart:0, colEnd:0, rowStart:0, rowEnd:3}])
        atom.commands.dispatch(editorView, "column-select:up")
        checkSelections([
          {colStart:0, colEnd:0, rowStart:0, rowEnd:3}])

    describe "down", ->
      it "should not do anything on last line", ->
        atom.commands.dispatch(editorView, "core:move-to-bottom")
        lines = editor.getLineCount()
        checkSelections([
          {colStart:0, colEnd:0, rowStart:lines-1, rowEnd:lines-1}])
        atom.commands.dispatch(editorView, "column-select:down")
        checkSelections([
          {colStart:0, colEnd:0, rowStart:lines-1, rowEnd:lines-1}])

      it "should move down in column 0", ->
        atom.commands.dispatch(editorView, "column-select:down")
        checkSelections([{colStart:0, colEnd:0, rowStart:0, rowEnd:1}])
        atom.commands.dispatch(editorView, "column-select:down")
        checkSelections([{colStart:0, colEnd:0, rowStart:0, rowEnd:2}])

    describe "pagedown", ->
      it "should move pages at a time", ->
        atom.commands.dispatch(editorView, "column-select:pagedown")
        checkSelections([
          {colStart:0, colEnd:0, rowStart:0, rowEnd:PAGE_SIZE}])
        atom.commands.dispatch(editorView, "column-select:pagedown")
        checkSelections([
          {colStart:0, colEnd:0, rowStart:0, rowEnd:2*PAGE_SIZE}])
        atom.commands.dispatch(editorView, "column-select:pagedown")
        checkSelections([
          {colStart:0, colEnd:0, rowStart:0, rowEnd:3*PAGE_SIZE}])

    describe "pageup", ->
      it "should move pages at a time", ->
        atom.commands.dispatch(editorView, "core:move-to-bottom")
        lines = editor.getLineCount()
        atom.commands.dispatch(editorView, "column-select:pageup")
        checkSelections([
          {colStart:0, colEnd:0, rowStart:lines-PAGE_SIZE-1, rowEnd:lines-1}])
        atom.commands.dispatch(editorView, "column-select:pageup")
        checkSelections([
          {colStart:0, colEnd:0, rowStart:lines-2*PAGE_SIZE-1, rowEnd:lines-1}])
        atom.commands.dispatch(editorView, "column-select:pageup")
        checkSelections([
          {colStart:0, colEnd:0, rowStart:lines-3*PAGE_SIZE-1, rowEnd:lines-1}])

    describe "top", ->
      it "should move to the top", ->
        atom.commands.dispatch(editorView, "core:move-to-bottom")
        lines = editor.getLineCount()
        atom.commands.dispatch(editorView, "column-select:top")
        checkSelections([
          {colStart:0, colEnd:0, rowStart:0, rowEnd:lines-1}])

    describe "bottom", ->
      it "should move to the bottom", ->
        lines = editor.getLineCount()
        atom.commands.dispatch(editorView, "column-select:bottom")
        checkSelections([
          {colStart:0, colEnd:0, rowStart:0, rowEnd:lines-1}])

    describe "undo", ->
      it "should undo down/up", ->
        atom.commands.dispatch(editorView, "column-select:down")
        atom.commands.dispatch(editorView, "column-select:up")
        checkSelections([
          {colStart:0, colEnd:0, rowStart:0, rowEnd:0}])
        atom.commands.dispatch(editorView, "column-select:down")
        atom.commands.dispatch(editorView, "column-select:down")
        atom.commands.dispatch(editorView, "column-select:up")
        checkSelections([
          {colStart:0, colEnd:0, rowStart:0, rowEnd:1}])

      it "should undo large jumps", ->
        lines = editor.getLineCount()
        atom.commands.dispatch(editorView, "column-select:down")
        atom.commands.dispatch(editorView, "column-select:down")
        atom.commands.dispatch(editorView, "column-select:down")
        atom.commands.dispatch(editorView, "column-select:top")
        checkSelections([
          {colStart:0, colEnd:0, rowStart:0, rowEnd:0}])
        atom.commands.dispatch(editorView, "column-select:bottom")
        atom.commands.dispatch(editorView, "column-select:pageup")
        checkSelections([
          {colStart:0, colEnd:0, rowStart:0, rowEnd:lines-PAGE_SIZE-1}])
        atom.commands.dispatch(editorView, "column-select:top")
        checkSelections([
          {colStart:0, colEnd:0, rowStart:0, rowEnd:0}])

      it "should reverse directions", ->
        editor.setCursorBufferPosition([2*PAGE_SIZE, 0])
        atom.commands.dispatch(editorView, "column-select:down")
        atom.commands.dispatch(editorView, "column-select:down")
        atom.commands.dispatch(editorView, "column-select:down")
        atom.commands.dispatch(editorView, "column-select:top")
        atom.commands.dispatch(editorView, "column-select:up")
        checkSelections([
          {colStart:0, colEnd:0, rowStart:2*PAGE_SIZE-1, rowEnd:2*PAGE_SIZE}])

  ###########################################################################

  describe "end tests", ->

    loadBefore('test-end.txt')

    it "should stick to the end per line", ->
      editor.moveToEndOfLine()
      atom.commands.dispatch(editorView, "column-select:down")
      checkSelections([
        {colStart:3, colEnd:3, rowStart:0, rowEnd:0},
        {colStart:4, colEnd:4, rowStart:1, rowEnd:1}])
      atom.commands.dispatch(editorView, "column-select:down")
      checkSelections([
        {colStart:3, colEnd:3, rowStart:0, rowEnd:0},
        {colStart:4, colEnd:4, rowStart:1, rowEnd:1},
        {colStart:5, colEnd:5, rowStart:2, rowEnd:2}])
      atom.commands.dispatch(editorView, "column-select:down")
      atom.commands.dispatch(editorView, "column-select:down")
      atom.commands.dispatch(editorView, "column-select:down")
      atom.commands.dispatch(editorView, "column-select:down")
      atom.commands.dispatch(editorView, "column-select:down")
      atom.commands.dispatch(editorView, "column-select:down")
      checkSelections([
        {colStart:3, colEnd:3, rowStart:0, rowEnd:0},
        {colStart:4, colEnd:4, rowStart:1, rowEnd:1},
        {colStart:5, colEnd:5, rowStart:2, rowEnd:2},
        {colStart:10, colEnd:10, rowStart:3, rowEnd:3},
        {colStart:0, colEnd:0, rowStart:4, rowEnd:4},
        {colStart:3, colEnd:3, rowStart:5, rowEnd:5},
        {colStart:4, colEnd:4, rowStart:6, rowEnd:6},
        {colStart:0, colEnd:0, rowStart:7, rowEnd:7}])

    it "should not be confused by empty lines", ->
      editor.setCursorBufferPosition([4, 0])
      atom.commands.dispatch(editorView, "column-select:up")
      atom.commands.dispatch(editorView, "column-select:up")
      checkSelections([
        {colStart:0, colEnd:0, rowStart:2, rowEnd:4}])

  ###########################################################################

  describe "short lines", ->

    loadBefore('test-skip-short-lines.txt')

    it "should skip short lines", ->
      editor.setCursorBufferPosition([0, 6])
      atom.commands.dispatch(editorView, "column-select:down")
      checkSelections([
        {colStart:6, colEnd:6, rowStart:0, rowEnd:0},
        {colStart:6, colEnd:6, rowStart:2, rowEnd:2}])
      atom.commands.dispatch(editorView, "column-select:down")
      checkSelections([
        {colStart:6, colEnd:6, rowStart:0, rowEnd:0},
        {colStart:6, colEnd:6, rowStart:2, rowEnd:2},
        {colStart:6, colEnd:6, rowStart:4, rowEnd:4}])
      atom.commands.dispatch(editorView, "column-select:down")
      checkSelections([
        {colStart:6, colEnd:6, rowStart:0, rowEnd:0},
        {colStart:6, colEnd:6, rowStart:2, rowEnd:2},
        {colStart:6, colEnd:6, rowStart:4, rowEnd:4},
        {colStart:6, colEnd:6, rowStart:87, rowEnd:87}])
      atom.commands.dispatch(editorView, "column-select:down")
      checkSelections([
        {colStart:6, colEnd:6, rowStart:0, rowEnd:0},
        {colStart:6, colEnd:6, rowStart:2, rowEnd:2},
        {colStart:6, colEnd:6, rowStart:4, rowEnd:4},
        {colStart:6, colEnd:6, rowStart:87, rowEnd:87},
        {colStart:6, colEnd:6, rowStart:164, rowEnd:164}])
      atom.commands.dispatch(editorView, "column-select:down")
      checkSelections([
        {colStart:6, colEnd:6, rowStart:0, rowEnd:0},
        {colStart:6, colEnd:6, rowStart:2, rowEnd:2},
        {colStart:6, colEnd:6, rowStart:4, rowEnd:4},
        {colStart:6, colEnd:6, rowStart:87, rowEnd:87},
        {colStart:6, colEnd:6, rowStart:164, rowEnd:164}])

    it "should skip short lines (bottom)", ->
      editor.setCursorBufferPosition([0, 6])
      atom.commands.dispatch(editorView, "column-select:bottom")
      checkSelections([
        {colStart:6, colEnd:6, rowStart:0, rowEnd:0},
        {colStart:6, colEnd:6, rowStart:2, rowEnd:2},
        {colStart:6, colEnd:6, rowStart:4, rowEnd:4},
        {colStart:6, colEnd:6, rowStart:87, rowEnd:87},
        {colStart:6, colEnd:6, rowStart:164, rowEnd:164}])

    it "should skip short lines (pagedown)", ->
      editor.setCursorBufferPosition([0, 6])
      atom.commands.dispatch(editorView, "column-select:pagedown")
      checkSelections([
        {colStart:6, colEnd:6, rowStart:0, rowEnd:0},
        {colStart:6, colEnd:6, rowStart:2, rowEnd:2},
        {colStart:6, colEnd:6, rowStart:4, rowEnd:4},
        {colStart:6, colEnd:6, rowStart:87, rowEnd:87}])
      atom.commands.dispatch(editorView, "column-select:pagedown")
      checkSelections([
        {colStart:6, colEnd:6, rowStart:0, rowEnd:0},
        {colStart:6, colEnd:6, rowStart:2, rowEnd:2},
        {colStart:6, colEnd:6, rowStart:4, rowEnd:4},
        {colStart:6, colEnd:6, rowStart:87, rowEnd:87},
        {colStart:6, colEnd:6, rowStart:164, rowEnd:164}])
      atom.commands.dispatch(editorView, "column-select:pagedown")
      checkSelections([
        {colStart:6, colEnd:6, rowStart:0, rowEnd:0},
        {colStart:6, colEnd:6, rowStart:2, rowEnd:2},
        {colStart:6, colEnd:6, rowStart:4, rowEnd:4},
        {colStart:6, colEnd:6, rowStart:87, rowEnd:87},
        {colStart:6, colEnd:6, rowStart:164, rowEnd:164}])

  ###########################################################################

  describe "wide columns", ->

    loadBefore('test-wide.txt')

    it "support multiple wide columns (with tabs)", ->
      editor.setTabLength(8)
      editor.setSelectedBufferRanges([
          [[0, 0], [0, 2]],
          [[0, 3], [0, 7]],
          [[0, 8], [0,13]],
          [[0,14], [0,15]],
          [[0,16], [0,16]]
        ])
      sel1 = [
        {colStart:0, colEnd:2, rowStart:0, rowEnd:0},

        {colStart:3, colEnd:7, rowStart:0, rowEnd:0},

        {colStart:8, colEnd:13, rowStart:0, rowEnd:0},

        {colStart:14, colEnd:15, rowStart:0, rowEnd:0},

        {colStart:16, colEnd:16, rowStart:0, rowEnd:0},
      ]
      checkSelections(sel1)
      atom.commands.dispatch(editorView, "column-select:down")
      sel2 = [
        {colStart:0, colEnd:2, rowStart:0, rowEnd:1},

        {colStart:3, colEnd:7, rowStart:0, rowEnd:0},
        {colStart:4, colEnd:8, rowStart:1, rowEnd:1},

        {colStart:8, colEnd:13, rowStart:0, rowEnd:0},
        {colStart:9, colEnd:14, rowStart:1, rowEnd:1},

        {colStart:14, colEnd:15, rowStart:0, rowEnd:0},
        {colStart:15, colEnd:16, rowStart:1, rowEnd:1},

        {colStart:16, colEnd:16, rowStart:0, rowEnd:0},
        {colStart:17, colEnd:17, rowStart:1, rowEnd:1}
      ]
      checkSelections(sel2)

      atom.commands.dispatch(editorView, "column-select:down")
      sel3 = [
        {colStart:0, colEnd:2, rowStart:0, rowEnd:2},

        {colStart:3, colEnd:7, rowStart:0, rowEnd:0},
        {colStart:4, colEnd:8, rowStart:1, rowEnd:1},
        {colStart:5, colEnd:9, rowStart:2, rowEnd:2},

        {colStart:8, colEnd:13, rowStart:0, rowEnd:0},
        {colStart:9, colEnd:14, rowStart:1, rowEnd:1},
        {colStart:11, colEnd:16, rowStart:3, rowEnd:3},

        {colStart:14, colEnd:15, rowStart:0, rowEnd:0},
        {colStart:15, colEnd:16, rowStart:1, rowEnd:1},
        {colStart:17, colEnd:18, rowStart:3, rowEnd:3},

        {colStart:16, colEnd:16, rowStart:0, rowEnd:0},
        {colStart:17, colEnd:17, rowStart:1, rowEnd:1},
        {colStart:19, colEnd:19, rowStart:3, rowEnd:3}
      ]
      checkSelections(sel3)

      atom.commands.dispatch(editorView, "column-select:down")
      sel4 = [
        {colStart:0,  colEnd:2,  rowStart:0, rowEnd:3},

        {colStart:3,  colEnd:7,  rowStart:0, rowEnd:0},
        {colStart:4,  colEnd:8,  rowStart:1, rowEnd:1},
        {colStart:5,  colEnd:9,  rowStart:2, rowEnd:2},
        {colStart:6,  colEnd:10, rowStart:3, rowEnd:3},

        {colStart:8,  colEnd:13, rowStart:0, rowEnd:0},
        {colStart:9,  colEnd:14, rowStart:1, rowEnd:1},
        {colStart:11, colEnd:16, rowStart:3, rowEnd:3},
        {colStart:16, colEnd:21, rowStart:4, rowEnd:4},

        {colStart:14, colEnd:15, rowStart:0, rowEnd:0},
        {colStart:15, colEnd:16, rowStart:1, rowEnd:1},
        {colStart:17, colEnd:18, rowStart:3, rowEnd:3},
        {colStart:24, colEnd:25, rowStart:4, rowEnd:4},

        {colStart:16, colEnd:16, rowStart:0, rowEnd:0},
        {colStart:17, colEnd:17, rowStart:1, rowEnd:1},
        {colStart:19, colEnd:19, rowStart:3, rowEnd:3},
        {colStart:32, colEnd:32, rowStart:4, rowEnd:4}
      ]
      checkSelections(sel4)

      atom.commands.dispatch(editorView, "column-select:up")
      checkSelections(sel3)
      atom.commands.dispatch(editorView, "column-select:up")
      checkSelections(sel2)
      atom.commands.dispatch(editorView, "column-select:up")
      checkSelections(sel1)
