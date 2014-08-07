# column-select

Enhanced column selection for the [Atom](https://atom.io) editor.

![example](https://raw.githubusercontent.com/ehuss/atom-column-select/master/example.gif)

## Key Bindings

| Command | Mac | Windows | Linux |
| ------- | --- | ------- | ----- |
| Up | Ctrl-Shift-Up | Ctrl-Alt-Up | Alt-Shift-Up |
| Down | Ctrl-Shift-Down | Ctrl-Alt-Down | Alt-Shift-Down |
| PageUp | Ctrl-Shift-PageUp | Ctrl-Alt-PageUp | Alt-Shift-PageUp |
| PageDown | Ctrl-Shift-PageDown | Ctrl-Alt-PageDown | Alt-Shift-PageDown |
| Up to top of document. | Ctrl-Shift-Home | Ctrl-Alt-Home | Alt-Shift-Home |
| Down to bottom of document. | Ctrl-Shift-End | Ctrl-Alt-End | Alt-Shift-End |

## Differences
Compared to the normal column selection in Atom, this does the following:
* Allows reversing direction (go down a few lines, if you go one too many just go up one).
* Added Page and Document jumps.
* Skips rows that are too short.
* If you start at the end of a line, then it will stay at the end of each line.
* Handles tab characters.

[![Build Status](https://travis-ci.org/ehuss/atom-column-select.svg?branch=master)](https://travis-ci.org/ehuss/atom-column-select)
[![Build status](https://ci.appveyor.com/api/projects/status/0dh6hv85bx2jvmk2)](https://ci.appveyor.com/project/ehuss/atom-column-select)
