(require 'dss-basic-editing)
(require 'k2-mode)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun dss/display-syntax (syntax-type)
  (eq syntax-type (syntax-ppss-context (syntax-ppss))))

(defun dss/in-syntax-p (syntax-type)
  "This only answers if you're in a comment or string at the moment."
  (eq syntax-type (syntax-ppss-context (syntax-ppss))))

(defun dss/in-string-p ()
  (dss/in-syntax-p 'string))

(defun dss/in-comment-p ()
  (dss/in-syntax-p 'comment))

(defun dss/blank-line-p ()
  "Return non-nil iff current line is blank."
  (save-excursion
    (beginning-of-line)
    (looking-at "\\s-*$")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun dss/beginning-of-string ()
  "Go to beginning of string around point.
Do nothing if not in string."
  ;; from loveshack's python-beginning-of-string
  (interactive)
  (if (and (not (dss/in-string-p))
           (save-excursion
             (backward-char)
             (dss/in-string-p)))
      (backward-char))
  (let ((state (syntax-ppss)))
    (when (eq 'string (syntax-ppss-context state))
      (goto-char (nth 8 state)))))

(defun dss/end-of-string ()
  (interactive)
  (if (and (not (dss/in-string-p))
           (save-excursion
             (forward-char)
             (dss/in-string-p)))
      (forward-char))
  (if (dss/in-string-p)
      (progn
        (dss/beginning-of-string)
        (forward-sexp))))

(defun dss/mark-string ()
  (interactive)
  (if (dss/in-string-p)
      (progn
        (dss/beginning-of-string)
        ;; (mark-sexp) ; vs
        (forward-char)
        (push-mark nil nil t)


        (dss/end-of-string)
        (backward-char)
        ;;
        )))

(defun dss/forward-string (&optional backward)
  (interactive)
  (if (dss/in-string-p)
      (dss/end-of-string))
  (while (not (dss/in-string-p))
    (if backward
        (backward-char)
      (forward-char))))

(defun dss/backward-string ()
  (interactive)
  (if (dss/in-string-p)
      (dss/beginning-of-string))
  (dss/forward-string t)
  (dss/beginning-of-string)
  (forward-char))

;@@TR: I should add some similar functions for working with comments etc.

(defun dss/out-sexp (&optional level forward syntax)
  "Skip out of any nested brackets.
 Skip forward if FORWARD is non-nil, else backward.
 If SYNTAX is non-nil it is the state returned by `syntax-ppss' at point.
 Return non-nil if and only if skipping was done."
  (interactive)
  (if (dss/in-string-p)
      (dss/beginning-of-string))
  (progn
    (let* ((depth (syntax-ppss-depth (or syntax (syntax-ppss))))
          (level (or level depth))
          (forward (if forward -1 1)))
      (unless (zerop depth)
        (if (> depth 0)
            ;; Skip forward out of nested brackets.
            (condition-case ()            ; beware invalid syntax
                (progn (backward-up-list (* forward level)) t)
              (error nil))
          ;; Invalid syntax (too many closed brackets).
          ;; Skip out of as many as possible.
          (let (done)
            (while (condition-case ()
                       (progn (backward-up-list forward)
                              (setq done t))
                     (error nil)))
            done))))))

;; (bounds-of-thing-at-point 'sexp)
(defun dss/out-one-sexp (&optional forward)
  (interactive)
  (dss/out-sexp 1 forward))

(defun dss/out-one-sexp-forward ()
  (interactive)
  (dss/out-sexp 1 1))

(require 'hl-line)

(defun dss/flash-region (beg end)
  (interactive "r")
  (let ((ovl (make-overlay beg end))
        (was-mark-active mark-active)
        (hl-line-mode-on hl-line-mode))
    (setq mark-active nil)
    (overlay-put ovl 'face 'highlight)
    (run-with-timer 0.5 nil
                    (lambda(ovl was-mark-active)
                      (delete-overlay ovl)
                      (setq mark-active was-mark-active))
                    ovl was-mark-active)))

(defun dss/indent-sexp ()
  "http://mihai.bazon.net/projects/editing-javascript-with-emacs-js2-mode
  can be used from any coding major mode"
  (interactive)
  (save-restriction
    (save-excursion
      (widen)
      (let* ((inhibit-point-motion-hooks t)
             (parse-status (syntax-ppss (point)))
             (beg (nth 1 parse-status))
             (end-marker (make-marker))
             (end (progn (goto-char beg) (forward-list) (point))))
        (dss/flash-region beg end)
        (set-marker end-marker end)
        (goto-char beg)
        (while (< (point) (marker-position end-marker))
          ;; don't reindent blank lines so we don't set the "buffer
          ;; modified" property for nothing
          (beginning-of-line)
          (unless (looking-at "\\s-*$")
            (indent-according-to-mode))
          (forward-line))))))


(defun dss/indent-defun ()
  (interactive)
  (save-excursion
    (dss/out-sexp)
    (forward-char)
    (dss/indent-sexp)))

(defun dss/defun-name ()
  (interactive)
  (save-excursion
    (dss/out-sexp)
    (forward-to-word 1)
    (forward-sexp)
    (skip-chars-forward " ")
    (mark-sexp 1)
    (let ((defun-name (buffer-substring (region-beginning) (region-end))))
      (if defun-name
          (set-text-properties 0 (length defun-name) nil defun-name))
      defun-name)))

(defun dss/copy-defun-name ()
  (interactive)
  (let ((defun-name (dss/defun-name)))
    (kill-new defun-name)
    (message defun-name)))

(defun dss/eval-defun ()
  "The built-in eval-defun doesn't choose the top level forms I would expect expect"
  (interactive)
  (dss/indent-defun)
  (save-excursion
    (dss/out-sexp nil t)
    (cond ((or (equal major-mode 'clojure-mode)
               (equal major-mode 'slime-repl-mode))
           (slime-eval-last-expression))
          (t (progn
               (eval-last-sexp nil)
               (smex-update))))))

;; (message "%S" (preceding-sexp))


(defun dss/goto-defun-name ()
  (interactive)
  (dss/out-sexp)
  (forward-to-word 2))

(defun dss/goto-defun-docstring ()
  "Jumps to the first quote in the defun form. If there is no
  docstring it just jumps forward to the first quote anyway. I
  should make this smarter and have it automatically insert the
  docstring if one does not exist."

  (interactive)
  (dss/goto-defun-name)
  (search-forward-regexp "\""))

(defun dss/goto-defun-args ()
  (interactive)
  (dss/goto-defun-name)
  (search-forward-regexp "(\\|\\["))

(defun dss/fix-sexp-whitespace ()
  (interactive)
  (save-excursion
    (dss/out-sexp 1)
    (forward-char)
    (fixup-whitespace)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun dss/electric-pair ()
  "If at end of line, insert character pair without surrounding spaces.
   Otherwise, just insert the typed character."
  (interactive)
  ;(if (eolp) (let (parens-require-spaces) (insert-pair))
  ;  (self-insert-command 1)))
  (if (or (dss/in-string-p)
          (dss/in-comment-p))
      (self-insert-command 1)
    (let (parens-require-spaces)
      (insert-pair))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'imenu)
(defun ido-imenu ()
  "Update the imenu index and then use ido to select a symbol to navigate to.
Symbols matching the text at point are put first in the completion list.
Comes from http://github.com/technomancy/emacs-starter-kit/blob/master/starter-kit-defuns.el"
  (interactive)
  (imenu--make-index-alist)
  (let ((name-and-pos '())
        (symbol-names '()))
    (flet ((addsymbols (symbol-list)
                       (when (listp symbol-list)
                         (dolist (symbol symbol-list)
                           (let ((name nil) (position nil))
                             (cond
                              ((and (listp symbol) (imenu--subalist-p symbol))
                               (addsymbols symbol))

                              ((listp symbol)
                               (setq name (car symbol))
                               (setq position (cdr symbol)))

                              ((stringp symbol)
                               (setq name symbol)
                               (setq position (get-text-property 1 'org-imenu-marker symbol))))

                             (unless (or (null position) (null name))
                               (add-to-list 'symbol-names name)
                               (add-to-list 'name-and-pos (cons name position))))))))
      (addsymbols imenu--index-alist))
    ;; If there are matching symbols at point, put them at the beginning of `symbol-names'.
    (let ((symbol-at-point (thing-at-point 'symbol)))
      (when symbol-at-point
        (let* ((regexp (concat (regexp-quote symbol-at-point) "$"))
               (matching-symbols (delq nil (mapcar (lambda (symbol)
                                                     (if (string-match regexp symbol) symbol))
                                                   symbol-names))))
          (when matching-symbols
            (sort matching-symbols (lambda (a b) (> (length a) (length b))))
            (mapc (lambda (symbol) (setq symbol-names (cons symbol (delete symbol symbol-names))))
                  matching-symbols)))))
    (let* ((selected-symbol (ido-completing-read "Symbol? " symbol-names))
           (position (cdr (assoc selected-symbol name-and-pos))))
      (goto-char position))))

;; ; http://nflath.com/2009/07/imenu/
;; (require 'imenu)
;; (setq imenu-auto-rescan t)
;; (defun ido-goto-symbol ()
;;   "Will update the imenu index and then use ido to select a symbol to navigate to"
;;   (interactive)
;;   (imenu--make-index-alist)
;;   (let ((name-and-pos '())
;;         (symbol-names '()))
;;     (flet ((addsymbols (symbol-list)
;;                        (when (listp symbol-list)
;;                          (dolist (symbol symbol-list)
;;                            (let ((name nil) (position nil))
;;                              (cond
;;                               ((and (listp symbol) (imenu--subalist-p symbol))
;;                                (addsymbols symbol))
;;                               ((listp symbol)
;;                                (setq name (car symbol))
;;                                (setq position (cdr symbol)))
;;                               ((stringp symbol)
;;                                (setq name symbol)
;;                                (setq position (get-text-property 1 'org-imenu-marker symbol))))
;;                              (unless (or (null position) (null name))
;;                                (add-to-list 'symbol-names name)
;;                                (add-to-list 'name-and-pos (cons name position))))))))
;;       (addsymbols imenu--index-alist))
;;     (let* ((selected-symbol (ido-completing-read "Symbol? " symbol-names))
;;               (position (cdr (assoc selected-symbol name-and-pos))))
;;       (if (markerp position)
;;             (goto-char position) (goto-char (overlay-start position))))))

(setq imenu-auto-rescan t)

(defun dss/line-jump (n)
  (interactive "nLine: ")
  (dss/goto-line n)
  (back-to-indentation))

(defun dss/local-line-jump (n)
  (interactive "nLine: ")
  (if (> n 100)
      (dss/line-jump n)
    (dss/line-jump (+ n (* (/ (line-number-at-pos) 100) 100)))))

(defun dss/local-line-jump-search (n txt)
  (interactive "nLine: \nsText:")
  (dss/local-line-jump n)
  (search-forward (downcase txt) (line-end-position)))

(defun dss/highlight-watchwords ()
  ;; http://github.com/technomancy/emacs-starter-kit/blob/master/starter-kit-defuns.el
  (interactive)
  ;; (font-lock-add-keywords
  ;;  nil '(("\\<\\(FIX\\|TODO\\|FIXME\\|HACK\\|@@TR\\|REFACTOR\\)*:"
  ;;         1 font-lock-warning-face t)))
  (highlight-regexp "\\<\\(FIXME\\|FIX\\|TODO\\|HACK\\|TR\\|REFACTOR\\):?" 'font-lock-warning-face))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'dss-codenav-helpers)
