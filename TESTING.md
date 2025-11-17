# Testing ido-numbered-mode

## Automated Tests

This repository includes automated tests using Emacs ERT (Emacs Lisp Regression Testing).

### Running Tests Locally

#### Option 1: With Emacs installed

```bash
./run-tests.sh
```

#### Option 2: With Docker

```bash
chmod +x test-with-docker.sh
./test-with-docker.sh
```

### GitHub Actions

Tests automatically run on push and pull requests via GitHub Actions (see `.github/workflows/test.yml`).

## Manual Testing

To manually verify the number insertion bug fix:

### Before the fix

1. Enable ido-mode and ido-numbered-mode in Emacs
2. Try to open a file (C-x C-f)
3. Start typing a filename that contains a number, e.g., "file5.txt"
4. When you type "5", you would see "file55555.txt" (the digit repeated 5 times)
5. Similarly, typing "3" would insert "333", typing "7" would insert "7777777"

### After the fix

1. Enable ido-mode and ido-numbered-mode in Emacs
2. Try to open a file (C-x C-f)
3. Start typing a filename that contains a number, e.g., "file5.txt"
4. When you type "5", you should see "file5.txt" (the digit appears only once)
5. All digits 1-9 should insert exactly once when typing filenames

### Testing numbered selection still works

The fix should NOT break the numbered selection feature:

1. Enable ido-mode and ido-numbered-mode in Emacs
2. Try to open a file (C-x C-f) with multiple matches displayed
3. WITHOUT typing anything, press a number (e.g., "3")
4. It should select the 3rd match in the list
5. This should work for numbers 1-9

## Test Coverage

The automated tests cover:

1. **Single digit insertion**: When ido-text exists, typing any number 1-9 should insert that digit exactly once
2. **Multiple numbers**: All numbers 1-9 should behave consistently
3. **Match selection**: When ido-text is empty, numbers should select the corresponding match
4. **Helper functions**: Tests for the `split-once` utility function

## Understanding the Bug

The bug was in `ido-numbered-select-number` function at line 5:

**Before (buggy):**
```elisp
(self-insert-command num)
```

**After (fixed):**
```elisp
(self-insert-command 1)
```

The issue: `self-insert-command` interprets its argument as a repeat count. When `num=5` (because the user pressed "5"), it would insert the character 5 times instead of once.
