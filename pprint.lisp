(defvar *print-width* 70)

(defun pprint (obj)
  "Tries to format reasonably an object that contains JsLisp source code.
   This function is useful mostly for displaying the result of macro \
   expansion. See {{macroexpand-1}}[[
   (pprint '(labels((fact(x)(if(< x 2)1(*
            x(fact(1- x))))))(fact 10)))
   ;; produces as output
   (labels ((fact (x)
              (if (< x 2)
                  1
                  (* x (fact (1- x))))))
     (fact 10))
   ]]"
  (let ((result "")
        (col 0)
        (row 0)
        (indent (list)))
    (labels ((newline ()
               (incf result "\n")
               (dotimes (i (last indent))
                 (incf result " "))
               (incf row)
               (setf col (last indent)))
             (output (str)
               (when (and (= (first str) "\n")
                          (> (length str) 1))
                 (newline)
                 (setf str (slice str 1)))
               (case str
                 ("\n"
                    (newline))
                 ("("
                    (incf result str)
                    (incf col)
                    (push col indent))
                 (")"
                    (incf result str)
                    (incf col)
                    (pop indent))
                 (otherwise
                    (when (and (> col (last indent))
                               (> (+ col (length str)) *print-width*))
                      (newline))
                    (incf result str)
                    (incf col (length str)))))
             (sep (ppx px x i)
               (cond
                 ((and (list? (first x))
                       (/= '\. (first (first x)))) "\n")
                 ((= (first x) 'progn) "\n ")
                 ((= (first x) 'with-canvas) (if (>= i 1) "\n " " "))
                 ((= (first x) 'do) (cond
                                      ((= i 0) " ")
                                      ((= i 1) "\n   ")
                                      (true "\n ")))
                 ((= (first x) 'cond) "\n ")
                 ((= (first x) 'labels) (if (>= i 1) "\n " " "))
                 ((= (first x) 'macrolet) (if (>= i 1) "\n " " "))
                 ((= (first x) 'case) (if (>= i 1) "\n " " "))
                 ((= (first x) 'and) (if (>= i 1) "\n    " " "))
                 ((= (first x) 'or) (if (>= i 1) "\n   " " "))
                 ((= (first x) 'enumerate) (if (>= i 1) "\n " " "))
                 ((= (first x) 'dotimes) (if (>= i 1) "\n " " "))
                 ((= (first x) 'dolist) (if (>= i 1) "\n " " "))
                 ((= (first x) 'set-handler) (if (>= i 2) "\n " " "))
                 ((= (first x) 'set-style) (if (% i 2) "\n          " " "))
                 ((= (first x) 'defun) (if (>= i 2) "\n " " "))
                 ((= (first x) 'defmethod) (if (>= i 3) "\n " " "))
                 ((and (= (first x) 'setf)
                       (= i 1)
                       (list? (aref x 2))
                       (= (first (aref x 2)) 'lambda)) "\n     ")
                 ((= (first x) 'lambda) (if (>= i 1) "\n " " "))
                 ((= (first x) 'defmacro) (if (>= i 2) "\n " " "))
                 ((= (first x) 'if) (if (>= i 1) "\n   " " "))
                 ((= (first x) 'let) (if (>= i 1) "\n " " "))
                 ((= (first x) 'let*) (if (>= i 1) "\n " " "))
                 ((= (first x) 'let**) (if (>= i 1) "\n " " "))
                 ((= (first x) 'with-window) (if (>= i 1) "\n " " "))
                 ((and (= (first px) 'with-window)
                       (= (index x px) 1))
                  (if (>= i 1) "\n  " " "))
                 ((= (first px) 'cond) "\n")
                 ((= (first px) 'case) "\n")
                 ((= (first ppx) 'labels) (if (>= i 1) "\n " " "))
                 ((= (first ppx) 'macrolet) (if (>= i 1) "\n " " "))
                 ((= (first x) 'when) (if (>= i 1) "\n " " "))
                 ((= (first x) 'unless) (if (>= i 1) "\n " " "))
                 (true " ")))
             (dumplist (ppx px x)
               (enumerate (j y x)
                 (dump px x y)
                 (when (< j (1- (length x)))
                   (output (sep ppx px x j)))))
             (dump (ppx px x)
               (cond
                 ((list? x)
                  (cond
                    ((and (= (first x) '\.) (= (length x) 3) (symbol? (third x)))
                     (dump px x (second x))
                     (output ~".{(symbol-name (third x))}"))
                    ((and (= (first x) '\`) (= (length x) 2))
                     (output "`")
                     (dump px x (second x)))
                    ((and (= (first x) '\,) (= (length x) 2))
                     (output ",")
                     (dump px x (second x)))
                    ((and (= (first x) '\,@) (= (length x) 2))
                     (output ",@")
                     (dump px x (second x)))
                    ((and (= (first x) 'quote) (= (length x) 2))
                     (output "'")
                     (dump px x (second x)))
                    ((and (= (first x) 'function) (= (length x) 2))
                     (output "#'")
                     (dump px x (second x)))
                    (true
                     (output "(")
                     (dumplist ppx px x)
                     (output ")"))))
                 ((symbol? x)
                  (output (symbol-name x)))
                 (true
                  (output (json x))))
               (when (and (list? x)
                          (find (first x) '(defun defmacro defmethod defvar)))
                 (newline))))
      (dump (list) (list) obj)
      (display result)
      null)))

(export pprint *print-width*)
