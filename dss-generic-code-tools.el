
(defun dss/lint-ignore ()
  (interactive)
  (cond ((eq major-mode 'js2-mode)
         (dss/flymake-ignore))
        ((eq major-mode 'python-mode)
         (call-interactively 'dss/pylint-silence))
        (t
         (call-interactively 'dss/flymake-ignore))))

(define-key global-map (kbd "M-?") 'dss/lint-ignore)

(defun dss/flymake-msgid-at-point ()
  (interactive)
  (let (msgid
        (line-no (line-number-at-pos)))
    (dolist (elem flymake-err-info msgid)
      (if (eq (car elem) line-no)
          (let ((err (car (second elem))))
            (setq msgid (second (split-string (flymake-ler-text err)))))))))

(provide 'dss-generic-code-tools)
