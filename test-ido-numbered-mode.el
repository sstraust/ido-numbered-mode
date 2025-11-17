;;; test-ido-numbered-mode.el --- Tests for ido-numbered-mode

;;; Commentary:
;; Tests for ido-numbered-mode functionality

;;; Code:

(require 'ert)
(require 'ido)
(load-file "ido-numbered-mode.el")

;; Mock variables for testing
(defvar test-inserted-text "")
(defvar test-insert-count 0)

;; Mock self-insert-command to capture what gets inserted
(defun mock-self-insert-command (n)
  "Mock version of self-insert-command that records insertions."
  (setq test-insert-count n)
  (dotimes (i n)
    (setq test-inserted-text (concat test-inserted-text (number-to-string last-command-event)))))

(ert-deftest test-self-insert-with-text ()
  "Test that typing a number when ido-text exists inserts it only once."
  (let ((ido-text "file")
        (ido-matches '())
        (test-inserted-text "")
        (test-insert-count 0)
        (last-command-event ?5))
    ;; Temporarily replace self-insert-command
    (cl-letf (((symbol-function 'self-insert-command) #'mock-self-insert-command)
              ((symbol-function 'ido-exit-minibuffer) #'ignore))
      (ido-numbered-select-number 5)
      ;; Should insert only once, not 5 times
      (should (= test-insert-count 1))
      (should (equal test-inserted-text "5")))))

(ert-deftest test-self-insert-different-numbers ()
  "Test that different numbers all insert only once when ido-text exists."
  (dolist (num '(1 2 3 4 5 6 7 8 9))
    (let ((ido-text "file")
          (ido-matches '())
          (test-inserted-text "")
          (test-insert-count 0)
          (last-command-event (+ ?0 num)))
      (cl-letf (((symbol-function 'self-insert-command) #'mock-self-insert-command)
                ((symbol-function 'ido-exit-minibuffer) #'ignore))
        (ido-numbered-select-number num)
        ;; Should always insert once, regardless of which number
        (should (= test-insert-count 1))
        (should (equal test-inserted-text (number-to-string num)))))))

(ert-deftest test-match-selection-when-no-text ()
  "Test that pressing a number with no ido-text selects that match."
  (let ((ido-text "")
        (ido-matches '("file1" "file2" "file3" "file4"))
        (next-match-calls 0))
    (cl-letf (((symbol-function 'ido-next-match)
               (lambda () (setq next-match-calls (1+ next-match-calls))))
              ((symbol-function 'ido-complete) #'ignore)
              ((symbol-function 'ido-exit-minibuffer) #'ignore))
      (ido-numbered-select-number 2)
      ;; Should call ido-next-match 2 times to get to the 2nd item
      (should (= next-match-calls 2)))))

(ert-deftest test-split-once-basic ()
  "Test the split-once helper function."
  (should (equal (split-once "hello world" " ")
                 '("hello" "world")))
  (should (equal (split-once "foo/bar/baz" "/")
                 '("foo" "bar/baz")))
  (should (equal (split-once "no-separator" "/")
                 nil)))

(provide 'test-ido-numbered-mode)
;;; test-ido-numbered-mode.el ends here
