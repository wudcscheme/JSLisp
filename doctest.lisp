(let ((tested (list))
      (skipped (list))
      (total 0)
      (failed 0))
  (dolist (n (keys (js-code "glob")))
    (when (find (slice n 0 3) (list "f$$" "m$$"))
      (let ((f (aref (js-code "glob") n))
            (name (demangle n)))
        (if (callable? f)
            (when (and f.documentation
                       (find "[[" f.documentation)
                       (find ";; ==>" f.documentation))
              (push name tested)
              (let* ((doc f.documentation)
                     (tstart (last-index "[[" f.documentation))
                     (tend (last-index "]]" f.documentation))
                     (test (slice doc (+ 2 tstart) tend)))
                (enumerate (num case (split test "\n\n"))
                  (incf total)
                  (let* ((err (find "\n**ERROR**: " case))
                         (ix (if err
                                 (index "\n**ERROR**: " case)
                                 (index "\n;; ==> " case)))
                         (src (strip (slice case 0 ix)))
                         (reference (replace
                                     (strip (replace
                                             (if (find "\n**ERROR**: " case)
                                                 "**ERROR**"
                                                 (slice case (+ 8 (index "\n;; ==> " case))))
                                             "\n;;.*" ""))
                                     "\\n\\s+" " "))
                         (result (try
                                  (str-value (toplevel-eval (parse-value src)))
                                  "**ERROR**")))
                    (unless (= result reference)
                      (incf failed)
                      (alert ~"FAILURE: {name} (test #{(1+ num)})\n\n\
                               src={(json src)}\n\n\
                               result={(json result)}\n\n\
                               reference={(json reference)}"))))))
            (push name skipped)))))
  (display ~"total: {total} test cases")
  (display ~"failed: {failed}")
  (display ~"tested {(length tested)} functions/macros: {tested}")
  (display ~"skipped {(length skipped)}: {skipped}"))