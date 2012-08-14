(require 'auto-complete)
(require 'ido)
(require 'comint)
(require 'org)
(require 'fm)
(require 'sunrise-commander)
(require 'dss-buffer-and-window-handling)
(require 'dss-command-history-and-freqs)
(require 'dss-lisps)
(require 'dss-completion)
(require 'dss-bookmarks-registers)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; additional custom keymaps, populated below
(defvar f2-map (make-sparse-keymap))
;(defvar f3-map (make-sparse-keymap))
(defvar f4-map (make-sparse-keymap))
(defvar f6-map (make-sparse-keymap))
(defvar f7-map (make-sparse-keymap))
(defvar f8-map (make-sparse-keymap))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; global map
(define-key global-map (kbd "M-X") 'smex-update-and-run)
(define-key global-map (kbd "M-x") 'smex)
(define-key global-map (kbd "M-s") 'ido-goto-symbol)
(define-key global-map (kbd "M-]") 'dss/multi-term)
(define-key global-map (kbd "M-,") 'dss/magit-or-monky)
(define-key global-map (kbd "C-M-]") 'sunrise-cd)
(define-key global-map (kbd "C-M-l") 'dss/sync-point-all-windows)

(defun dss/hippie-expand ()
  (interactive)
  (if (not ac-completing)
      (call-interactively 'hippie-expand)
    (ac-expand)))
(global-set-key (kbd "M-/") 'dss/hippie-expand)
(global-set-key (kbd "M-TAB") 'dabbrev-expand)


(global-set-key "\C-ca" 'org-agenda)
(global-set-key "\C-cl" 'org-store-link)
(global-set-key "\C-cb" 'org-iswitchb)
(global-set-key (kbd "C-M-r") 'org-remember)

(global-set-key (kbd "C-x C-r") 'dss/ido-choose-from-recentf)
(global-set-key (kbd "C-x C-p") 'dss/ido-find-file-at-point)
(global-set-key (kbd "C-x C-v") 'revert-buffer)

(global-set-key (kbd "C-x r b") 'dss/bookmark-jump)
(global-set-key (kbd "C-x r v") 'list-register)

(define-key help-map "." 'find-function)
(define-key help-map "," 'find-variable)

(define-key global-map [(f2)] f2-map)
(define-key global-map "\eOQ" f2-map)

(define-key global-map [(f3)] 'dss/smex)
(define-key global-map "\eOR" 'dss/smex)

(define-key global-map [(f4)] f4-map)
(define-key global-map "\eOS" f4-map)
(define-key global-map [(f5)] 'undo)
(define-key global-map [(f6)] f6-map)
(define-key global-map [(f7)] f7-map)
(define-key global-map [(f8)] f8-map)

(define-key global-map [(f12)] 'save-buffer)

(define-key global-map [(alt insert)] 'yank-pop)
(define-key global-map "\e[4~" 'end-of-line)
(define-key global-map "\e\e[4~" 'end-of-buffer)
(define-key global-map "\e\e[1~" 'beginning-of-buffer)

(define-key global-map "\eOa" 'backward-paragraph)
(define-key global-map "\e\eOA" 'backward-paragraph)
(define-key global-map "\e\e[A" 'backward-paragraph)
(define-key global-map "\e\eOB" 'forward-paragraph)
(define-key global-map "\e\e[B" 'forward-paragraph)
(define-key global-map "\eOb" 'forward-paragraph)

;;; there has to be a cleaner way to do this ...

(define-key global-map "\eOc" (kbd "M-f"))
(require 'misc)
(require 'subword)
(define-key global-map (kbd "M-f") 'forward-to-word)
(define-key subword-mode-map (kbd "M-f") 'forward-word)
(define-key global-map "\eOd" 'backward-word)

;;; http://www.gnu.org/software/emacs/manual/html_node/viper/Key-Bindings.htm
;;; ;@@TR: the following needs to be translated to use input-decode-map
;; terminal/gnu-screen arrow key support
(define-key global-map "\e[A" (kbd "<up>"))
(define-key global-map "\e[B" (kbd "<down>"))
(define-key global-map "\e[C" (kbd "<right>"))
(define-key global-map "\e[D" (kbd "<left>"))

(define-key global-map "\e[1;9A" (kbd "M-<up>"))
(define-key global-map "\e[1;9B" (kbd "M-<down>"))
(define-key global-map "\e[1;9C" (kbd "M-<right>"))
(define-key global-map "\e[1;9D" (kbd "M-<left>"))

;;; shift arrow key support inside of gnu screen / iTerm
(define-key global-map "\eO2D" (kbd "S-<left>"))
(define-key global-map "\eO2C" (kbd "S-<right>"))
(define-key global-map "\eO2A" (kbd "S-<up>"))
(define-key global-map "\eO2B" (kbd "S-<down>"))

(define-key global-map "\e[1;2D" (kbd "S-<left>"))
(define-key global-map "\e[1;2C" (kbd "S-<right>"))
(define-key global-map "\e[1;2A" (kbd "S-<up>"))
(define-key global-map "\e[1;2B" (kbd "S-<down>"))

;;; shift arrow in gnu screen / urxvt
(define-key global-map "\e[d" (kbd "S-<left>"))
(define-key global-map "\e[c" (kbd "S-<right>"))
(define-key global-map "\e[a" (kbd "S-<up>"))
(define-key global-map "\e[b" (kbd "S-<down>"))

(define-key global-map "\e[1;10D" (kbd "M-S-<left>"))
(define-key global-map "\e[1;10C" (kbd "M-S-<right>"))
(define-key global-map "\e[1;10A" (kbd "M-S-<up>"))
(define-key global-map "\e[1;10B" (kbd "M-S-<down>"))

(define-key paredit-mode-map (kbd "C-<right>") 'forward-word)
(define-key paredit-mode-map (kbd "C-<left>") 'backward-word)

(define-key ido-common-completion-map "\e[A" 'previous-history-element)
(define-key ido-common-completion-map "\e[B" 'next-history-element)
;; (define-key ido-common-completion-map (kbd "C-g") 'keyboard-escape-quit)

;;;;;;;;;
;; this crap is only necessary because of the kbd macro crap above
(define-key ido-common-completion-map "\e[C" 'ido-next-match)
(define-key ido-common-completion-map "\e[D" 'ido-prev-match)

;; (define-key ido-completion-map "\e[C" 'ido-next-match)
;; (define-key ido-completion-map "\e[D" 'ido-prev-match)

(define-key ido-file-dir-completion-map "\e[C" 'ido-next-match)
(define-key ido-file-dir-completion-map "\e[D" 'ido-prev-match)
(define-key ido-file-dir-completion-map "\C-]" 'ido-undo-merge-work-directory)


(define-key ido-buffer-completion-map "\e[C" 'ido-next-match)
(define-key ido-buffer-completion-map "\e[D" 'ido-prev-match)

;;;;;;;;

(defun up-slightly () (interactive) (scroll-up 5))
(defun down-slightly () (interactive) (scroll-down 5))
(define-key global-map [mouse-4] 'down-slightly)
(define-key global-map [mouse-6] 'down-slightly)
(define-key global-map [mouse-5] 'up-slightly)



;http://www.emacsblog.org/2007/02/27/quick-tip-add-occur-to-isearch/
(define-key isearch-mode-map (kbd "C-o")
  (lambda ()
    (interactive)
    (let ((case-fold-search isearch-case-fold-search))
      (occur (if isearch-regexp isearch-string
               (regexp-quote isearch-string))))))

(defun dss/confirm-exit-emacs ()
  "ask for confirmation before exiting emacs"
  (interactive)
  (if (y-or-n-p "Are you sure you want to exit? ")
      (save-buffers-kill-emacs)))

(global-unset-key "\C-x\C-c")
(global-set-key "\C-x\C-c" 'dss/confirm-exit-emacs)
(global-set-key "\C-x\C-m" 'execute-extended-command)
                      ;for when I don't want to use smex
(global-set-key "\C-x\C-b" 'ibuffer)
(define-key ibuffer-mode-map (kbd "M-g") 'goto-line)

;comint-previous-matching-input-from-input
;; (define-key py-shell-map (quote [up])
;;'comint-previous-matching-input-from-input)

;; (define-key py-shell-map (quote [down])
;; 'comint-next-matching-input-from-input)

(defun dss/comint-previous-matching-input ()
  (interactive)
  (if (comint-after-pmark-p)
      (call-interactively 'comint-previous-matching-input-from-input)
    (call-interactively 'scroll-down-command)))

(defun dss/comint-next-matching-input ()
  (interactive)
  (if (comint-after-pmark-p)
      (call-interactively 'comint-next-matching-input-from-input)
    (call-interactively 'scroll-up-command)))

(defun dss/comint-next-input ()
  (interactive)
  (if (comint-after-pmark-p)
      (call-interactively 'comint-next-input)
    (call-interactively 'next-line)))

(defun dss/comint-previous-input ()
  (interactive)
  (if (comint-after-pmark-p)
      (call-interactively 'comint-previous-input)
    (call-interactively 'previous-line)))

(defun dss/comint-mode-hook (&optional mode-map)
  (interactive)
  (let ((mode-map (or mode-map comint-mode-map)))
    (define-key mode-map (kbd "<prior>") 'dss/comint-previous-matching-input)
    (define-key mode-map (kbd "<next>") 'dss/comint-next-matching-input)
    (define-key mode-map (kbd "<down>") 'dss/comint-next-input)
    (define-key mode-map (kbd "<up>") 'dss/comint-previous-input)

    (define-key mode-map (kbd "C-M-r") 'comint-history-isearch-backward)
    (define-key mode-map (kbd "C-M-s") 'comint-history-isearch-search)

    (define-key mode-map (kbd "M-p") 'previous-line)
    (define-key mode-map (kbd "M-n") 'next-line)
    (define-key mode-map (kbd "C-M-l") 'comint-goto-process-mark)))

(add-hook 'comint-mode-hook 'dss/comint-mode-hook)


(define-key read-expression-map (kbd "TAB") 'lisp-complete-symbol)
(define-key lisp-mode-shared-map (kbd "C-c l") "lambda")
(define-key lisp-mode-shared-map (kbd "RET") 'reindent-then-newline-and-indent)
(define-key lisp-mode-shared-map (kbd "M-TAB") 'lisp-complete-symbol)
(define-key lisp-mode-shared-map (kbd "C-c v") 'eval-buffer)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; additional custom maps, defined and hooked into global-map above

;; f2-map

(define-key f2-map "j" 'windmove-left)
(define-key f2-map "l" 'windmove-right)
(define-key f2-map "k" 'windmove-down)
(define-key f2-map "i" 'windmove-up)

(define-key f2-map "m" 'flymake-goto-prev-error)
(define-key f2-map "," 'flymake-goto-next-error)

(define-key f2-map "[" 'isearch-forward-at-point)

(define-key f2-map "=" 'dvc-status)
(define-key f2-map "-" 'dvc-diff)

(define-key f2-map "r" 'recursive-edit)


;; f4-map

(define-key f4-map " " 'fixup-whitespace)
(defun dss/eval-region-or-last-sexp ()
  (interactive)
  (if mark-active
      (call-interactively 'eval-region)
    (call-interactively 'eval-last-sexp)))

(define-key f4-map "s" 'dss/eval-region-or-last-sexp)
(define-key f4-map "d" 'dss/eval-defun)

(define-key f4-map "x" 'dss/magit-or-monky)
(define-key f4-map "v" 'dss/magit-or-monky)
(define-key f4-map "q" 'monky-queue)

(define-key f4-map "3" 'dss/out-sexp)
(define-key f4-map "8" 'dss/out-one-sexp)

(define-key f4-map "9" 'paredit-wrap-round)
(define-key f4-map "0" 'paredit-close-round-and-newline)

(define-key f4-map [(f4)] (kbd "TAB"))
;(define-key f4-map [(f4)] 'kill-ring-save)
(define-key f4-map "i" 'yank)
(define-key f4-map "u" 'undo)

(define-key f4-map "y" 'dss/mark-string)
(define-key f4-map "m" 'mark-sexp)

(define-key f4-map "'" (kbd "\""))
(define-key f4-map "," 'sunrise-cd)
;; (define-key f4-map "c" 'k2-copy-whole-sexp)

(define-key sr-mode-map ","  'dss/multi-term)
(define-key sr-mode-map "V"  'dss/magit-or-monky)

;;(define-keymap f4-map "n" 'dss/goto-match-paren)
(define-key f4-map ";" 'goto-last-change)

(require 'iedit)

(defvar *dss-iedit-auto-complete-was-on* nil)
(make-variable-buffer-local '*dss-iedit-auto-complete-was-on*)
(defun dss/iedit-toggle ()
  (interactive)
  (if iedit-mode
      (progn
        (if *dss-iedit-auto-complete-was-on*
            (progn
              (setq *dss-iedit-auto-complete-was-on* nil)
              (auto-complete-mode t)))
        (iedit-mode))
    (progn
      (if auto-complete-mode
          (progn
            (setq *dss-iedit-auto-complete-was-on* t)
            (auto-complete-mode nil)))
      (iedit-mode))))

(define-key f4-map "e" 'dss/iedit-toggle)

(define-key f4-map "6" 'dss/backward-string)
(define-key f4-map "7" 'dss/forward-string)

(define-key f4-map "-" 'dss/clojure-run-tests)
(define-key f4-map "c" 'dss/slime-repl-clear)
(define-key f4-map "p" 'dss/clojure-jump-to-project)
(define-key f4-map "j" 'dss/clojure-jump-between-tests-and-code)

(define-key f4-map "/" 'dss/goto-match-paren)
(define-key f4-map "]" 'dss/smex)


;; f6-map


(defun dss/insert-todo ()
  (interactive)
  (insert comment-start)
  (insert "@@TR: "))

(defun open-next-line()
  (interactive)
  (save-excursion
    (end-of-line)
    (open-line 1)))

(defun fm-occur(arg)
  (interactive "soccur: ")
  (occur arg)
  (other-window 1)
  (fm-start))

(define-key f6-map "`" 'open-next-line)
(define-key f6-map [(f6)] 'open-next-line)
(define-key f6-map "1" 'replace-string)
(define-key f6-map "i" 'dss/insert-todo)
(define-key f6-map "l" 'linum-mode)
(define-key f6-map "o" 'fm-occur)
(define-key f6-map ";" 'string-rectangle)

(define-key f6-map "k" 'dss/kill-buffer)

;; f7-map, which I rarely use these days
(require 'k2-mode) ; my old keymap extension package
(k2-mode) ; start k2-mode by default

(define-key f7-map "l" 'list-bookmarks)
(define-key f7-map "g" 'dss/bookmark-jump)
(define-key f7-map "b" 'ido-switch-buffer)

(define-key f7-map "s" 'dss/toggle-window-split)
(define-key f7-map "t" 'dss/transpose-windows)

;; (define-key f7-map "d" 'dss-defun-skeleton)
;; (define-key f7-map "i" '(lambda ()
;;                           (interactive)
;;                           (insert "(interactive)")))

(define-key f7-map "d" 'slime-describe-symbol)
(define-key f7-map "i" 'slime-inspect)
(define-key f7-map [(f7)] 'slime-selector)
(define-key f7-map "a" 'slime-apropos)

(define-key f7-map "=" 'dss/toggle-current-window-dedication)
(define-key f7-map "'" 'k2-kill-whole-paragraph)
(define-key f7-map "," 'k2-copy-whole-paragraph)
(define-key f7-map "." 'mark-paragraph)
(define-key f7-map "0" 'k2-toggle-mark)

;; f8 map for org-mode
;; @@TR: add bindings for org node promote, demote
(define-key f8-map "n" 'org-insert-heading-respect-content)
(define-key f8-map "s" 'org-insert-subheading)
(define-key f8-map "t" 'org-insert-todo-heading-respect-content)
(define-key f8-map "m" 'dss/multi-term)

(define-key f8-map "r" 'org-capture)

(define-key f8-map "i" 'org-clock-in)
(define-key f8-map "o" 'org-clock-out)
(define-key f8-map "d" (lambda ()
                          "C-u C-u C-c C-x C-i -> org-clock-mark-default-task"
                          (interactive)
                          (org-clock-in '(16))))
(define-key f8-map "." 'org-time-stamp)

(define-key f8-map "c" 'org-clock-cancel)

;(define-key f8-map "_" 'org-clock-select-task)
(defun dss/org-clock-in-select ()
  "C-u C-c C-x C-i -> org-clock-select-task"
  (interactive)
  (org-clock-in '(4)))

(defun dss/org-clock-goto-select-task ()
  "C-u C-c C-x C-i -> org-clock-goto via org-clock-select-task"
  (interactive)
  (org-clock-goto '(4)))

(defun dss/org-refile-goto ()
  "org-goto using refile ui"
  (interactive)
  (org-refile '(4)))

(define-key f8-map "_" 'dss/org-clock-in-select)
(define-key f8-map "-" 'org-clock-goto)
(define-key f8-map "'" 'dss/org-clock-goto-select-task)
(define-key f8-map "g" 'dss/org-refile-goto)

;; (define-key f8-map "l" (lambda ()
;;                           "org-goto last refile location"
;;                           (interactive)
;;                           (org-refile '(16))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'dss-keybindings)
