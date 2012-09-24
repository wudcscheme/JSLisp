(import * from gui)
(import * from layout)

(setf *font* "\"Droid Sans Mono\",\"Courier New\",\"Courier\",monospace")
(setf *fontsz* 18)
(setf *line* 20)

(defun font (ctx opts)
  (let ((font ""))
    (when opts.bold
      (incf font " bold"))
    (when opts.italic
      (incf font " italic"))
    (setf ctx.fillStyle (or opts.color "#000000"))
    (setf ctx.font ~"{(slice font 1)} {*fontsz*}px {*font*}")))

(defobject line
    (text
     start-signature
     end-signature
     sel-x0 sel-x1
     (start-context #())
     (end-context #())
     (sections (list))))

(defobject section (from to style))

(defun signature (d)
  (+ "{"
     (join (map (lambda (k)
                  ~"{k}:{(json (aref d k))}")
                (sort (keys d)))
           ",")
     "}"))

(defun parmatch (lines row col)
  (let** ((r 0)
          (c -1)
          (last null)
          (current null)
          (#'next ()
                  (setf last current)
                  (when (> (incf c) (length (aref lines r).text))
                    (setf c 0) (incf r))
                  (setf current
                        (if (or (> r row)
                                (and (= r row) (>= c col)))
                            undefined
                            (or (aref lines r "text" c) "\n"))))
          (close (aref lines row "text" (1- col)))
          (open (aref "{[(" (index close "}])")))
          (stack (list)))
    (next)
    (do ()
        ((or (undefined? current)
             (or (> r row)
                 (and (= r row) (>= c (1- col)))))
           (last stack))
      (cond
        ((= current "\"")
         (next)
         (do ()
             ((or (undefined? current)
                  (= current "\n")
                  (= current "\""))
                (when (undefined? current)
                  (return-from parmatch null))
                (next))
           (when (= current "\\")
             (next))
           (next)))
        ((and (= current "/") (= last "/"))
         (do ()
             ((or (undefined? current)
                  (= current "\n")))
           (next))
         (when (undefined? current)
           (return-from parmatch null)))
        ((and (= current "*") (= last "/"))
         (next)
         (do ()
             ((or (undefined? current)
                  (and (= current "/") (= last "*")))
                (next))
           (next))
         (when (undefined? current)
           (return-from parmatch null)))
        ((= current open)
         (push (list r c) stack)
         (next))
        ((= current close)
         (pop stack)
         (next))
        (true (next))))))

(defun compute-end-context (line)
  (do ((ec (copy line.start-context))
       (text (rstrip line.text))
       (i 0)
       (sections (list)))
      ((>= i (length text))
         (unless (= (last text) "\\")
           (setf ec.preproc false))
         (when (> (length line.text) (length text))
           (push (new-section (length text) (length line.text)
                              #((background-color "#C0FFC0")))
                 sections))
         (setf line.sections sections)
         ec)
    (cond
      (ec.mlcomment
       (let ((i0 i))
         (do () ((or (= i (length text))
                     (= (slice text i (+ i 2)) "*/")))
           (incf i))
         (when (= (slice text i (+ i 2)) "*/")
           (setf ec.mlcomment false)
           (incf i 2))
         (push (new-section i0 i #((color "#888888"))) sections)))
      (ec.preproc
       (push (new-section i (length text) #((color "#880088"))) sections)
       (setf i (length text)))
      ((= (slice text i (+ i 2)) "/*")
       (setf ec.mlcomment true))
      ((= (aref text i) "#")
       (setf ec.preproc true))
      ((or (and (= (aref text i) ".") (<= "0" (aref text (1+ i)) "9"))
           (<= "0" (aref text i) "9"))
       (let ((i0 i))
         (if (find (slice text i (+ i 2)) '("0x" "0X"))
             (progn
               (incf i 2)
               (do () ((or (= i (length text))
                           (not (find (aref text i) "0123456789abcdefABCDEF")))
                         (push (new-section i0 i #((color "#884400"))) sections))
                 (incf i)))
             (progn
               (do () ((or (= i (length text))
                           (< (aref text i) "0")
                           (> (aref text i) "9")))
                 (incf i))
               (when (= (aref text i) ".")
                 (incf i)
                 (do () ((or (= i (length text))
                             (< (aref text i) "0")
                             (> (aref text i) "9")))
                   (incf i)))
               (when (find (aref text i) "eE")
                 (incf i)
                 (when (find (aref text i) "+-")
                   (incf i))
                 (do () ((or (= i (length text))
                             (< (aref text i) "0")
                             (> (aref text i) "9")))
                   (incf i)))
               (push (new-section i0 i #((color "#FF4444"))) sections)))))
      ((= (aref text i) "\"")
       (let ((i0 i))
         (incf i)
         (do () ((or (>= i (length text))
                     (= (aref text i) "\""))
                   (when (< i (length text))
                     (incf i))
                   (push (new-section i0 i #((color "#008800"))) sections))
           (if (= (aref text i) "\\")
               (incf i 2)
               (incf i)))))
      ((= (slice text i (+ i 2)) "//")
       (push (new-section i (length text) #((color "#888888"))) sections)
       (setf i (length text)))
      (((regexp "[_a-zA-Z]").exec (aref text i))
       (let ((i0 i))
         (do ()
             ((or (= i (length text))
                  (not ((regexp "[_a-zA-Z0-9]").exec (aref text i))))
                (when (find (slice text i0 i)
                            '("if" "else" "do" "switch" "goto"
                              "while" "for" "return" "break" "case"
                              "struct" "union" "typedef"
                              "void" "int" "double" "char" "const"
                              "float" "unsigned"
                              "extern" "static" "inline"))
                  (push (new-section i0 i #((bold true)
                                            (color "#0000CC")))
                        sections)))
           (incf i))))
      (true
       (incf i)))))

(defun autoindent (lines row)
  (when (> row 0)
    (let ((line (aref lines (1- row)))
          (newline (aref lines row)))
      (let ((indent (length (first ((regexp "^ *").exec line.text)))))
        (when (> indent 0)
          (setf newline.text
                (+ (slice line.text 0 indent)
                   newline.text)))
        indent))))

(defun fix-for-selection (sections x0 x1)
  (let ((new-sections (list)))
    (dolist (s sections)
      (let ((xa (max x0 s.from))
            (xb (min x1 s.to)))
        (if (< xa xb)
            (progn
              (when (> xa s.from)
                (push (new-section s.from xa s.style) new-sections))
              (when (< xb s.to)
                (push (new-section xb s.to s.style) new-sections))
              (push (new-section xa xb
                                 (let ((ss (copy s.style)))
                                   (setf ss.background-color "#FFFF00")
                                   ss))
                    new-sections))
            (push s new-sections))))
    (let ((ss #((background-color "#FFFF00"))))
      (if (= (length sections) 0)
          (push (new-section x0 x1 ss)
                new-sections)
          (progn
            (when (< x0 (first sections).from)
              (push (new-section x0 (min x1 (first sections).from) ss)
                    new-sections))
            (when (> x1 (last sections).to)
              (push (new-section (max x0 (last sections).to) x1 ss)
                    new-sections))
            (dotimes (i (1- (length sections)))
              (let ((s0 (aref sections i))
                    (s1 (aref sections (1+ i))))
                (when (< s0.to s1.from)
                  (let ((xa (max s0.to x0))
                        (xb (min s1.from x1)))
                    (when (< xa xb)
                      (push (new-section xa xb ss) new-sections)))))))))
    (sort new-sections
          (lambda (a b) (< a.from b.from)))))

(defun draw-line (text sections h w
                  ctx x y tx endsel)
  (let ((xx 0))
    (dolist (s sections)
      (when (> s.from xx)
        (let ((part (slice text xx s.from)))
          (font ctx #())
          (ctx.fillText part (+ tx x) y)
          (incf x (ctx.measureText part).width)
          (setf xx s.from)))
      (when (< (+ tx x) w)
        (let ((part (slice text s.from s.to)))
          (font ctx s.style)
          (let ((pw (ctx.measureText part).width))
            (when s.style.background-color
              (setf ctx.fillStyle s.style.background-color)
              (ctx.fillRect (+ tx x) y pw h))
            (setf ctx.fillStyle (or s.style.color "#000000"))
            (ctx.fillText part (+ tx x) y)
            (incf x pw)
            (setf xx s.to)))))
    (when (< (+ tx x) w)
      (when (> (length text) xx)
        (let ((part (slice text xx)))
          (font ctx #())
          (ctx.fillText part (+ tx x) y)
          (incf x (ctx.measureText part).width)))
      (when endsel
        (setf ctx.fillStyle "#FFFF00")
        (ctx.fillRect (+ tx x) y (- w x tx) h)))))

(defun ifind (text lines row col)
  (let ((lt (if (= text (lowercase text)) #'lowercase (lambda (x) x))))
    (dolist (r (range row (length lines)))
      (let ((i (index text (funcall lt (slice (aref lines r).text col)))))
        (when (>= i 0)
          (return-from ifind (list r (+ i col)))))
      (setf col 0))))

(defun editor (content)
  (macrolet ((mutate (redo undo)
               `(progn
                  (push (list (lambda () ,undo) (lambda () ,redo)) undo)
                  (setf redo (list))
                  (setf lastins undefined)
                  (funcall (second (last undo))))))
    (let** ((screen (create-element "canvas"))
            (lines (list))
            (cw null)
            (ch *line*)
            (last-width null)
            (last-height null)
            (top 0)
            (left 0)
            (row 0)
            (col 0)
            (s-row 0)
            (s-col 0)
            (ifind-mode false)
            (ifind-text "")
            (ifind-last-text "")
            (ifind-row 0)
            (ifind-col 0)
            (ifind-left 0)
            (ifind-top 0)
            (hinput (create-element "textarea"))
            (undo (list))
            (redo (list))
            (lastins undefined)
            (#'touch (line)
                     (setf line.start-signature null))
            (#'update ()
                      (setf screen.width screen.offsetWidth)
                      (setf screen.height screen.offsetHeight)
                      (let ((cr top)
                            (ctx (screen.getContext "2d")))
                        (when (null? cw)
                          (font ctx #())
                          (setf cw (/ (ctx.measureText "XXXXXXXXXX").width 10)))
                        (setf ctx.fillStyle (if ifind-mode
                                                "#DDFFFF"
                                                "#FFFFFF"))
                        (ctx.fillRect 0 0 screen.width screen.height)
                        (setf ctx.textBaseline "top")
                        (do () ((or (>= cr (length lines))
                                    (>= (* (- cr top) ch) screen.offsetHeight))
                                  (when (and (> col 0)
                                             (find (aref lines row "text" (1- col))
                                                   "})]"))
                                    (let ((m (parmatch lines row col)))
                                      (when (and m
                                                 (>= (first m) top))
                                        (let ((y0 (* (- (first m) top) *line*))
                                              (x0 (* (- (second m) left) cw))
                                              (y1 (* (- row top) *line*))
                                              (x1 (* (- col left 1) cw)))
                                          (setf ctx.fillStyle "rgba(255,0,0,0.25)")
                                          (ctx.fillRect x0 y0 (+ cw 2) (+ *line* 2))
                                          (ctx.fillRect x1 y1 (+ cw 2) (+ *line* 2)))))))
                          (let ((current-signature (if (= cr 0)
                                                       ""
                                                       (aref lines (1- cr)).end-signature))
                                (x0 0)
                                (x1 0)
                                (line (aref lines cr)))
                            (when (and (or (/= col s-col)
                                           (/= row s-row))
                                       (or (<= row cr s-row)
                                           (<= s-row cr row)))
                              (cond
                                ((= row s-row)
                                 (setf x0 (min col s-col))
                                 (setf x1 (max col s-col)))
                                ((= cr (min row s-row))
                                 (setf x0 (if (= cr row) col s-col))
                                 (setf x1 (1+ (length line.text))))
                                ((= cr (max row s-row))
                                 (setf x0 0)
                                 (setf x1 (if (= cr row) col s-col)))
                                (true
                                 (setf x0 0)
                                 (setf x1 (1+ (length line.text))))))
                            (unless (and (= x0 line.sel-x0)
                                         (= x1 line.sel-x1)
                                         (= current-signature line.start-signature))
                              (setf line.start-context
                                    (if (= cr 0)
                                        #()
                                        (aref lines (1- cr)).end-context))
                              (let ((ec (compute-end-context line))
                                    (text line.text))
                                (when (< x0 x1)
                                  (setf line.sections
                                        (fix-for-selection line.sections x0 x1)))
                                (setf line.end-context ec)
                                (setf line.sel-x0 x0)
                                (setf line.sel-x1 x1)
                                (setf line.start-signature current-signature)
                                (setf line.end-signature (signature line.end-context))))
                            (draw-line line.text line.sections
                                       ch screen.offsetWidth
                                       ctx 0 (* (- cr top) ch) (- (* cw left))
                                       (> x1 (length line.text)))
                            (when (= cr row)
                              (setf ctx.fillStyle "#FF0000")
                              (ctx.fillRect (* cw (- col left)) (* ch (- cr top))
                                            2 *line*))
                            (incf cr)))))
            (#'fix ()
                   (let ((screen-lines (floor (/ screen.offsetHeight ch)))
                         (screen-cols (floor (/ screen.offsetWidth cw))))
                     (setf row (max 0 (min (1- (length lines)) row)))
                     (setf col (max 0 (min (length (aref lines row).text) col)))
                     (setf s-row (max 0 (min (1- (length lines)) s-row)))
                     (setf s-col (max 0 (min (length (aref lines s-row).text) s-col)))
                     (setf left (max 0 (- col screen-cols) (min left col)))
                     (setf top (max 0 (- row -1 screen-lines) (min row top (- (length lines) screen-lines)))))
                   (update))
            (#'selection-to-hinput ()
                                   (let ((txt ""))
                                     (if (= row s-row)
                                         (setf txt (slice (aref lines row).text
                                                          (min col s-col)
                                                          (max col s-col)))
                                         (let ((r0 (min row s-row))
                                               (r1 (max row s-row))
                                               (c0 (if (< row s-row) col s-col))
                                               (c1 (if (< row s-row) s-col col)))
                                           (setf txt (+ (slice (aref lines r0).text c0) "\n"))
                                           (dotimes (i (- r1 r0 1))
                                             (incf txt (+ (aref lines (+ r0 i 1)).text "\n")))
                                           (incf txt (slice (aref lines r1).text 0 c1))))
                                     (setf hinput.value txt)
                                     (hinput.setSelectionRange 0 (length txt))))
            (#'paste ()
                     (let ((pasted-lines (split (replace hinput.value "\r" "") "\n")))
                       (when (or (/= col s-col) (/= row s-row))
                         (delete-selection))
                       (let ((r row)
                             (c col)
                             (r1 null)
                             (c1 null))
                         (mutate
                          (let ((line (aref lines r)))
                            (if (= (length pasted-lines) 1)
                                (progn
                                  (setf line.text
                                        (+ (slice line.text 0 c)
                                           (aref pasted-lines 0)
                                           (slice line.text c)))
                                  (setf col (+ c (length (aref pasted-lines 0))))
                                  (setf row r)
                                  (touch line))
                                (let ((tail (slice line.text c)))
                                  (setf line.text
                                        (+ (slice line.text 0 c)
                                           (aref pasted-lines 0)))
                                  (touch line)
                                  (dotimes (i (- (length pasted-lines) 2))
                                    (let ((newline (new-line (aref pasted-lines (1+ i)))))
                                      (incf r)
                                      (insert lines r newline)))
                                  (let ((newline (new-line (+ (last pasted-lines) tail))))
                                    (incf r)
                                    (insert lines r newline)
                                    (setf row r)
                                    (setf col (length (last pasted-lines))))))
                            (setf s-col col)
                            (setf s-row row)
                            (setf r1 row)
                            (setf c1 col))
                          (let ((line (aref lines r)))
                            (setf line.text
                                  (+ (slice line.text 0 c)
                                     (slice (aref lines r1).text c1)))
                            (when (> r1 r)
                              (splice lines (1+ r) (- r1 r)))
                            (touch line)
                            (setf row r)
                            (setf col c)
                            (setf s-row r)
                            (setf s-col c)))))
                     (fix))
            (#'change-line (r c text)
                           (let ((oldtext (aref lines r).text)
                                 (oldr row)
                                 (oldc col)
                                 (oldsr s-row)
                                 (oldsc s-col)
                                 (l-undo (if (= lastins r)
                                             (first (pop undo)))))
                             (mutate
                              (progn
                                (setf (aref lines r).text text)
                                (setf row r)
                                (setf col c)
                                (setf s-row row)
                                (setf s-col col)
                                (touch (aref lines r)))
                              (progn
                                (setf (aref lines r).text oldtext)
                                (setf row oldr)
                                (setf col oldc)
                                (setf s-row oldsr)
                                (setf s-col oldsc)
                                (touch (aref lines r))))
                             (when l-undo
                               (setf (first (last undo)) l-undo))
                             (setf lastins r)))
            (#'delete-selection ()
                                (if (= row s-row)
                                    (let ((text (aref lines row).text)
                                          (r row)
                                          (cc col)
                                          (sc s-col))
                                      (mutate
                                       (progn
                                         (setf (aref lines r).text
                                               (+ (slice text 0 (min cc sc))
                                                  (slice text (max cc sc))))
                                         (setf row r)
                                         (setf col (min cc sc))
                                         (setf s-col col)
                                         (touch (aref lines r)))
                                       (progn
                                         (setf (aref lines r).text text)
                                         (setf row r)
                                         (setf col cc)
                                         (setf s-col sc)
                                         (touch (aref lines r)))))
                                    (let ((changed-lines null)
                                          (org-r0 null)
                                          (rr row)
                                          (cc col)
                                          (sr s-row)
                                          (sc s-col)
                                          (r0 (min row s-row))
                                          (r1 (max row s-row))
                                          (c0 (if (< row s-row) col s-col))
                                          (c1 (if (< row s-row) s-col col)))
                                      (mutate
                                       (progn
                                         ;; Move lines to var for undo
                                         (setf changed-lines
                                               (slice lines (1+ r0) (1+ r1)))
                                         (setf org-r0 (aref lines r0).text)
                                         ;; Delete the lines
                                         (setf (aref lines r0).text
                                               (+ (slice (aref lines r0).text 0 c0)
                                                  (slice (aref lines r1).text c1)))
                                         (splice lines (1+ r0) (- r1 r0))
                                         (setf row r0)
                                         (setf col c0)
                                         (setf s-row row)
                                         (setf s-col col)
                                         (touch (aref lines row)))
                                       (progn
                                         ;; Recover
                                         (setf (aref lines r0).text org-r0)
                                         (setf lines (append (slice lines 0 (1+ r0))
                                                             changed-lines
                                                             (slice lines (1+ r0))))
                                         (setf changed-lines null)
                                         (setf row rr)
                                         (setf col cc)
                                         (setf s-row sr)
                                         (setf s-col sc)
                                         (dolist (r (range r0 (1+ r1)))
                                           (touch (aref lines r))))))))
            (#'undo ()
                    (when (> (length undo) 0)
                      (setf lastins undefined)
                      (funcall (first (last undo)))
                      (push (pop undo) redo)))
            (#'redo ()
                    (when (> (length redo) 0)
                      (setf lastins undefined)
                      (funcall (second (last redo)))
                      (push (pop redo) undo))))
      (set-style hinput
                 position "absolute"
                 px/left 0
                 px/top 0
                 px/width 1
                 px/height 1
                 outline "none"
                 border "none"
                 px/padding 0
                 px/margin 0)
      (append-child document.body hinput)
      (set-timeout (lambda () (hinput.focus)) 10)
      (dolist (L (split content "\n"))
        (let ((line (append-child screen (create-element "div"))))
          (set-style line
                     whiteSpace "pre")
          (setf line.textContent (+ L " "))
          (push (new-line L line) lines)))
      (setf screen."data-resize" #'update)
      (set-handler document.body onmousewheel
        (let ((delta (floor (/ event.wheelDelta -60)))
              (screen-lines (floor (/ screen.offsetHeight ch))))
          (setf top (max 0 (min (+ top delta) (- (length lines) screen-lines)))))
        (update))
      (set-handler document.body onkeydown
        (let ((block true))
          (case event.which
            (67
               (when event.ctrlKey
                 (selection-to-hinput))
               (setf block false))
            (88
               (when event.ctrlKey
                 (selection-to-hinput)
                 (delete-selection)
                 (fix))
               (setf block false))
            (86
               (when event.ctrlKey
                 (setf hinput.value "")
                 (hinput.focus)
                 (set-timeout #'paste 10))
               (setf block false))
            (33
               (let ((delta (floor (/ screen.offsetHeight ch))))
                 (decf top delta)
                 (decf row delta)))
            (34
               (let ((delta (floor (/ screen.offsetHeight ch))))
                 (incf top delta)
                 (incf row delta)))
            (35
               (when event.ctrlKey
                 (setf row (1- (length lines))))
               (setf col (length (aref lines row).text)))
            (36
               (when event.ctrlKey
                 (setf row 0))
               (setf col 0))
            (37
               (if (> col 0)
                   (decf col)
                   (when (> row 0)
                     (decf row)
                     (setf col (length (aref lines row).text)))))
            (39
               (if (< col (length (aref lines row).text))
                   (incf col)
                   (when (< row (1- (length lines)))
                     (incf row)
                     (setf col 0))))
            (40
               (if (< row (1- (length lines)))
                   (progn
                     (incf row)
                     (when (> col (length (aref lines row).text))
                       (setf col (length (aref lines row).text))))
                   (setf col (length (aref lines row).text))))
            (38
               (if (> row 0)
                   (progn
                     (decf row)
                     (when (> col (length (aref lines row).text))
                       (setf col (length (aref lines row).text))))
                   (setf col 0)))
            (46
               (when (and (= row s-row) (= col s-col))
                 (if (< s-col (length (aref lines row).text))
                     (incf s-col)
                     (when (< s-row (1- (length lines)))
                       (incf s-row)
                       (setf s-col 0))))
               (delete-selection))
            (8
               (if ifind-mode
                   (progn
                     (when (> (length ifind-text) 0)
                       (setf ifind-text (slice ifind-text 0 -1))
                       (setf s-col (1- s-col)))
                     (event.preventDefault)
                     (event.stopPropagation)
                     (setf block false)
                     (fix))
                   (if (and (= row s-row) (= col s-col))
                       (if (> col 0)
                           (let ((text (aref lines row).text))
                             (change-line row (1- col)
                                          (+ (slice text 0 (1- col))
                                             (slice text col))))
                           (when (> row 0)
                             (let ((rr row)
                                   (sz (length (aref lines row).text)))
                               (mutate
                                (let ((line (aref lines rr))
                                      (prev-line (aref lines (1- rr))))
                                  (setf col (length prev-line.text))
                                  (incf prev-line.text line.text)
                                  (splice lines rr 1)
                                  (touch prev-line)
                                  (setf row (1- rr))
                                  (setf s-col col)
                                  (setf s-row row))
                                (let* ((prev-line (aref lines (1- rr)))
                                       (line (new-line (slice prev-line.text (- sz)))))
                                  (setf prev-line.text (slice prev-line.text 0 (- sz)))
                                  (insert lines rr line)
                                  (setf row rr)
                                  (setf col 0)
                                  (setf s-col col)
                                  (setf s-row row)
                                  (touch prev-line)
                                  (touch line))))))
                       (delete-selection))))
            (13
               (if ifind-mode
                   (setf ifind-mode false)
                   (progn
                     (when (or (/= row s-row) (/= col s-col))
                       (delete-selection))
                     (let* ((r row)
                            (c col)
                            (text (aref lines row).text))
                     (mutate
                      (let ((line (aref lines r))
                            (newline (new-line (slice text c))))
                        (setf line.text (slice text 0 c))
                        (touch line)
                        (setf row (1+ r))
                        (insert lines row newline)
                        (setf col (or (autoindent lines row) 0))
                        (touch newline)
                        (setf s-row row)
                        (setf s-col col))
                      (let ((line (aref lines r)))
                        (setf line.text text)
                        (splice lines (1+ r) 1)
                        (touch line)
                        (setf row r)
                        (setf col c)
                        (setf s-row row)
                        (setf s-col col)))))))
            (27
               (when ifind-mode
                 (setf ifind-mode false)
                 (setf row ifind-row)
                 (setf col ifind-col)
                 (setf top ifind-top)
                 (setf left ifind-left)
                 (fix)))
            (83
               (when event.ctrlKey
                 (if ifind-mode
                     (let ((f (ifind ifind-text lines row (+ col (length ifind-text)))))
                       (when f
                         (setf row (first f))
                         (setf col (second f))
                         (setf s-row row)
                         (setf s-col (+ col (length ifind-text)))))
                     (progn
                       (setf ifind-mode true)
                       (setf ifind-text "")
                       (setf ifind-row row)
                       (setf ifind-col col)
                       (setf ifind-top top)
                       (setf ifind-left left)))
                 (event.stopPropagation)
                 (event.preventDefault)
                 (fix))
               (setf block false))
            (90
               (when event.ctrlKey
                 (undo)
                 (event.stopPropagation)
                 (event.preventDefault)
                 (fix))
               (setf block false))
            (89
               (when event.ctrlKey
                 (redo)
                 (event.stopPropagation)
                 (event.preventDefault)
                 (fix))
               (setf block false))
            (87
               (unless event.ctrlKey
                 (setf block false)))
            (otherwise
               (setf block false)))
          (when block
            (setf ifind-mode false)
            (event.preventDefault)
            (event.stopPropagation)
            (unless event.shiftKey
              (setf s-row row)
              (setf s-col col))
            (fix))))
      (set-handler document.body onkeypress
        (event.preventDefault)
        (event.stopPropagation)
        (if ifind-mode
            (let* ((tx (+ ifind-text (char event.which)))
                   (f (ifind tx lines row col)))
              (when f
                (setf row (first f))
                (setf col (second f))
                (setf ifind-text tx)
                (setf s-row row)
                (setf s-col (+ col (length tx)))
                (fix)))
            (progn
              (when (or (/= row s-row) (/= col s-col))
                (delete-selection))
              (let ((text (aref lines row).text))
                (change-line row (1+ col)
                             (+ (slice text 0 col)
                                (char event.which)
                                (slice text col)))
                (fix)))))
      (set-handler screen onmousedown
        (labels ((pos (x y)
                   (let (((x0 y0) (element-pos screen)))
                     (decf x x0)
                     (decf y y0)
                     (if (and (< 0 x screen.clientWidth)
                              (< 0 y screen.clientHeight))
                         (let ((a (max 0 (min (1- (length lines)) (+ (floor (/ y ch)) top)))))
                           (list a (max 0 (min (floor (/ x cw)) (length (aref lines a).text)))))
                         (list null null)))))
          (let (((r c) (apply #'pos (event-pos event))))
            (unless (null? r)
              (event.preventDefault)
              (event.stopPropagation)
              (setf row r)
              (setf col c)
              (setf s-row r)
              (setf s-col c)
              (fix)
              (let* ((scroller-delta 0)
                     (scroller (set-interval (lambda ()
                                               (incf top scroller-delta)
                                               (incf row scroller-delta)
                                               (fix))
                                             20)))
                (tracking (lambda (x y)
                            (let (((r c) (pos x y)))
                              (if (null? r)
                                  (let (((sx sy) (element-pos screen))
                                        (sh screen.offsetHeight))
                                    (when (< y sy)
                                      (setf scroller-delta (floor (/ (- y sy) ch))))
                                    (when (> y (+ sy sh))
                                      (setf scroller-delta (1+ (floor (/ (- y (+ sy sh)) ch))))))
                                  (progn
                                    (setf scroller-delta 0)
                                    (setf row r)
                                    (setf col c)
                                    (fix)))))
                          (lambda () (clear-interval scroller))))))))
      (set-timeout #'fix 10)
      screen)))

(defun test-editor ()
  (let** ((w (window 0 0 640 480 title: "Editor test"))
          (editor (add-widget w (editor (replace (http-get "bbchess64k.c") "\r" "")))))
    (set-layout w (V border: 8 spacing: 8
                     (dom editor)))
    (show-window w center: true)))

(defun test-editor-fs ()
  (let ((editor (editor (replace (http-get "bbchess64k.c") "\r" "")))
        (frame (create-element "div")))
    (set-style frame
               position "absolute"
               px/left 8
               px/top 8
               px/bottom 8
               px/right 8)
    (set-style editor
               position "absolute"
               px/left 0
               px/top 0)
    (append-child frame editor)
    (append-child document.body frame)
    (let ((fw 0) (fh 0))
      (set-interval (lambda ()
                      (let ((w frame.offsetWidth)
                            (h frame.offsetHeight))
                        (when (or (/= w fw) (/= h fh))
                          (setf fw w)
                          (setf fh h)
                          (set-style editor
                                     px/left 0
                                     px/top 0
                                     px/width fw
                                     px/height fh)
                          (editor."data-resize" 0 0 fw fh))))
                    10))))

(defun main ()
  (test-editor))

(main)