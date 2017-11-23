# column-select

Enhanced column selection for the [Atom](https://atom.io) editor.

![example](https://raw.githubusercontent.com/ehuss/atom-column-select/master/example.gif)

## Key Bindings

| Command | Mac | Windows | Linux |
| ------- | --- | ------- | ----- |
| Up | Ctrl-Shift-Up | Alt-Shift-Up | Alt-Shift-Up |
| Down | Ctrl-Shift-Down | Alt-Shift-Down | Alt-Shift-Down |
| PageUp | Ctrl-Shift-PageUp | Alt-Shift-PageUp | Alt-Shift-PageUp |
| PageDown | Ctrl-Shift-PageDown | Alt-Shift-PageDown | Alt-Shift-PageDown |
| Up to top of document. | Ctrl-Shift-Home | Alt-Shift-Home | Alt-Shift-Home |
| Down to bottom of document. | Ctrl-Shift-End | Alt-Shift-End | Alt-Shift-End |

## Differences
Compared to the normal column selection in Atom, this does the following:
* Allows reversing direction (go down a few lines, if you go one too many just go up one).
* Added Page and Document jumps.
* Skips rows that are too short.
* If you start at the end of a line, then it will stay at the end of each line.
* Handles tab characters.

[![Build Status](https://travis-ci.org/ehuss/atom-column-select.svg?branch=master)](https://travis-ci.org/ehuss/atom-column-select)
[![Build status](https://ci.appveyor.com/api/projects/status/0dh6hv85bx2jvmk2)](https://ci.appveyor.com/project/ehuss/atom-column-select)
