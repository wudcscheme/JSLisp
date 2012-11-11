(import * from gui)
(import * from layout)
(import * from editor)
(import (mode) from editor-lispmode)
(import ilisp)
(import * from rpc-client)
(import (hash) from crypto)

(defvar *ilisp*)

(defun src-tab (name content)
  (let ((editor (editor name content mode)))
    (set-style editor
               position "absolute")
    (setf editor.ilisp-exec
          (lambda ()
            (let ((lines (editor.lines))
                  ((row col s-row s-col) (editor.pos)))
              (declare (ignorable s-row s-col))
              (let ((m (mode.parmatch lines row col)))
                (when m
                  (let (((row0 col0) m)
                        (txt ""))
                    (if (= row row0)
                        (incf txt (slice (aref lines row).text col0 (- col col0)))
                        (progn
                          (incf txt (+ (slice (aref lines row0).text col0) "\n"))
                          (dolist (r (range (1+ row0) row))
                            (incf txt (+ (aref lines r).text "\n")))
                          (incf txt (slice (aref lines row).text 0 col))))
                    (*ilisp*.send "lisp" txt)))))))
    editor))

(defun inferior-lisp ()
  (let** ((container (set-style (create-element "div")
                                position "absolute"))
          (inspect (append-child container (button "Inspect" #'inspect)))
          (reset (append-child container (button "Reset" #'reset)))
          (clear (append-child container (button "Clear" #'clear)))
          (ilisp (ilisp:new #'reply))
          (#'inspect ()
                     (mode.inspect-ilisp ilisp))
          (#'reply (msg)
                   (when (= msg "\"ready\"")
                     (inspect))
                   (ilisp.send "javascript"
                               (+ "output(f$$str_value(f$$json_parse$42_("
                                  (json msg)
                                  "))+\"\\n\")")))
          (#'reset ()
                   (ilisp.reset))
          (#'clear ()
                   (ilisp.send "javascript"
                               "repl.value=\"\""))
          (layout (V border: 8 spacing: 8
                     (dom ilisp.iframe)
                     size: 30
                     (H :filler:
                        size: 80
                        (dom reset)
                        (dom clear)
                        (dom inspect)
                        :filler:))))
    (append-child container ilisp.iframe)
    (set-style ilisp.iframe
               position "absolute"
               border "solid 1px #CCCCCC"
               px/padding 0
               px/margin -1
               opacity 1)
    (setf container."data-resize"
          (lambda (x0 y0 x1 y1)
            (set-coords layout 0 0 (- x1 x0) (- y1 y0))))
    (setf container.ilisp ilisp)
    container))

(defvar *user*)
(defvar *secret*)
(defvar *session-id*)

(rpc:defun remote (user-name session-id x authcode))
(rpc:defun login (user-name))

(defun call-remote (x)
  (remote *user* *session-id* x
          (hash (+ *session-id* *secret* (json* x)))))

(defun get-file (name)
  (call-remote `(get-file ,name)))

(defun files (path)
  (call-remote `((node:require "fs").readdirSync ,path)))

(defun file-browser (cback)
  (let** ((w (set-style (create-element "div")
                        position "absolute"))
          (user (append-child w (input "username")))
          (password (append-child w (input "password")))
          (current-path (append-child w (input "current path")))
          (files (append-child w (set-style (create-element "div")
                                            position "absolute"
                                            border  "solid 1px #000000"
                                            overflow "auto"
                                            px/margin -2
                                            px/padding 2)))
          (last-search null)
          (filelist (list))
          (#'pathexp (s)
            (let* ((last-sep (last-index "/" s))
                   (base (if (= last-sep -1) "./" (slice s 0 last-sep)))
                   (name (slice s (1+ last-sep))))
              (list base name)))
          (#'filter ()
            (when (/= last-search (text current-path))
              (setf last-search (text current-path))
              (let (((base name) (pathexp last-search)))
                (setf files.textContent "")
                (setf filelist (list))
                (dolist (f (or (files base) ""))
                  (when (and (/= (last f) "~")
                             (= (slice f 0 (length name)) name))
                    (push f filelist)
                    (let ((d (append-child files (set-style (create-element "div")
                                                            px/fontSize 18
                                                            fontFamily "monospace"
                                                            whiteSpace "pre"
                                                            px/padding 2))))
                      (setf d.textContent f)))))))
          (#'enter ()
            (funcall cback (text current-path)))
          (layout (V border: 8 spacing: 8
                     size: 40
                     (H size: 120
                        (dom user)
                        (dom password)
                        size: undefined
                        (dom current-path))
                     size: undefined
                     (dom files))))
    (setf current-path.onkeydown
          (lambda (event)
            (when (= event.which 13)
              (event.stopPropagation)
              (event.preventDefault)
              (enter))))
    (setf password.lastChild.type "password")
    (setf password.lastChild.onblur (lambda ()
                                      (setf *user* (text user))
                                      (setf *secret* (hash (text password)))
                                      (setf *session-id* (login *user*))))
    (set-interval #'filter 250)
    (set-interval (lambda () (call-remote 42)) 5000) ;; keep-alive
    (setf w."data-resize" (lambda (x0 y0 x1 y1)
                            (set-coords layout 0 0 (- x1 x0) (- y1 y0))))
    (setf w.focus (lambda ()
                    ((cond
                       ((= (text user) "") user)
                       ((= (text password) "") password)
                       (true current-path)).lastChild.focus)))
    w))

(defun main ()
  (let** ((w (window 0 0 0.95 0.95 title: "JsLisp IDE"))
          (sources (tabbed))
          (ilisp (inferior-lisp))
          (doc (set-style (create-element "div")
                          position "absolute"
                          overflow "auto"))
          (hs (set-style (h-splitter ilisp doc)
                         position "absolute"))
          (vs (add-widget w (v-splitter sources hs split: 70)))
          (zoom false)
          (#'show-doc (x)
            (setf x (json-parse x))
            (when (and x (string? (first x)))
              (setf x (first x))
              (setf x (replace x "&" "&amp;"))
              (setf x (replace x "<" "&lt;"))
              (setf x (replace x ">" "&gt;"))
              (setf x (replace x "\"" "&quot;"))
              (setf x (replace x "\\n" "<br/>"))
              (setf x (replace x "\\[\\[((.|[\\n])*?)\\]\\]"
                               "<pre style=\"color:#008;\
                                 font-weight:bold;\
                                 font-size:110%\">$1</pre>"))
              (setf x (replace x "\\[(.*?)\\]"
                               "<span style=\"font-weight:bold;\
                                 font-family:monospace;\
                                 color:#008\">$1</span>"))
              (setf x (replace x "{{(.*?)}}"
                               "<a href=\"javascript:showdoc('$1')\">\
                                 <span style=\"font-weight:bold;\
                                 text-decoration:underline;\
                                 font-family:monospace;\
                                 color:#00F\">$1</span></a>"))
              (setf doc.innerHTML x)))
          (#'doc-lookup (name)
            (*ilisp*.send
             "lisp"
             ~"(let ((f (intern {(json name)} undefined true)))
                 (if (and f (or (symbol-function f) (symbol-macro f)))
                   (documentation (or (symbol-function f) (symbol-macro f)))))"
             #'show-doc)))

    (setf (js-code "window").showdoc #'doc-lookup)
    (setf *ilisp* ilisp.ilisp)

    (sources.add "<unnamed-1>.lisp" (src-tab "<unnamed-1>.lisp" ""))
    (sources.add "+" (file-browser (lambda (f)
                                     (sources.add f (src-tab f (or (get-file f) ""))))))

    (document.body.addEventListener
     "keydown"
     (lambda (event)
       (let ((stop true))
         (cond
           ((and event.ctrlKey (= event.which 75))
            (setf zoom (not zoom))
            (setf sources.style.opacity (if zoom 0 1))
            (setf doc.style.opacity (if zoom 0 1))
            (vs.partition (if zoom 1 70))
            (hs.partition (if zoom 99 50)))
           ((and event.ctrlKey (= event.which 39))
            (sources.next)
            ((sources.current).focus))
           ((and event.ctrlKey (= event.which 37))
            (sources.prev)
            ((sources.current).focus))
           ((and event.ctrlKey (= event.which 13))
            ((sources.current).ilisp-exec))
           ((and event.ctrlKey (= event.which 73))
            (mode.inspect-ilisp *ilisp*))
           (true (setf stop false)))
         (when stop
           (event.stopPropagation)
           (event.preventDefault))))
     true)

    (set-interval
     (let ((last-lookup ""))
       (lambda ()
         (when (and (sources.current) (sources.current).pos)
           (let* (((row col) ((sources.current).pos))
                  (lines ((sources.current).lines))
                  (text (aref lines row).text))
             (do ((c col (1- c)))
                 ((or (= c 0)
                      (= (aref text (1- c)) "("))
                    (let ((name (slice text c col)))
                      (when (/= name last-lookup)
                        (setf last-lookup name)
                        (doc-lookup name)))))))))
     100)

    (set-layout w (V border: 8 spacing: 8
                     (dom vs)))
    (show-window w center: true)))

(main)