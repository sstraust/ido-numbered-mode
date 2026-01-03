(defun ido-numbered-select-number (num)
  "Select the nth match and go to it."
  (interactive)
  (if (> (length ido-text) 0)
      (self-insert-command 1)
    (when (> (length ido-matches) num)
      (dotimes (i num)
	(ido-next-match))
      (ido-complete))
    (ido-exit-minibuffer)))

(defun myido-completions (name)
  "Return the string that is displayed after the user's text.
Modified from `icomplete-completions'."
  (let* ((comps ido-matches)
	 (ind (and (consp (car comps)) (> (length (cdr (car comps))) 1)
		   ido-merged-indicator))
         (my/number 0)
	 first)

    (if (and ind ido-use-faces)
	(put-text-property 0 1 'face 'ido-indicator ind))

    (if (and ido-use-faces comps)
	(let* ((fn (ido-name (car comps)))
	       (ln (length fn)))
	  (setq first (copy-sequence fn))
	  (put-text-property 0 ln 'face
			     (if (= (length comps) 1)
                                 (if ido-incomplete-regexp
                                     'ido-incomplete-regexp
                                   'ido-only-match)
			       'ido-first-match)
			     first)
	  (if ind (setq first (concat first ind)))
	  (setq comps (cons first (cdr comps)))))

    (cond ((null comps)
	   (cond
	    (ido-show-confirm-message
	     (or (nth 10 ido-decorations) " [Confirm]"))
	    (ido-directory-nonreadable
	     (or (nth 8 ido-decorations) " [Not readable]"))
	    (ido-directory-too-big
	     (or (nth 9 ido-decorations) " [Too big]"))
	    (ido-report-no-match
	     (nth 6 ido-decorations))  ;; [No match]
	    (t "")))
	  (ido-incomplete-regexp
           (concat " " (car comps)))
	  ((null (cdr comps))		;one match
	   (concat (if (if (not ido-enable-regexp)
                           (= (length (ido-name (car comps))) (length name))
                         ;; We can't rely on the length of the input
                         ;; for regexps, so explicitly check for a
                         ;; complete match
                         (string-match name (ido-name (car comps)))
                         (string-equal (match-string 0 (ido-name (car comps)))
                                       (ido-name (car comps))))
                       ""
                     ;; When there is only one match, show the matching file
                     ;; name in full, wrapped in [ ... ].
                     (concat
                      (or (nth 11 ido-decorations) (nth 4 ido-decorations))
                      (ido-name (car comps))
                      (or (nth 12 ido-decorations) (nth 5 ido-decorations))))
		   (if (not ido-use-faces) (nth 7 ido-decorations))))  ;; [Matched]
	  (t				;multiple matches
	   (let* ((items (if (> ido-max-prospects 0) (1+ ido-max-prospects) 999))
		  (alternatives
		   (apply
		    #'concat
		    (cdr (apply
			  #'nconc
			  (mapcar
			   (lambda (com)
			     (setq com (concat (number-to-string my/number) " " (ido-name com)))
			     (setq items (1- items))
                             (setq my/number (1+ my/number))

			     (cond
			      ((< items 0) ())
			      ((= items 0) (list (nth 3 ido-decorations))) ; " | ..."
			      (t
			       (list (or ido-separator (nth 2 ido-decorations)) ; " | "
				     (let ((str (substring com 0)))
				       (if (and ido-use-faces
						(not (string= str first))
						(ido-final-slash str))
					   (put-text-property 0 (length str) 'face 'ido-subdir str))
				       str)))))
			   comps))))))

	     (concat
	      ;; put in common completion item -- what you get by pressing tab
	      (if (and (stringp ido-common-match-string)
		       (> (length ido-common-match-string) (length name)))
		  (concat (nth 4 ido-decorations)   ;; [ ... ]
			  (substring ido-common-match-string (length name))
			  (nth 5 ido-decorations)))
	      ;; list all alternatives
	      (nth 0 ido-decorations)  ;; { ... }
	      alternatives
	      (nth 1 ido-decorations)))))))

(defun ido-numbered-mode-turn-on ()
  (advice-add 'ido-completions :override #'myido-completions)
  (add-hook 'ido-setup-hook 'ido-numbered-define-keys))

(defun ido-numbered-mode-turn-off ()
  (advice-remove 'ido-completions #'myido-completions)
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
  "Adds numbers to ido mode. If you type a number n, it goes to the nth completion"
  :global t
  (if ido-numbered-mode
      (ido-numbered-mode-turn-on)
    (ido-numbered-mode-turn-off)))

(provide 'ido-numbered-mode)
