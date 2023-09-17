(defun ido-numbered-select-number (num)
  (interactive)
  (if (> (length ido-text) 0)
      (self-insert-command num)
    (when (> (length ido-matches) num)
      (dotimes (i num)
	(ido-next-match))
      (ido-complete))
    (ido-exit-minibuffer)))

(defun split-once (initial-string separator)
  (let ((string-location (string-match (regexp-quote separator) initial-string)))
	(if (not string-location)
	    nil
	  (let ((string-end-location (+ string-location (length separator))))
	    (list (substring initial-string 0 string-location)
		  (substring initial-string string-end-location))))))


(defun ido-numbered-add-numbers-helper (remaining-string curr-matches num)
  (if (not (and (car curr-matches)
		(string-match (regexp-quote (car curr-matches)) remaining-string)
		(< num 10)))
      remaining-string
    (let ((split-once-result (split-once remaining-string (car curr-matches))))
      (concat (nth 0 split-once-result)
	      (number-to-string num)
	      " "
	      (car curr-matches)
	      (ido-numbered-add-numbers-helper (nth 1 split-once-result) (cdr curr-matches) (+ num 1))))))

	   

(defun ido-numbered-add-numbers-to-matches (input-str)
  (ido-numbered-add-numbers-helper input-str ido-matches 0))

(defvar ido-numbered-set-matches-set nil)

(defun ido-numbered-mode-turn-on ()
  (if (not ido-numbered-set-matches-set)
      (progn (setq ido-numbered-ido-set-matches-copy (symbol-function 'ido-completions))
	     (setq ido-numbered-set-matches-set t)))
  (fset 'ido-completions (lambda (name)
			 (ido-numbered-add-numbers-to-matches (funcall ido-numbered-ido-set-matches-copy name))))
  (add-hook 'ido-setup-hook 'ido-numbered-define-keys))

(defun ido-numbered-mode-turn-off ()
  (fset 'ido-completions ido-numbered-ido-set-matches-copy)
  (setq ido-numbered-set-matches-set nil)
  (remove-hook 'ido-setup-hook 'ido-numbered-define-keys))

(defun ido-numbered-define-keys ()
    (define-key ido-completion-map (kbd "1") (lambda () (interactive) (ido-numbered-select-number 1)))
  (define-key ido-completion-map (kbd "2") (lambda () (interactive) (ido-numbered-select-number 2)))
  (define-key ido-completion-map (kbd "3") (lambda () (interactive) (ido-numbered-select-number 3)))
  (define-key ido-completion-map (kbd "4") (lambda () (interactive) (ido-numbered-select-number 4)))
  (define-key ido-completion-map (kbd "5") (lambda () (interactive) (ido-numbered-select-number 5)))
  (define-key ido-completion-map (kbd "6") (lambda () (interactive) (ido-numbered-select-number 6)))
  (define-key ido-completion-map (kbd "7") (lambda () (interactive) (ido-numbered-select-number 7)))
  (define-key ido-completion-map (kbd "8") (lambda () (interactive) (ido-numbered-select-number 8)))
  (define-key ido-completion-map (kbd "9") (lambda () (interactive) (ido-numbered-select-number 9))))

;;;###autoload
(define-minor-mode ido-numbered-mode
  "I don't write docs lol"
  :global t
  (if ido-numbered-mode
      (ido-numbered-mode-turn-on)
    (ido-numbered-mode-turn-off)))


(provide 'ido-numbered-mode)
(require 'ido-numbered-mode)

;; ;; (ido-numbered-mode-turn-on)
;; (ido-numbered-mode-turn-off)
