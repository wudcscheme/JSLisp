
(defun set-action (name precond to-remove to-add)
  (lambda (state)
    (when (subset precond state)
      (list name (set-union (set-difference state to-remove)
                            to-add)))))

(defun build-block-actions (blocks)
  (let ((actions (list)))
    (dolist (x blocks)
      (dolist (y blocks)
        (when (/= x y)
          (dolist (z blocks)
            (when (and (/= x z) (/= y z))
              (push (set-action ~"{x}-from-{y}-to-{z}"
                                (list (intern ~"space-on-{x}")
                                      (intern ~"{x}-on-{y}")
                                      (intern ~"space-on-{z}"))
                                (list (intern ~"{x}-on-{y}")
                                      (intern ~"space-on-{z}"))
                                (list (intern ~"{x}-on-{z}")
                                      (intern ~"space-on-{y}")))
                    actions)))
          (push (set-action ~"{x}-from-{y}-to-table"
                            (list (intern ~"space-on-{x}")
                                  (intern ~"{x}-on-{y}"))
                            (list (intern ~"{x}-on-{y}"))
                            (list (intern ~"space-on-{y}")
                                  (intern ~"{x}-on-table")))
                actions)
          (push (set-action ~"{x}-from-table-to-{y}"
                            (list (intern ~"space-on-{x}")
                                  (intern ~"space-on-{y}")
                                  (intern ~"{x}-on-table"))
                            (list (intern ~"space-on-{y}")
                                  (intern ~"{x}-on-table"))
                            (list (intern ~"{x}-on-{y}")))
                actions))))
    actions))

(defun gps (start actions goal key)
  (do ((seen (let ((seen (js-object)))
               (setf (aref seen (funcall key start)) (list "*start*" null))
               seen))
       (active (list start))
       (solution null))
      ((or solution
           (zerop (length active)))
         solution)
    (let ((next-active (list)))
      (dolist (state active)
        (if (funcall goal state)
            (progn
              (setf solution (list))
              (do ((x (list "*goal*" state)))
                  ((nullp (second x))
                     (nreverse solution))
                (push x solution)
                (setf x (aref seen (funcall key (second x))))))
            (dolist (action actions)
              (let ((result (funcall action state)))
                (when (and result
                           (undefinedp (aref seen (funcall key (second result)))))
                  (setf (aref seen (funcall key (second result)))
                        (list (first result) state))
                  (push (second result) next-active))))))
      (setf active next-active))))

(let ((x (gps '(space-on-a
                a-on-c
                c-on-b
                b-on-table)
              (build-block-actions '(a b c))
              (lambda (s) (subset '(c-on-b b-on-a) s))
              (lambda (s) (+ (sort s) "")))))
  (if x
      (dolist (y x)
        (display (str-value y)))
      (display "** NO SOLUTION **")))