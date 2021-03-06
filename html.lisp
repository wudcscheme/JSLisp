(setf (hash-reader "#")
      (lambda (src)
        (next-char src)
        `(document.getElementById
           ,(if (or (<= "a" (current-char src) "z")
                    (<= "a" (current-char src) "z"))
                (symbol-name (parse-symbol src))
                (read src)))))

(defmacro set-style (element &rest properties)
  "Allows settings multiple style properties for a DOM node, example:[[
     (set-style mynode
                position \"absolute\"
                px/left 0
                px/top  0
                px/width 200
                px/height 300)
]]
  The [px/] prefix means a CSS unit that will be appended to the expression."
  (let ((el '#.(gensym))
        (elstyle '#.(gensym)))
    `(let* ((,el ,element)
            (,elstyle (. ,el style)))
       ,@(map (lambda (i)
                (let* ((prop (aref properties i))
                       (value (aref properties (1+ i)))
                       (pname (symbol-name prop))
                       (um (index "/" pname)))
                  (if (= um -1)
                      `(setf (. ,elstyle ,prop) ,value)
                      `(setf (. ,elstyle ,(intern (slice pname (1+ um))))
                             (+ ,value ,(slice pname 0 um))))))
              (range 0 (length properties) 2))
       ,el)))

(setf (hash-reader ">")
      (lambda (src)
        (next-char src)
        (let ((stopmark "")
              (text ""))
          (do ((c (current-char src) (current-char src)))
            ((or (undefined? c) (= c "\n"))
             (when c
               (incf stopmark c)
               (next-char src)))
            (incf stopmark c)
            (next-char src))
          (do ((c (current-char src) (current-char src)))
            ((or (undefined? c)
                 (= (slice text (- (length stopmark))) stopmark))
             (slice text 0 (- (length stopmark))))
            (incf text c)
            (next-char src)))))

(defvar *css* #())

(defun scss (tag tx)
  (unless (aref *css* tag)
    (setf (aref *css* tag)
          (append-child document.head
                        (document.createElement "style")))
    (setf (aref *css* tag).type "text/css"))
  (setf (aref *css* tag).textContent (+ tag tx)))

(defmacro css (tag &rest attributes)
  (unless (and (even? (length attributes))
               (all (i (range 0 (length attributes) 2))
                 (keyword? (aref attributes i))))
    (error "syntax is (css <tag> <attr1>: <value1> ...)"))
  (let ((tx (list '+ "{"))
        (sep ""))
    (dolist (i (range 0 (length attributes) 2))
      (push (+ sep (slice (symbol-name (aref attributes i)) 0 -1) ":") tx)
      (push (aref attributes (1+ i)) tx)
      (setf sep ";"))
    (push (+ sep "}") tx)
    `(scss ,tag ,tx)))

(defun class (x)
  (x.className))

(defun set-class (x y)
  (setf x.className y))

(defun class-add (x &rest classes)
  (dolist (c classes)
    (x.classList.add c)))

(defun class-remove (x &rest classes)
  (dolist (c classes)
    (x.classList.remove c)))

(defmacro on (element event &rest body)
  `((. ,element addEventListener) ,(symbol-name event)
    (lambda (event)
      (declare (ignorable event))
      ,@body)))

(defmacro template (x)
  (do ((content (if node-js (get-file x) (http-get x)))
       (i 0)
       (c '#.(gensym))
       (code (list)))
    ((>= i (length content))
     (if (= (length code) 0)
         ""
         `(let ((,c ""))
            ,@code
            ,c)))
    (let ((j (index "{{" content i)))
      (if (= j -1)
          (progn
            (push `(incf ,c ,(slice content i)) code)
            (setf i (length content)))
          (let ((k (index "}}" content j)))
            (push `(incf ,c ,(slice content i j)) code)
            (when (= k -1)
              (error "Invalid template content"))
            (push `(incf ,c ,(read (+ "(progn "
                                      (slice content (+ j 2) k)
                                      ")"))) code)
            (setf i (+ k 2)))))))

(defmacro base-css (name)
  `(let ((css (append-child document.head (create-element "style"))))
     (setf css.type "text/css")
     (setf css.textContent (template ,name))))

(defmacro main-view (name)
  `(let ((main (append-child document.body (create-element "div"))))
     (setf main.innerHTML (template ,name))))

(defvar cached-subviews #())

(defmacro set-view (tag name)
  (let ((tt '#.(gensym)))
    `(progn
       (unless (aref cached-subviews ,name)
         (let ((,tt (create-element "div")))
           (setf (. ,tt innerHTML) (template ,name))
           (setf (aref cached-subviews ,name) (map (lambda (x) x) (. ,tt children)))))
       (let ((,tt ,tag))
         (setf (. ,tt innerHTML) "")
         (dolist (x (aref cached-subviews ,name))
           (append-child ,tt x))))))

(defun focus (x)
  (set-timeout (lambda () (x.focus)) 10))

(defun hide (x)
  (set-style x display "none"))

(defun show (x &key text html delay)
  (set-style x display "inherit")
  (unless (undefined? html)
    (setf x.innerHTML html))
  (unless (undefined? text)
    (setf x.textContent text))
  (unless (undefined? delay)
    (set-timeout (lambda () (hide x)) delay)))

(defvar *code-snippet-id* -1)
(if node-js
    (incf *deploy-prefix* "csnip=[];"))

(defmacro code (&rest body)
  (incf *code-snippet-id*)
  `(progn
     (setf (js-code ,(+ "csnip[" *code-snippet-id* "]"))
           (lambda () ,@body))
     ,~"\"csnip[{*code-snippet-id*}]()\""))

(defmacro button (text &rest body)
  `(+ "<input type=button value="
      ,(json text)
      " onclick="
      (code ,@body) ">"))

(export css set-style class set-class class-add class-remove on template
        base-css main-view set-view focus show hide button code)