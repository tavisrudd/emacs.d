;; python-mode
(require 'dss-paths)
(require 'dss-codenav-helpers)
(setq py-load-pymacs-p nil)
(require 'python-mode)
(require 'flymake)

(require 'dss-generic-code-tools) ; flymake/lint stuff

;;; see http://pedrokroger.net/blog/2010/07/configuring-emacs-as-a-python-ide-2/
;;; for a good overview of another very complete setup
(add-to-list 'auto-mode-alist '("\\.py$" . python-mode))
(add-to-list 'interpreter-mode-alist '("python" . python-mode))

(defvar dss-pycodechecker "dss_pycheck") ; this is a wrapper around pep8.py, pyflakes and pylint

(when (load "flymake" t)
  (load-library "flymake-cursor")
  (defun flymake-pycodecheck-init ()
    (let* ((temp-file (flymake-init-create-temp-buffer-copy
                       'flymake-create-temp-inplace))
           (local-file (file-relative-name
                        temp-file
                        (file-name-directory buffer-file-name))))
      (if (not (string-match-p tramp-file-name-regexp buffer-file-name))
          ;; don't run for tramp buffers.
          (list dss-pycodechecker (list local-file)))))
  (add-to-list 'flymake-allowed-file-name-masks
               '("\\.py\\'" flymake-pycodecheck-init)))

;; (setq flymake-allowed-file-name-masks (assq-delete-all "\\.py\\'" flymake-allowed-file-name-masks))
;; (assoc "\\.py\\'" flymake-allowed-file-name-masks)

(defun dss/pylint-silence (msgid)
  "Add a special pylint comment to silence a particular warning."
  (interactive (list (read-from-minibuffer "msgid: " (dss/flymake-msgid-at-point))))
  (save-excursion
    (comment-dwim nil)
    (if (looking-at "pylint:")
        (progn (end-of-line)
               (insert ","))
        (insert "pylint: disable-msg="))
    (insert msgid)))


(defun dss/py-insert-docstring ()
  (interactive)
  (if (not (save-excursion
             (forward-line 1)
             (back-to-indentation)
             (looking-at "[\"']")))
      (save-excursion
        (end-of-line)
        (open-line 1)
        (forward-line 1)
        (py-indent-line)
        (insert "\"\"\"\n")
        (py-indent-line)
        (insert "\"\"\"")))
  (progn
    (forward-line 1)
    (end-of-line)))

(defun dss/py-insert-triple-quote ()
  (interactive)
  (insert "\"\"\"")
  (save-excursion (insert " \"\"\"")))

(defun dss/py-fix-indent (top bottom)
  (interactive "r")
  (apply-macro-to-region-lines top bottom (kbd "TAB")))

(defun dss/py-fix-last-utterance ()
  "Downcase the previous word and remove any leading whitespace.
This is useful with Dragon NaturallySpeaking."
  (interactive)
  (save-excursion
    (backward-word)
    (set-mark (point))
    (call-interactively 'py-forward-into-nomenclature)
    (call-interactively 'downcase-region)
    (setq mark-active nil)
    (backward-word)
    (delete-horizontal-space t)))

(defun dss/py-dot-dictate (words)
  (interactive "s")
  (progn
    (if (looking-at-p "\\.")
        (forward-char))
    (delete-horizontal-space t)
    (if (save-excursion
          (backward-char)
          (not (looking-at-p "\\.")))
        (insert "."))
    (insert (mapconcat 'identity (split-string words) "_"))
    (dss/py-fix-last-utterance)
    (delete-horizontal-space t)))

(defun dss/py-decorate-function (&optional decorator-name)
  (interactive)
  (beginning-of-line-text)
  (if (not (or (looking-at "def\\|class")
               (looking-at "@")))
      (progn
        (py-beginning-of-def-or-class)
        (beginning-of-line-text)))
  (if (not (save-excursion
             (forward-line -1)
             (beginning-of-line-text)
             (looking-at-p "@")))
      (progn
        ;;  make room for it:
        (while (not (save-excursion
                      (forward-line -1)
                      (beginning-of-line-text)
                      (looking-at-p "$")))
          (save-excursion
            (forward-line -1)
            (end-of-line)
            (open-line 1)))
        (insert "@")
        (open-line 1)
        (if decorator-name
            (insert decorator-name))
        (save-excursion
          (forward-line 1)
          (py-indent-line)))))

(defun dss/py-make-classmethod ()
  (interactive)
  (dss/py-decorate-function "classmethod"))

(defun dss/py-comment-line-p ()
  "Return non-nil iff current line has only a comment.
This is python-comment-line-p from Dave Love's python.el"
  (save-excursion
    (end-of-line)
    (when (eq 'comment (syntax-ppss-context (syntax-ppss)))
      (back-to-indentation)
      (looking-at (rx (or (syntax comment-start) line-end))))))

(setq virtual-env (getenv "VIRTUAL_ENV"))
(defvar dss-ropemacs-loaded nil)
(defun dss/ropemacs-init ()
  (interactive)
  (unless dss-ropemacs-loaded
    (if (not (equal virtual-env nil))
        (setq load-path (append
                         (list (concat virtual-env "/src/pymacs" ))
                         load-path)))
    (require 'pymacs)
    (if (not (boundp 'ropemacs-global-prefix))
        (setq ropemacs-global-prefix nil))
    (pymacs-load "ropemacs" "rope-")
    (setq ropemacs-enable-autoimport nil)
    (define-key ropemacs-local-keymap (kbd "M-/") nil)
    (setq dss-ropemacs-loaded t)))


(defun dss/py-next-line ()
  (interactive)
  (end-of-line)
  (py-newline-and-indent))

(defun dss/py-insert-self ()
  "Insert self. at the beginning of the current expression."
  (interactive)
  (cond ((save-excursion
           (search-backward-regexp "[ \n\t,(-]\\|^")
           (looking-at "[A-Za-z_]+"))
         (save-excursion
           (search-backward-regexp "[ \n\t,(-]\\|^")
           (if (not (looking-at "^"))
               (forward-char))
           (insert "self.")))
        ((looking-at " *$")
         (insert "self"))
        (t (insert "self"))))

(defun dss/python-mode-hook ()
  (interactive)
  (dss/install-whitespace-cleanup-hook)
  (turn-on-auto-fill)
  ;; (which-function-mode t)
  (setq mode-name "PY:")
  (setq py-python-command-args '("-colors" "Linux"))
  (if (and (string-match "\\.py$" (buffer-name))
                                        ; and isn't a py-shell tmp buffer:
           (not (string-match "python-" (buffer-name))))
      (progn
        ;; (unless dss/ecb-loaded
        ;;   (dss/load-ecb)
        ;;   (smex-update))
        (dss/load-lineker-mode)
        (flymake-mode t)
        (linum-mode t)
        ;; (dss/ropemacs-init)
        ;; (ropemacs-mode t)
        (dss/highlight-watchwords)
        (dss/load-rope-completion)))

  ;; custom keybindings
  (mapc (lambda (char)
          (progn
            (define-key py-mode-map char 'dss/electric-pair)
            (define-key py-shell-map char 'dss/electric-pair)
            ))
        '("\"" "\'" "(" "[" "{"))

  (define-key py-mode-map (kbd "C-p") 'dss/py-insert-self)

  (define-key py-mode-map (kbd "M-RET") 'dss/py-next-line)
  (define-key py-mode-map (kbd "C-M-@") 'mark-sexp)
  ;; rope-code-assist
  (define-key py-mode-map (kbd "M-/") 'dss/hippie-expand)

  (define-key py-mode-map (kbd "M-@") 'etags-select-find-tag-at-point)
  (define-key py-mode-map (kbd "M-.") 'rope-goto-definition)

  ;;(define-key py-shell-map (kbd "C-M-@") 'dss/ido-ipython-complete)
  (define-key py-shell-map (kbd "C-M-@") 'mark-sexp)
  (define-key py-shell-map "\C-e" (lambda ()
                                    (interactive)
                                    (goto-char (point-max))))
  (define-key py-shell-map (quote [up]) 'comint-previous-matching-input-from-input)
  (define-key py-shell-map (quote [down]) 'comint-next-matching-input-from-input)

  ;;(local-set-key "\C-ch" 'pylookup-lookup)
  )

(add-hook 'python-mode-hook 'dss/python-mode-hook)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; python-mode helpers

;; ;@@TR: study this stuff for better remote proc control
;; http://wingolog.org/archives/2006/01/02/slime
;; http://hillview.1on.de/archives/122-python-mode-vs.-slime.html

;; ipython related
(set-default 'ipython-command "emacs_ipython") ; which is a shell script that handles all the virtualenv setup, etc
(require 'ipython)

(defun dss/reset-ipython-command ()
  (interactive)
  (setq py-which-shell ipython-command))

(require 'auto-complete)

(defun dss/start-ipy-complete ()
  (interactive)
  (setq ac-sources '(ac-source-dss-ipy-dot ac-source-dss-ipy ac-source-filename)))

(add-hook 'ipython-shell-hook 'dss/start-ipy-complete)
(add-hook 'py-shell-hook 'dss/start-ipy-complete)

(add-hook 'ipython-shell-hook '(lambda () (linum-mode -1)))
(add-hook 'py-shell-hook '(lambda () (linum-mode -1)))

;;

(autoload 'rst "rst")
(add-to-list 'auto-mode-alist '("\\.rst$" . rst-mode))
;;

;; (autoload 'doctest-mode "doctest-mode" "Editing mode for Python Doctest examples." t)
;; (autoload 'doctest-register-mmm-classes "doctest-mode")
;; (add-to-list 'auto-mode-alist '("\\.doctest$" . doctest-mode))
;; (doctest-register-mmm-classes t t)

; # @@TR: eldoc

;; cheetah .tmpl files
(autoload 'cheetah-mode "cheetah-mode")
(add-to-list 'auto-mode-alist '("\\.tmpl$" . cheetah-mode))

;; `Cython' mode.
(autoload 'cython-mode "cython-mode")
(add-to-list 'auto-mode-alist '("\\.pyx$" . cython-mode))
(add-to-list 'auto-mode-alist '("\\.pxd$" . cython-mode))

;; (require 'pylookup)
;; (autoload 'pylookup-lookup "pylookup"
;;   "Lookup SEARCH-TERM in the Python HTML indexes." t)
;; (autoload 'pylookup-update "pylookup"
;;   "Run pylookup-update and create the database at `pylookup-db-file'." t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'dss-python)
