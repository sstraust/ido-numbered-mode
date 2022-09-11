# Ido Numbered Mode
Add numbered selection to ido-mode.

`Buffer: {0 .emacs | 1 *Messages* | 2 *scratch* | 3 *shell*}`

If you press a number (like "1") it will go to that buffer (i.e. *Messages* in the example above).

0 does not go to the 0th buffer (just hit enter)

## Installation
In order to turn this on, you must use ido-mode, and turn on ido-mode first.

e.g. your .emacs should have

`
(require 'ido-mode)

(ido-mode 1)

(require 'ido-numbered-mode)

(ido-numbered-mode 1)
`

To get the code, copy it into your init directory, and add it to your load path e.g. in your .emacs, add 
`(add-to-list 'load-path "~/.emacs.d/downloadedCode")`

## Note

This caches ido-completions, so you could get wonky behavior if you turn it on and off frequently and have other packages that modify ido-completions (e.g. ido-vertical-mode)