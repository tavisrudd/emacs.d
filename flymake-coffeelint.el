(require 'flymake)

;;; see https://github.com/ajkavanagh/coffeelintnode
;;; https://github.com/kui/flymake-coffeescript/blob/master/flymake-coffeescript.el
;;;

(defcustom flymake-coffeelint-program "coffeelint.sh"
  "The JSHint program name."
  :type 'string
  :group 'flymake-coffeelint)

(defcustom flymake-coffeelint-config nil
  "If non-nil, specifies the location of the JSHint configuration file to use."
  :type 'string
  :group 'flymake-coffeelint)

(defun flymake-coffeelint-init ()
  (let* ((temp-file (flymake-init-create-temp-buffer-copy
                     'flymake-create-temp-inplace))
         (local-file (file-relative-name
                      temp-file
                      (file-name-directory buffer-file-name)))
         (arglist (list local-file)))
    (if flymake-coffeelint-config
        (setq arglist (append arglist (list "--config" (expand-file-name flymake-coffeelint-config)))))
    (list flymake-coffeelint-program arglist)))

(setq flymake-err-line-patterns
      (cons '(" +✗ *#\\([[:digit:]]+\\): \\(.+\\)$"
              nil 1 nil 2)
            flymake-err-line-patterns))
;;;      ✗ #16: Line contains a trailing semicolon.

(setq flymake-err-line-patterns
      (cons '("Error: Parse error on line \\([[:digit:]]+\\): \\(.+\\)$"
              nil 1 nil 2)
            flymake-err-line-patterns))

(setq flymake-err-line-patterns
      (cons '("SyntaxError:\\(.+\\) on line \\([[:digit:]]+\\)$"
              nil 2 nil 1)
            flymake-err-line-patterns))

(add-to-list 'flymake-allowed-file-name-masks
             '(".+\\.coffee$" flymake-coffeelint-init))

(provide 'flymake-coffeelint)
