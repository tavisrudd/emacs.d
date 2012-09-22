(require 'comint)
(require 'dss-paths)
(eval-when-compile (require 'cl))

(setq-default abbrev-mode t)
(setq save-abbrevs t)
(setq abbrev-file-name (concat dss-ephemeral-dir "abbrev_defs"))
(if (file-exists-p abbrev-file-name)
    (read-abbrev-file abbrev-file-name t))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ido
(require 'ido)
(ido-mode t) ; use 'buffer rather than t to use only buffer switching
(ido-everywhere t)
(setq ido-enable-flex-matching t)
(setq ido-auto-merge-work-directories-length -1)

;; from http://emacs-fu.blogspot.com/2009_02_01_archive.html
(setq
  ido-ignore-buffers  '("\\` "  "^\*Back" ".*Completions\*" "^\*Ido" "^\*trace"
                        "^\*compilation" "^\*GTAGS" "^session\.*")
  ;ido-work-directory-list '("~/" "~/Desktop" "~/Documents" "~src")
  ido-case-fold  t
  ido-enable-last-directory-history t ; remember last used dirs
  ido-max-work-file-list      50   ; remember many
  ido-use-filename-at-point nil
  ido-use-url-at-point nil
  ;ido-max-prospects 8              ; don't spam my minibuffer
  ;ido-confirm-unique-completion t ; wait for RET, even with unique completion
  ido-save-directory-list-file (concat dss-ephemeral-dir "ido.last"))

(defvar dss-minibuffer-truncate-lines t)
(defun dss/minibuffer-setup-hook ()
  ;; in the future I'll change this so it looks to see if
  ;; linum-mode is active in any of this frame's windows. if the mini
  ;; buffer lines are not truncated, and linum-mode is active the line
  ;; numbers interactive the margin flicker annoyingly.
  ;; http://stackoverflow.com/questions/1775898/emacs-disable-line-truncation-in-minibuffer-only

  (when dss-minibuffer-truncate-lines
    (setq truncate-lines t)))

(add-hook 'minibuffer-setup-hook 'dss/minibuffer-setup-hook)

(defun dss/ido-find-file-at-point ()
  (interactive)
  (let ((ido-use-filename-at-point t)
        (ido-use-url-at-point t))
     (call-interactively 'ido-find-file)))

;;; http://stackoverflow.com/questions/905338/can-i-use-ido-completing-read-instead-of-completing-read-everywhere
(defvar ido-enable-replace-completing-read t
  "If t, use ido-completing-read instead of completing-read if possible.

Set it to nil using let in around-advice for functions where the
original completing-read is required.  For example, if a function
foo absolutely must use the original completing-read, define some
advice like this:

\(defadvice foo (around original-completing-read-only activate)
  (let (ido-enable-replace-completing-read) ad-do-it))")

;; Replace completing-read wherever possible, unless directed otherwise
(defadvice completing-read
  (around use-ido-when-possible activate)
  (if (or (not ido-enable-replace-completing-read) ; Manual override disable ido
          (boundp 'ido-cur-list)) ; Avoid infinite loop from ido calling this
      ad-do-it
    (let ((allcomp (all-completions "" collection predicate)))
      (if allcomp
          (setq ad-return-value
                (ido-completing-read prompt
                               allcomp
                               nil require-match initial-input hist def))
        ad-do-it))) " ")

;; (setq ido-enable-replace-completing-read t)
;; (defadvice where-is
;;   (around where-is-completing-read-only activate)
;;   (let (ido-enable-replace-completing-read) ad-do-it))

(defun dss/where-is ()
  "wrapper around where-is that doesn't use ido for completion"
  (interactive)
  (let (ido-enable-replace-completing-read)
     (call-interactively 'where-is)))

(defun dss/execute-extended-command ()
  "wrapper around execute-extended-command that doesn't use ido for completion"
  (interactive)
  (let (ido-enable-replace-completing-read)
    (call-interactively 'execute-extended-command)))

(defun dss/load-library ()
  "wrapper around load-library that doesn't use ido for completion"
  (interactive)
  (let (ido-enable-replace-completing-read)
    (call-interactively 'load-library)))

(defun dss/ido-search-file (dir pattern ex-pattern)
  (let* ((file-list
          (split-string
           (shell-command-to-string
            (concat
             "DIR=" dir ";"
             "find $DIR -type f -regex '" pattern "'"
             " -not -regex '" ex-pattern "' "
             "| sed -e's#'$DIR'##'"))))
         (choice (ido-completing-read "Which file: " file-list)))
    (find-file (concat dir choice))))

;http://www.rlazo.org/blog/entry/2008/sep/13/insert-a-path-into-the-current-buffer/
(defun dss/insert-path (file)
  "insert file"
  (interactive "FPath: ")
  (insert (replace-regexp-in-string (getenv "HOME") "~" (expand-file-name file))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; dabbrev and hippie-expand

(setq-default dabbrev-case-replace nil)
(setq-default hippie-expand-try-functions-list '(try-expand-abbrev try-expand-dabbrev-visible try-expand-dabbrev))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; auto-complete mode

(require 'auto-complete-config)
(add-to-list 'ac-dictionary-directories (concat dss-dotfiles-dir "ac-dict"))
(ac-config-default)
(setq ac-delay 0.2)
(setq ac-auto-show-menu 0.3)
(setq ac-menu-height 20)
(setq ac-use-comphist nil)
(setq ac-candidate-limit 25)
(setq ac-use-quick-help nil)

(defun dss/ac-hide-help ()
  (interactive)
  (setq ac-use-quick-help nil))

(defun dss/ac-show-help ()
  (interactive)
  (setq ac-use-quick-help t))

(require 'dss-codenav-helpers)

(defun ac-complete-no-fallback ()
  "a hacked version of ac-complete with fallback disabled.
  For some reason this is very sensitive to the function name
  prefix 'ac-'."
  (interactive)
  (let* ((candidate (ac-selected-candidate))
         (action (popup-item-property candidate 'action))
         (fallback nil))
    (when candidate
      (unless (ac-expand-string candidate)
        (setq fallback nil)) ;
      ;; Remember to show help later
      (when (and ac-point candidate)
        (unless ac-last-completion
          (setq ac-last-completion (cons (make-marker) nil)))
        (set-marker (car ac-last-completion) ac-point ac-buffer)
        (setcdr ac-last-completion candidate)))
    (ac-abort)
    (cond
     (action
      (funcall action))
     (fallback
      (ac-fallback-command)))
    candidate))

(defun dss/ac-electric-pair ()
  (interactive)
  (ac-complete-no-fallback)
  (dss/electric-pair))

(defun dss/ac-electric-char ()
  (interactive)
  (ac-complete-no-fallback)
  (call-interactively 'self-insert-command))

(define-key ac-completing-map "(" 'dss/ac-electric-pair)
(define-key ac-completing-map "[" 'dss/ac-electric-pair)
(define-key ac-completing-map "," 'dss/ac-electric-char)
;; (define-key ac-completing-map " " 'dss/ac-electric-char)
(define-key ac-completing-map "\r" 'ac-complete-no-fallback)
;; (define-key ac-completing-map (kbd "M-/") 'dabbrev-completion)
;; (define-key ac-completing-map (kbd "M-/") 'dss/hippie-expand)
(define-key ac-completing-map (kbd "M-/") 'ac-expand)

;;; <up/down> in terminal
(define-key ac-completing-map "\e[A" 'ac-previous)
(define-key ac-completing-map "\e[B" 'ac-next)

;;; C-<up/down> in terminal
(define-key ac-completing-map "\eOa" 'ac-quick-help-scroll-up)
(define-key ac-completing-map "\eOb" 'ac-quick-help-scroll-down)


;;; this seems to be little bit buggy with the most recent version of auto-complete.el ...


;;;
(defvar dss-ropemacs-completions-cache nil)
(defun dss/rope-candidates (prefix)
  (with-no-warnings
    (setq dss-ropemacs-completions-cache
          (delete ""
            (mapcar
                (lambda (completion)
                  (concat ac-prefix completion))
                (ignore-errors
                  (rope-completions))))))
  dss-ropemacs-completions-cache)

(ac-define-source dss-rope
  '((candidates . (dss/rope-candidates ac-prefix))
    (requires . 0)
    (cache . t)
    (symbol . "f")))

(ac-define-source dss-rope-dot
  '((candidates . (dss/rope-candidates ac-prefix))
    (prefix . c-dot)
    (requires . 0)
    (symbol . "f")))

(defvar ac-source-dss-filename '((init setq ac-filename-cache nil)
 (candidates . ac-filename-candidate)
 (requires . 0)
 (action . ac-start)
 (prefix . file)
 (limit)))

;; also see dss/ropemacs-init in dss-python.el
(defun dss/load-rope-completion()
  (interactive)
  (setq ac-sources (list
                    ac-source-dss-rope-dot
                    ac-source-yasnippet
                    ac-source-dss-rope
                    ac-source-words-in-buffer
                    ;;ac-source-filename
                    ac-source-dss-filename
                    ;;ac-source-words-in-same-mode-buffers
                    ;;ac-source-dictionary
                    )))

(defun dss/unload-rope-completion()
  (interactive)
  (setq ac-sources (list
                    ac-source-yasnippet
                    ac-source-words-in-buffer
                    ac-source-dss-filename
                    ;ac-source-words-in-same-mode-buffers
                    ac-source-dictionary
                    )))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; partially working support for using auto complete in ipython buffers
(require 'ipython)
(defun dss-ipython-completion-candidate (&optional use-ido)
  "This is a hacked version of ipython-complete from ipython.el,
    which can be used with either autocomplete-mode or ido.

    It mostly works but there are a few bugs that need resolving...

(defun dss/start-ipy-complete ()
  (interactive)
  (setq ac-sources '(ac-source-dss-ipy-dot
                     ac-source-dss-ipy
                     ac-source-filename)))
(add-hook 'ipython-shell-hook 'dss/start-ipy-complete)
(add-hook 'py-shell-hook 'dss/start-ipy-complete)

"
  (let* ((ugly-return nil)
         (sep ";")
         (python-process (or (get-buffer-process (current-buffer))
                                        ;XXX hack for .py buffers
                             (get-process py-which-bufname)))
         (beg (save-excursion (skip-chars-backward "a-z0-9A-Z_." (point-at-bol))
                               (point)))
         (end (point))
         (pattern (buffer-substring-no-properties beg end))

         (completions nil)
         (completion nil)
         (comint-preoutput-filter-functions
          (append comint-preoutput-filter-functions
                  '(ansi-color-filter-apply
                    (lambda (string)
                      (setq ugly-return (concat ugly-return string))
                      "")))))

    (message pattern)
    (process-send-string python-process
                         (format ipython-completion-command-string pattern))
    (accept-process-output python-process)
    (setq completions
          (split-string (substring ugly-return 0 (position ?\n ugly-return)) sep))

    (setq completions (if (string-match "\\." pattern)
                          (mapcar
                             (lambda (completion)
                               (car (last (cdr (split-string completion "\\.")))))
                             completions)
                        completions))
    (if use-ido
        (let* ((prefix-beg (if (string-match "\\." pattern)
                               (save-excursion (skip-chars-backward "a-z0-9A-Z_" (point-at-bol))
                                               (point))
                             beg))
               (prefix (buffer-substring-no-properties prefix-beg end))
               (choice (if (<= (length completions) 1)
                           (car completions)
                         (ido-completing-read "Choice:" completions nil nil prefix nil prefix)))
               )
          (if (and choice (not (string= pattern choice)))
              (progn
                (message "%s %s %s %s" prefix prefix-beg beg (point-at-bol))
                (delete-region prefix-beg end)
                (insert choice))))
      (progn
        ;(message "not using ido")
        completions))))


(defun dss/ido-ipython-complete ()
  (interactive)
  (dss-ipython-completion-candidate t))

(ac-define-source dss-ipy
  '((candidates . dss-ipython-completion-candidate)
    (requires . 0)
    (symbol . "f")))

(ac-define-source dss-ipy-dot
  '((candidates . dss-ipython-completion-candidate)
    (prefix . c-dot)
    (requires . 0)
    (symbol . "f")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; http://www.emacswiki.org/emacs/AutoCompleteSources#toc2

(defvar ac-org-candidates nil)
(defvar ac-org-pattern nil)
(defun ac-org-construct-candidates ()
  "Pabbrev source for org."
  (let* ((end (point))
         (beg1 (save-excursion
                (skip-chars-backward (org-re "[:alnum:]_@"))
                (point)))
         (beg (save-excursion
               (skip-chars-backward "a-zA-Z0-9_:$")
               (point)))
         (confirm (lambda (x) (stringp (car x))))
         (searchhead (equal (char-before beg) ?*))
         (struct
          (when (and (member (char-before beg1) '(?. ?<))
                     (setq a (assoc (buffer-substring beg1 (point))
                                    org-structure-template-alist)))
                (org-complete-expand-structure-template (1- beg1) a)
                (throw 'exit t)))
         (tag (and (equal (char-before beg1) ?:)
                   (equal (char-after (point-at-bol)) ?*)))
         (prop (and (equal (char-before beg1) ?:)
                    (not (equal (char-after (point-at-bol)) ?*))))
         (texp (equal (char-before beg) ?\\))
         (link (equal (char-before beg) ?\[))
         (opt (equal (buffer-substring (max (point-at-bol) (- beg 2))
                                       beg)
                     "#+"))
         (startup (string-match "^#\\+STARTUP:.*"
                                (buffer-substring (point-at-bol) (point))))
         (completion-ignore-case opt)
         (type nil)
         (tbl nil)
         (table (cond
                 (opt
                  (setq type :opt)
                  (require 'org-exp)
                  (append
                   (mapcar
                    (lambda (x)
                      (string-match "^#\\+\\(\\([A-Z_]+:?\\).*\\)" x)
                      (cons (match-string 2 x) (match-string 1 x)))
                    (org-split-string (org-get-current-options) "\n"))
                   (mapcar 'list org-additional-option-like-keywords)))
                 (startup
                  (setq type :startup)
                  org-startup-options)
                 (link (append org-link-abbrev-alist-local
                               org-link-abbrev-alist))
                 (texp
                  (setq type :tex)
                  org-html-entities)
                 ((string-match "\\`\\*+[ \t]+\\'"
                                (buffer-substring (point-at-bol) beg))
                  (setq type :todo)
                  (mapcar 'list org-todo-keywords-1))
                 (searchhead
                  (setq type :searchhead)
                  (save-excursion
                   (goto-char (point-min))
                   (while (re-search-forward org-todo-line-regexp nil t)
                          (push (list
                                 (org-make-org-heading-search-string
                                  (match-string 3) t))
                                tbl)))
                  tbl)
                 (tag (setq type :tag beg beg1)
                      (or org-tag-alist (org-get-buffer-tags)))
                 (prop (setq type :prop beg beg1)
                       (mapcar 'list (org-buffer-property-keys nil t t)))
                 (t (progn
                     (call-interactively org-completion-fallback-command)
                     (throw 'exit nil))))))
    (setq ac-org-pattern (buffer-substring-no-properties beg end))
    table))

(defvar ac-source-org nil)
(setq ac-source-org
      `((sigil . "o")
        (init . (lambda () (setq ac-org-candidates
                                 (condition-case nil
                                                 (ac-org-construct-candidates)))))
        (candidates . (lambda ()
                        (all-completions ac-target ac-org-candidates)))))




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun ac-emacs-lisp-mode-setup ()
  (setq ac-sources '(ac-source-words-in-buffer ac-source-functions ac-source-variables ac-source-symbols ac-source-features ac-source-yasnippet)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'dss-completion)
