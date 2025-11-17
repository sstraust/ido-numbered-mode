#!/bin/bash
# Run ERT tests for ido-numbered-mode

cd "$(dirname "$0")"

emacs -batch -l ert -l test-ido-numbered-mode.el -f ert-run-tests-batch-and-exit
