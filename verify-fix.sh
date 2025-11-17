#!/bin/bash
# Simple static verification that the fix is in place

echo "Verifying the bug fix in ido-numbered-mode.el..."
echo

# Check if the file has the fix (self-insert-command 1)
if grep -q "(self-insert-command 1)" ido-numbered-mode.el; then
    echo "✓ Fix is present: (self-insert-command 1) found"
    FIX_PRESENT=1
else
    echo "✗ Fix is NOT present: (self-insert-command 1) not found"
    FIX_PRESENT=0
fi

# Check if the buggy code is gone (self-insert-command num)
if grep -q "(self-insert-command num)" ido-numbered-mode.el; then
    echo "✗ Bug still present: (self-insert-command num) found"
    BUG_GONE=0
else
    echo "✓ Bug removed: (self-insert-command num) not found"
    BUG_GONE=1
fi

echo
echo "Context around the fix:"
echo "----------------------"
grep -n -A 2 -B 2 "self-insert-command" ido-numbered-mode.el

echo
if [ $FIX_PRESENT -eq 1 ] && [ $BUG_GONE -eq 1 ]; then
    echo "✓ Static verification PASSED"
    echo
    echo "To fully test this fix, you need to run the automated tests:"
    echo "  ./run-tests.sh  (requires Emacs)"
    echo "  or"
    echo "  ./test-with-docker.sh  (requires Docker)"
    exit 0
else
    echo "✗ Static verification FAILED"
    exit 1
fi
