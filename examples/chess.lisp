(defconstant +EMPTY+ 0)
(defconstant +WHITE+ 1)
(defconstant +BLACK+ 2)
(defconstant +COLOR+ (+ +WHITE+ +BLACK+))
(defconstant +PIECE+ (logxor (1- (ash 8 2)) +COLOR+))
(defconstant +OUT+   (+ +WHITE+ +BLACK+))
(defconstant +PAWN+   (ash 1 2))
(defconstant +ROOK+   (ash 2 2))
(defconstant +KNIGHT+ (ash 3 2))
(defconstant +BISHOP+ (ash 4 2))
(defconstant +QUEEN+  (ash 5 2))
(defconstant +KING+   (ash 6 2))

(defconstant +PROMOTION-LIST+ (list +QUEEN+ +ROOK+ +KNIGHT+ +BISHOP+))

(defconstant +WQF+    (ash 1 0))
(defconstant +WKF+    (ash 1 1))
(defconstant +BQF+    (ash 1 2))
(defconstant +BKF+    (ash 1 3))
(defconstant +CFLAGS+ (+ +WQF+ +WKF+ +BQF+ +BKF+))

(defconstant +WP+ (+ +WHITE+ +PAWN+))
(defconstant +WR+ (+ +WHITE+ +ROOK+))
(defconstant +WN+ (+ +WHITE+ +KNIGHT+))
(defconstant +WB+ (+ +WHITE+ +BISHOP+))
(defconstant +WQ+ (+ +WHITE+ +QUEEN+))
(defconstant +WK+ (+ +WHITE+ +KING+))

(defconstant +BP+ (+ +BLACK+ +PAWN+))
(defconstant +BR+ (+ +BLACK+ +ROOK+))
(defconstant +BN+ (+ +BLACK+ +KNIGHT+))
(defconstant +BB+ (+ +BLACK+ +BISHOP+))
(defconstant +BQ+ (+ +BLACK+ +QUEEN+))
(defconstant +BK+ (+ +BLACK+ +KING+))

(defconstant ---- +EMPTY+)
(defconstant -xx- +OUT+)

(defconstant +PAWN-VALUE+   100)
(defconstant +ROOK-VALUE+   500)
(defconstant +KNIGHT-VALUE+ 300)
(defconstant +BISHOP-VALUE+ 310)
(defconstant +QUEEN-VALUE+  900)
(defconstant +KING-VALUE+   99999)

(defvar *material-value* (list))
(setf (aref *material-value* +PAWN+)   +PAWN-VALUE+)
(setf (aref *material-value* +ROOK+)   +ROOK-VALUE+)
(setf (aref *material-value* +KNIGHT+) +KNIGHT-VALUE+)
(setf (aref *material-value* +BISHOP+) +BISHOP-VALUE+)
(setf (aref *material-value* +QUEEN+)  +QUEEN-VALUE+)
(setf (aref *material-value* +KING+)   +KING-VALUE+)

(setf (aref *material-value* ----) 0)
(setf (aref *material-value* -xx-) 0)

(setf (aref *material-value* +WP+)   +PAWN-VALUE+)
(setf (aref *material-value* +WR+)   +ROOK-VALUE+)
(setf (aref *material-value* +WN+) +KNIGHT-VALUE+)
(setf (aref *material-value* +WB+) +BISHOP-VALUE+)
(setf (aref *material-value* +WQ+)  +QUEEN-VALUE+)
(setf (aref *material-value* +WK+)   +KING-VALUE+)

(setf (aref *material-value* +BP+)   (- +PAWN-VALUE+))
(setf (aref *material-value* +BR+)   (- +ROOK-VALUE+))
(setf (aref *material-value* +BN+) (- +KNIGHT-VALUE+))
(setf (aref *material-value* +BB+) (- +BISHOP-VALUE+))
(setf (aref *material-value* +BQ+)  (- +QUEEN-VALUE+))
(setf (aref *material-value* +BK+)  (-  +KING-VALUE+))

(defun tosq (y x)
  (+ (* 10 y) x 21))

(defun sq (x)
  (tosq (index (aref x 1) "87654321")
        (index (aref x 0) "abcdefgh")))

(defun sqname (x)
  (+ (aref "abcdefgh" (1- (% x 10)))
     (aref "87654321" (- (floor (/ x 10)) 2))))

(dolist (x "abcdefgh")
  (dolist (y "12345678")
    (setf (symbol-value (intern ~"{x}{y}"))
          (sq ~"{x}{y}"))))

(defconstant +UFLAGS+
  (let ((x (list)))
    (dotimes (i 120)
      (push -1 x))
    (setf (aref x (sq "a8")) (- +CFLAGS+ +BQF+))
    (setf (aref x (sq "h8")) (- +CFLAGS+ +BKF+))
    (setf (aref x (sq "e8")) (- +CFLAGS+ +BQF+ +BKF+))
    (setf (aref x (sq "a1")) (- +CFLAGS+ +WQF+))
    (setf (aref x (sq "h1")) (- +CFLAGS+ +WKF+))
    (setf (aref x (sq "e1")) (- +CFLAGS+ +WQF+ +WKF+))
    x))

(defconstant +ROOK-DIR+ (list 1 -1 10 -10))
(defconstant +KNIGHT-DIR+ (list 8 -8 12 -12 19 -19 21 -21))
(defconstant +BISHOP-DIR+ (list 9 -9 11 -11))
(defconstant +QUEEN-DIR+ (append +ROOK-DIR+ +BISHOP-DIR+))
(defconstant +KING-DIR+ +QUEEN-DIR+)

;; The chessboard
(defvar *sq*)
(defvar *color*)
(defvar *ep-square*)
(defvar *flags*)
(defvar *history*)
(defvar *material*)

;; [x] -> (aref *sq* x)
;; [+ x 1] -> (aref *sq* (+ x 1))
(setf (reader "[")
      (lambda (src)
        (next-char src)
        (let ((x (parse-delimited-list src "]")))
          (if (> (length x) 1)
              `(aref *sq* ,x)
              `(aref *sq* ,@x)))))

(defun init-board (&optional (fen "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"))
  "Setup chessboard from the standard FEN representation"
  (let ((sq (list -xx- -xx- -xx- -xx- -xx- -xx- -xx- -xx- -xx- -xx-
                  -xx- -xx- -xx- -xx- -xx- -xx- -xx- -xx- -xx- -xx-
                  -xx- ---- ---- ---- ---- ---- ---- ---- ---- -xx-
                  -xx- ---- ---- ---- ---- ---- ---- ---- ---- -xx-
                  -xx- ---- ---- ---- ---- ---- ---- ---- ---- -xx-
                  -xx- ---- ---- ---- ---- ---- ---- ---- ---- -xx-
                  -xx- ---- ---- ---- ---- ---- ---- ---- ---- -xx-
                  -xx- ---- ---- ---- ---- ---- ---- ---- ---- -xx-
                  -xx- ---- ---- ---- ---- ---- ---- ---- ---- -xx-
                  -xx- ---- ---- ---- ---- ---- ---- ---- ---- -xx-
                  -xx- -xx- -xx- -xx- -xx- -xx- -xx- -xx- -xx- -xx-
                  -xx- -xx- -xx- -xx- -xx- -xx- -xx- -xx- -xx- -xx-))
        (i 0)
        (color +WHITE+)
        (flags 0)
        (epsq 0)
        (mat 0))
    (do ((y 0)
         (x 0))
        ((and (= y 7) (= x 8)))
      (let ((c (aref fen (1- (incf i)))))
        (cond
          ((<= "1" c "8")
           (incf x (js-code "parseInt(d$$c)"))
           (unless (<= x 8) (error "Invalid FEN string")))
          ((find c "prnbqkPRNBQK")
           (unless (< x 8) (error "Invalid FEN string"))
           (let ((p (aref '#.(list +BP+ +BR+ +BN+ +BB+ +BQ+ +BK+
                                   +WP+ +WR+ +WN+ +WB+ +WQ+ +WK+)
                          (index c "prnbqkPRNBQK"))))
             (setf (aref sq (tosq y x)) p)
             (incf mat (aref *material-value* p)))
           (incf x))
          ((= c "/")
           (unless (= x 8) (error "Invalid FEN string"))
           (setf x 0)
           (incf y))
          (true (error "Invalid FEN string")))))
    (do () ((or (>= i (length fen))
                (/= (aref fen i) " ")))
      (incf i))
    (cond
      ((= (aref fen i) "w")
       (setf color +WHITE+))
      ((= (aref fen i) "b")
       (setf color +BLACK+))
      (true (error "Invalid FEN string")))
    (incf i)
    (do () ((or (>= i (length fen))
                (/= (aref fen i) " ")))
      (incf i))
    (do () ((or (>= i (length fen))
                (= (aref fen i) " ")))
      (if (find (aref fen i) "QKqk-")
          (setf flags (logior flags
                              (aref (list +WQF+ +WKF+ +BQF+ +BKF+ 0)
                                    (index (aref fen i) "QKqk-"))))
          (error "Invalid FEN string"))
      (incf i))
    (do () ((or (>= i (length fen))
                (/= (aref fen i) " ")))
      (incf i))
    (cond
      ((= (aref fen i) "-")
       (setf epsq 0)
       (incf i))
      ((and (<= "a" (aref fen i) "h")
            (= (aref fen (1+ i)) (if (= color +WHITE+) 6 3)))
       (setf epsq (tosq (if (= color +WHITE+) 2 5)
                        (index (aref fen i) "abcdefgh")))
       (incf i))
      (true (error "Invalid FEN string")))
    (setf *sq* sq)
    (setf *color* color)
    (setf *flags* flags)
    (setf *ep-square* epsq)
    (setf *history* (list))
    (setf *material* mat)))

(defvar *pnames* #((#.+WP+ "P")
                   (#.+WR+ "R")
                   (#.+WN+ "N")
                   (#.+WB+ "B")
                   (#.+WQ+ "Q")
                   (#.+WK+ "K")
                   (#.+BP+ "p")
                   (#.+BR+ "r")
                   (#.+BN+ "n")
                   (#.+BB+ "b")
                   (#.+BQ+ "q")
                   (#.+BK+ "k")))

(defun ascii-board ()
  "ASCII graphical representation of the chessboard"
  (let ((res ""))
    (dotimes (y 8)
      (dotimes (x 8)
        (let ((i (tosq y x)))
          (setf res (+ res
                       (if [i]
                           (aref *pnames* [i])
                           (aref "-=" (% (+ x y) 2)))))))
      (when (and (= y 0) (= +BLACK+ *color*))
        (setf res (+ res " *")))
      (when (and (= y 7) (= +WHITE+ *color*))
        (setf res (+ res " *")))
      (setf res (+ res "\n")))
    (+ res "\n")))


(defmacro move (x0 x1 &optional np)
  (if np
      `(+ ,x0 (ash ,x1 7) (ash ,np 14))
      `(+ ,x0 (ash ,x1 7))))
(defmacro move-x0 (m) `(logand ,m 127))
(defmacro move-x1 (m) `(logand (ash ,m -7) 127))
(defmacro move-np (m) `(logand (ash ,m -14) 127))

(defun move-str (m)
  (+ (sqname (move-x0 m))
     (if (= [move-x1 m] +EMPTY+) "-" "x")
     (sqname (move-x1 m))
     (if (move-np m)
         ~"={(aref *pnames* (+ +WHITE+ (logand (move-np m) +PIECE+)))}"
         "")))

(defun play (move)
  "Play a move on the chessboard"
  (let ((x0 (move-x0 move))
        (x1 (move-x1 move))
        (np (move-np move)))
    (push (list x0 x1 [x0] [x1] *ep-square* *flags*)
          *history*)
    (unless np
      (setf np [x0]))
    (incf *material* (- (aref *material-value* np)
                        (aref *material-value* [x0])
                        (aref *material-value* [x1])))
    (setf [x1] np)
    (setf [x0] +EMPTY+)
    (setf *flags* (logand *flags*
                          (aref +UFLAGS+ x0)
                          (aref +UFLAGS+ x1)))
    (when (= x1 *ep-square*)
      (cond
        ((= np +WP+)
         (setf [+ x1 10] +EMPTY+)
         (incf *material* +PAWN-VALUE+))
        ((= np +BP+)
         (setf [- x1 10] +EMPTY+)
         (decf *material* +PAWN-VALUE+))))
    (when (= (logand np +PIECE+) +KING+)
      (cond
        ((= (- x1 x0) 2)
         (setf [1+ x0] [1+ x1])
         (setf [1+ x1] +EMPTY+))
        ((= (- x0 x1) 2)
         (setf [1- x0] [- x1 2])
         (setf [- x1 2] +EMPTY+))))
    (cond
      ((and (= np +WP+) (= (- x1 x0) -20))
       (setf *ep-square* (+ x1 10)))
      ((and (= np +BP+) (= (- x1 x0) 20))
       (setf *ep-square* (- x1 10)))
      (true
       (setf *ep-square* 0)))
    (setf *color* (logxor +COLOR+ *color*))))

(defun undo ()
  "Undo last move on the chessboard"
  (let (((x0 x1 px0 px1 epsq flags) (pop *history*)))
    (decf *material* (+ (aref *material-value* [x0])
                        (aref *material-value* [x1])))
    (setf [x0] px0)
    (setf [x1] px1)
    (incf *material* (+ (aref *material-value* [x0])
                        (aref *material-value* [x1])))
    (setf *ep-square* epsq)
    (setf *flags* flags)
    (setf *color* (logxor +COLOR+ *color*))
    (when (= x1 epsq)
      (cond
        ((= px0 +WP+)
         (setf [+ x1 10] +BP+)
         (decf *material* +PAWN-VALUE+))
        ((= px0 +BP+)
         (setf [- x1 10] +WP+)
         (incf *material* +PAWN-VALUE+))))
    (when (= (logand px0 +PIECE+) +KING+)
      (cond
        ((= (- x1 x0) 2)
         (setf [1+ x1] [1+ x0])
         (setf [1+ x0] +EMPTY+))
        ((= (- x0 x1) 2)
         (setf [- x1 2] [1- x0])
         (setf [1- x0] +EMPTY+))))))

(defun attacks (x color)
  "True if square x is formally attacked by specified color"
  (let ((pdir (if (= color +WHITE+) 10 -10))
        (p (+ color +PAWN+))
        (r (+ color +ROOK+))
        (n (+ color +KNIGHT+))
        (b (+ color +BISHOP+))
        (q (+ color +QUEEN+))
        (k (+ color +KING+)))
    #.`(or (= [+ x pdir -1] p)
           (= [+ x pdir 1] p)
           ,@(map (lambda (d) `(= [+ x ,d] n))
                  +KNIGHT-DIR+)
           ,@(map (lambda (d) `(= [+ x ,d] q))
                  +QUEEN-DIR+)
           ,@(map (lambda (d) `(= [+ x ,d] k))
                  +QUEEN-DIR+)
           ,@(map (lambda (d) `(= [+ x ,d] r))
                  +ROOK-DIR+)
           ,@(map (lambda (d) `(= [+ x ,d] b))
                  +BISHOP-DIR+)
           ,@(map (lambda (d)
                    (labels ((step (i f)
                               `(and (= [+ x ,(* i d)] +EMPTY+)
                                     (or (= [+ x ,(* (1+ i) d)] q)
                                         (= [+ x ,(* (1+ i) d)] ,f)
                                         ,@(if (< i 6)
                                               (list (step (1+ i) f))
                                               (list))))))
                      (step 1 (if (find d +ROOK-DIR+) 'r 'b))))
                  +QUEEN-DIR+))))

(defun check ()
  "True if player is currently under check"
  (attacks (index (+ *color* +KING+) *sq*) (logxor +COLOR+ *color*)))

(defun pmove-map (f)
  "Calls the specified function passing all pseudo-legal moves"
  (let ((opponent (logxor +COLOR+ *color*)))
    (when (/= *ep-square* 0)
      (when (= [+ *ep-square* (if (= *color* +WHITE+) 9 -9)] (+ *color* +PAWN+))
        (funcall f (move (+ *ep-square* (if (= *color* +WHITE+) 9 -9)) *ep-square*)))
      (when (= [+ *ep-square* (if (= *color* +WHITE+) 11 -11)] (+ *color* +PAWN+))
        (funcall f (move (+ *ep-square* (if (= *color* +WHITE+) 11 -11)) *ep-square*))))
    (dotimes (x 99)
      (let ((p (logxor [x] *color*)))
        (when (= 0 (logand p +COLOR+))
          (cond
            ((= [x] +WP+)
             (when (= (logand [- x 9] +COLOR+) +BLACK+)
               (funcall f (move x (- x 9))))
             (when (= (logand [- x 11] +COLOR+) +BLACK+)
               (funcall f (move x (- x 11))))
             (when (= [- x 10] +EMPTY+)
               (funcall f (move x (- x 10)))
               (when (and (= [- x 20] +EMPTY+)
                          (= [+ x 20] +OUT+))
                 (funcall f (move x (- x 20))))))

            ((= [x] +BP+)
             (when (= (logand [+ x 9] +COLOR+) +WHITE+)
               (funcall f (move x (+ x 9))))
             (when (= (logand [+ x 11] +COLOR+) +WHITE+)
               (funcall f (move x (+ x 11))))
             (when (= [+ x 10] +EMPTY+)
               (funcall f (move x (+ x 10)))
               (when (and (= [+ x 20] +EMPTY+)
                          (= [- x 20] +OUT+))
                 (funcall f (move x (+ x 20))))))

            ((= p +KNIGHT+)
             (dolist (d +KNIGHT-DIR+)
               (let ((y (+ x d)))
                 (when (or (= [y] +EMPTY+)
                           (= (logand [y] +COLOR+) opponent))
                   (funcall f (move x y))))))

            ((= p +ROOK+)
             (dolist (d +ROOK-DIR+)
               (do ((y (+ x d) (+ y d)))
                   ((/= [y] +EMPTY+)
                      (when (= (logand [y] +COLOR+) opponent)
                        (funcall f (move x y))))
                 (funcall f (move x y)))))

            ((= p +BISHOP+)
             (dolist (d +BISHOP-DIR+)
               (do ((y (+ x d) (+ y d)))
                   ((/= [y] +EMPTY+)
                      (when (= (logand [y] +COLOR+) opponent)
                        (funcall f (move x y))))
                 (funcall f (move x y)))))

            ((= p +QUEEN+)
             (dolist (d +QUEEN-DIR+)
               (do ((y (+ x d) (+ y d)))
                   ((/= [y] +EMPTY+)
                      (when (= (logand [y] +COLOR+) opponent)
                        (funcall f (move x y))))
                 (funcall f (move x y)))))

            ((= p +KING+)
             (dolist (d +QUEEN-DIR+)
               (let ((y (+ x d)))
                 (when (or (= [y] +EMPTY+)
                           (= (logand [y] +COLOR+) opponent))
                   (funcall f (move x y)))))
             (when (and (logand *flags* (if (= *color* +WHITE+) +WKF+ +BKF+))
                        (= [+ x 1] 0)
                        (= [+ x 2] 0)
                        (not (check))
                        (not (attacks (+ x 1) opponent)))
               (funcall f (move x (+ x 2))))
             (when (and (logand *flags* (if (= *color* +WHITE+) +WQF+ +BQF+))
                        (= [- x 1] 0)
                        (= [- x 2] 0)
                        (= [- x 3] 0)
                        (not (check))
                        (not (attacks (- x 1) opponent)))
               (funcall f (move x (- x 2)))))))))))

(defun legal (m)
  "True if a move doesn't leave the king under check"
  (play m)
  (let ((legal (not (attacks (index (logxor *color* +COLOR+ +KING+) *sq*)
                             *color*))))
    (undo)
    legal))

(defun genmove (f m)
  "Calls function [f] passing the move [m], optionally generating pawn promotions"
  (if (and (= [move-x0 m] (+ *color* +PAWN+))
           (= [+ (move-x1 m) (if (= *color* +WHITE+) -10 10)] +OUT+))
      (dolist (y +PROMOTION-LIST+)
        (funcall f (move (move-x0 m) (move-x1 m) (+ *color* y))))
      (funcall f m)))

(defun move-map (f)
  "Calls the specified function with all legal moves"
  (let ((special (list))
        (kp (index (+ *color* +KING+) *sq*))
        (opponent (logxor *color* +COLOR+))
        (check (check)))
    (dotimes (i 120)
      (setf (aref special i) false))
    ;; King moves needs always to be considered
    (setf (aref special kp) true)
    (if check
        (progn
          ;; When king is under attack only consider moves that
          ;; can possibly solve the problem. A valid move will
          ;; move the King or will end in a square that is
          ;; at queen or knight from the king (it must either
          ;; shield the king or capture the offender).
          (dolist (d +QUEEN-DIR+)
            (do ((x (+ kp d) (+ x d)))
                ((/= [x] +EMPTY+)
                   (setf (aref special x) true))
              (setf (aref special x) true)))
          (dolist (d +KNIGHT-DIR+)
            (setf (aref special (+ kp d)) true))
          (pmove-map (lambda (m)
                       (when (and (or (= (move-x0 m) kp)
                                      (aref special (move-x1 m)))
                                  (legal m))
                         (genmove f m)))))
        (progn
          ;; When *not* in check any move that starts from a
          ;; square that is at queen of the king is potentially
          ;; dangerous (the piece could be pinned).
          (dolist (d +QUEEN-DIR+)
            (do ((x (+ kp d) (+ x d)))
                ((/= [x] +EMPTY+)
                   (setf (aref special x) true)
                   ;; Annoying special case: en-passant captures are
                   ;; dangerous if the king is on the same horizontal
                   ;; line because in this case TWO occupied squares
                   ;; become free with a single move.
                   ;; Consider "8/8/8/8/R3p1k1/8/5P2/5K2 w - - 0 1"
                   ;; after the move f4.
                   (when (and (or (= d -1) (= d 1))
                              (if (= *color* +WHITE+)
                                  (<= a5 kp h5)
                                  (<= a4 kp h4))
                              (= [x] (+ opponent +PAWN+))
                              (= [+ x d] (+ *color* +PAWN+)))
                     (setf (aref special (+ x d)) true)))))
          (pmove-map (lambda (m)
                       (when (or (not (aref special (move-x0 m)))
                                 (legal m))
                         (genmove f m))))))))

(defconstant +MY+PAWN+    (ash 1 0))
(defconstant +MY+KNIGHT+  (ash 1 1))
(defconstant +MY+BISHOP+  (ash 1 2))
(defconstant +MY+ROOK+    (ash 1 3))
(defconstant +MY+QUEEN+   (ash 1 4))
(defconstant +MY+KING+    (ash 1 5))
(defconstant +OPP+        5)
(defconstant +OPP+PAWN+   (ash +MY+PAWN+   +OPP+))
(defconstant +OPP+KNIGHT+ (ash +MY+KNIGHT+ +OPP+))
(defconstant +OPP+ROOK+   (ash +MY+ROOK+   +OPP+))
(defconstant +OPP+BISHOP+ (ash +MY+BISHOP+ +OPP+))
(defconstant +OPP+QUEEN+  (ash +MY+QUEEN+  +OPP+))
(defconstant +OPP+KING+   (ash +MY+KING+   +OPP+))

(defun static-value ()
  "Returns a static evaluation of the position (meaningful only if no trivial captures are possible)"
  (let ((atk (list))
        (space 0)
        (opponent (logxor *color* +COLOR+)))
    (dotimes (i 120)
      (setf (aref atk i) 0))
    (labels ((set (x bit)
               (setf (aref atk x) (logior (aref atk x) bit))))
      (dotimes (x 120)
        (let ((p (logxor [x] *color*)))
          (cond
            ((= p +PAWN+)
             (let ((y (+ x (if (= *color* +WHITE+) -10 10))))
               (set (1- y) +MY+PAWN+)
               (set (1+ y) +MY+PAWN+)))
            ((= p #.(+ +COLOR+ +PAWN+))
             (let ((y (+ x (if (= *color* +WHITE+) 10 -10))))
               (set (1- y) +OPP+PAWN+)
               (set (1+ y) +OPP+PAWN+)))
            ((= p +ROOK+)
             (dolist (d +ROOK-DIR+)
               (do ((y (+ x d) (+ y d)))
                   ((/= [y] +EMPTY+)
                      (set y +MY+ROOK+)))))
            ((= p +BISHOP+)
             (dolist (d +BISHOP-DIR+)
               (do ((y (+ x d) (+ y d)))
                   ((/= [y] +EMPTY+)
                      (set y +MY+BISHOP+)))))
            ((= p +QUEEN+)
             (dolist (d +QUEEN-DIR+)
               (do ((y (+ x d) (+ y d)))
                   ((/= [y] +EMPTY+)
                      (set y +MY+QUEEN+)))))
            ((= p +KNIGHT+)
             (dolist (d +KNIGHT-DIR+)
               (let ((y (+ x d)))
                 (set y +MY+KNIGHT+))))
            ((= p +KING+)
             (dolist (d +QUEEN-DIR+)
               (let ((y (+ x d)))
                 (set y +MY+KING+))))
            ((= p #.(+ +COLOR+ +ROOK+))
             (dolist (d +ROOK-DIR+)
               (do ((y (+ x d) (+ y d)))
                   ((/= [y] +EMPTY+)
                      (set y +OPP+ROOK+)))))
            ((= p #.(+ +COLOR+ +BISHOP+))
             (dolist (d +BISHOP-DIR+)
               (do ((y (+ x d) (+ y d)))
                   ((/= [y] +EMPTY+)
                      (set y +OPP+BISHOP+)))))
            ((= p #.(+ +COLOR+ +QUEEN+))
             (dolist (d +QUEEN-DIR+)
               (do ((y (+ x d) (+ y d)))
                   ((/= [y] +EMPTY+)
                      (set y +OPP+QUEEN+)))))
            ((= p #.(+ +COLOR+ +KNIGHT+))
             (dolist (d +KNIGHT-DIR+)
               (let ((y (+ x d)))
                 (set y +OPP+KNIGHT+))))
            ((= p #.(+ +COLOR+ +KING+))
             (dolist (d +KING-DIR+)
               (let ((y (+ x d)))
                 (set y +OPP+KING+))))))))
    (labels ((space (color x forbidden)
               (if (and (or (= [x] +EMPTY+)
                            (= (logand +COLOR+ (logxor [x] color)) +COLOR+))
                        (= (logand (aref atk x) forbidden) 0))
                   1 0)))
      (dotimes (x 120)
        (let ((p (logxor [x] *color*)))
          (cond
            ((= p +KNIGHT+)
             (dolist (d +KNIGHT-DIR+)
               (let ((y (+ x d)))
                 (incf space (space *color* y +OPP+PAWN+)))))
            ((= p #.(+ +COLOR+ +KNIGHT+))
             (dolist (d +KNIGHT-DIR+)
               (let ((y (+ x d)))
                 (decf space (space opponent y +MY+PAWN+)))))
            ((= p +BISHOP+)
             (dolist (d +BISHOP-DIR+)
               (do ((y (+ x d) (+ y d)))
                   ((/= [y] +EMPTY+)
                      (incf space (space *color* y +OPP+PAWN+)))
                 (incf space (space *color* y +OPP+PAWN+)))))
            ((= p #.(+ +COLOR+ +BISHOP+))
             (dolist (d +BISHOP-DIR+)
               (do ((y (+ x d) (+ y d)))
                   ((/= [y] +EMPTY+)
                      (decf space (space opponent y +MY+PAWN+)))
                 (decf space (space opponent y +MY+PAWN+)))))
            ((= p +ROOK+)
             (dolist (d +ROOK-DIR+)
               (do ((y (+ x d) (+ y d)))
                   ((/= [y] +EMPTY+)
                      (incf space (space *color* y #.(+ +OPP+PAWN+ +OPP+KNIGHT+ +OPP+BISHOP+))))
                 (incf space (space *color* y #.(+ +OPP+PAWN+ +OPP+KNIGHT+ +OPP+BISHOP+))))))
            ((= p #.(+ +COLOR+ +ROOK+))
             (dolist (d +ROOK-DIR+)
               (do ((y (+ x d) (+ y d)))
                   ((/= [y] +EMPTY+)
                      (decf space (space opponent y #.(+ +MY+PAWN+ +MY+KNIGHT+ +MY+BISHOP+))))
                 (decf space (space opponent y #.(+ +MY+PAWN+ +MY+KNIGHT+ +MY+BISHOP+))))))
            ((= p +QUEEN+)
             (dolist (d +QUEEN-DIR+)
               (do ((y (+ x d) (+ y d)))
                   ((/= [y] +EMPTY+)
                      (incf space (space *color* y #.(+ +OPP+PAWN+ +OPP+KNIGHT+ +OPP+BISHOP+ +OPP+ROOK+))))
                 (incf space (space *color* y #.(+ +OPP+PAWN+ +OPP+KNIGHT+ +OPP+BISHOP+ +OPP+ROOK+))))))
            ((= p #.(+ +COLOR+ +QUEEN+))
             (dolist (d +QUEEN-DIR+)
               (do ((y (+ x d) (+ y d)))
                   ((/= [y] +EMPTY+)
                      (decf space (space opponent y #.(+ +OPP+PAWN+ +OPP+KNIGHT+ +OPP+BISHOP+ +OPP+ROOK+))))
                 (decf space (space opponent y #.(+ +OPP+PAWN+ +OPP+KNIGHT+ +OPP+BISHOP+ +OPP+ROOK+))))))))))
    (+ (if (= *color* +WHITE+) *material* (- *material*))
       space)))

(defconstant +MAX-POSITIONAL-CONTRIBUTION+ +PAWN-VALUE+)

(defun bounded-static-value (min max)
  "Returns the static evaluation only if is higher than [min] and
lower than [max], otherwise just return [min] or [max]. This may be
done more efficently than just computing the evaluation and comparing
if we know the material imbalance is already too big to be compensated
by positional considerations."
  (let ((v (if (= *color* +WHITE+) *material* (- *material*))))
    (cond
      ((<= (+ v +MAX-POSITIONAL-CONTRIBUTION+) min) min)
      ((>= (- v +MAX-POSITIONAL-CONTRIBUTION+) max) max)
      (true (static-value)))))

(defun trivial-capture-map (x f)
  "Calls function [f] for each legal trivial capture to square [x].
Trivial means that either the capturing piece is less valuable than captured piece
or that the captured piece is not defended."
  (let ((pdir (if (= *color* +WHITE+) 10 -10))
        (p (+ *color* +PAWN+))
        (r (+ *color* +ROOK+))
        (n (+ *color* +KNIGHT+))
        (b (+ *color* +BISHOP+))
        (q (+ *color* +QUEEN+))
        (k (+ *color* +KING+))
        (y null)
        (captured (if (attacks x (logxor *color* +COLOR+))
                      (aref *material-value* (logand [x] +PIECE+))
                      (1+ +KING-VALUE+))))
    (labels ((process (y)
               (let ((m (move y x)))
                 (when (legal m)
                   (genmove f m)))))
      (when (= [setf y (+ x pdir -1)] p)
        (process y))
      (when (= [setf y (+ x pdir 1)] p)
        (process y))
      (when (> captured +PAWN-VALUE+)
        (dolist (d +KNIGHT-DIR+)
          (when (= [setf y (+ x d)] n)
            (process y)))
        (when (> captured +QUEEN-VALUE+)
          (dolist (d +QUEEN-DIR+)
            (when (= [setf y (+ x d)] k)
              (process y))))
        (when (> captured +BISHOP-VALUE+)
          (dolist (d +BISHOP-DIR+)
            (do ((y (+ x d) (+ y d)))
                ((/= [y] +EMPTY+)
                   (when (or (= [y] b) (= [y] q))
                     (process y)))))
          (when (> captured +ROOK-VALUE+)
            (dolist (d +ROOK-DIR+)
              (do ((y (+ x d) (+ y d)))
                  ((/= [y] +EMPTY+)
                     (when (or (= [y] r) (= [y] q))
                       (process y)))))))))))

(defun capture-map (x f)
  "Calls funcion f for each legal capture to square x"
  (let ((pdir (if (= *color* +WHITE+) 10 -10))
        (p (+ *color* +PAWN+))
        (r (+ *color* +ROOK+))
        (n (+ *color* +KNIGHT+))
        (b (+ *color* +BISHOP+))
        (q (+ *color* +QUEEN+))
        (k (+ *color* +KING+))
        (y null))
    (labels ((process (y)
               (let ((m (move y x)))
                 (when (legal m)
                   (genmove f m)))))
      (when (= [setf y (+ x pdir -1)] p)
        (process y))
      (when (= [setf y (+ x pdir 1)] p)
        (process y))
      (dolist (d +KNIGHT-DIR+)
        (when (= [setf y (+ x d)] n)
          (process y)))
      (dolist (d +QUEEN-DIR+)
        (when (= [setf y (+ x d)] k)
          (process y)))
      (dolist (d +BISHOP-DIR+)
        (do ((y (+ x d) (+ y d)))
            ((/= [y] +EMPTY+)
               (when (or (= [y] b) (= [y] q))
                 (process y)))))
      (dolist (d +ROOK-DIR+)
        (do ((y (+ x d) (+ y d)))
            ((/= [y] +EMPTY+)
               (when (or (= [y] r) (= [y] q))
                 (process y))))))))

(defun alpha-beta (depth alpha beta)
  (let ((moves false))
    (labels ((process (m)
               (setf moves true)
               (play m)
               (let ((v (- (alpha-beta (1- depth) (- beta) (- alpha)))))
                 (undo)
                 (when (> v alpha)
                   (setf alpha v))
                 (when (>= v beta)
                   (return-from alpha-beta beta)))))
      (if (and (< depth 0) (not (check)))
          (let ((v (bounded-static-value (- alpha 10) (+ beta 10))))
            (incf v (- (random-int 21) 10))
            (when (> v alpha)
              (setf alpha v))
            (when (>= v beta)
              (return-from alpha-beta beta))
            (trivial-capture-map (second (last *history*))
                                 #'process)
            (return-from alpha-beta alpha))
          (if (> (length *history*) 0)
              (let ((x (second (last *history*))))
                (capture-map x #'process)
                (move-map (lambda (m)
                            (unless (= x (move-x1 m))
                              (process m)))))
              (move-map #'process)))
      (if moves
          alpha
          (if (check) -99999 0)))))

(defun perft (n)
  (if (= n 0)
      1
      (let ((count 0))
        (move-map (lambda (m)
                    (play m)
                    (incf count (perft (1- n)))
                    (undo)))
        count)))

(defun perft-debug (n)
  (let ((res (list))
        (total 0))
    (move-map (lambda (m)
                (push (+ (aref *pnames* (logior +WHITE+ (logand [move-x0 m] +PIECE+)))
                         (sqname (move-x0 m))
                         (if (= [move-x1 m] +EMPTY+) "-" "x")
                         (sqname (move-x1 m))
                         " = "
                         (progn
                           (play m)
                           (let ((count (perft (1- n))))
                             (incf total count)
                             count)))
                      res)
                (undo)))
    (dolist (x (sort res))
      (display x))
    (display ~"Total ---> {total}")))

(defun computer (n)
  (let ((best null))
    (move-map (lambda (m)
                (play m)
                (let ((v (- (alpha-beta n -1000000 1000000))))
                  (undo)
                  (when (or (null? best) (> v (first best)))
                    (setf best (list v m))))))
    (unless (null? best)
      (play (second best)))))

(defstruct chessboard
  sq color ep-square flags history material)

(defun chessboard (&optional fen)
  (if fen
      (init-board fen)
      (init-board))
  (make-chessboard :sq *sq*
                   :color *color*
                   :ep-square *ep-square*
                   :flags *flags*
                   :history *history*
                   :material *material*))

(defmacro with-board (b &rest body)
  (let ((bb (gensym))
        (res (gensym)))
    `(let ((,bb ,b))
       (let ((*sq* (chessboard-sq ,bb))
             (*color* (chessboard-color ,bb))
             (*ep-square* (chessboard-ep-square ,bb))
             (*history* (chessboard-history ,bb))
             (*material* (chessboard-material ,bb)))
         (let ((,res (progn ,@body)))
           (setf (chessboard-sq ,bb) (slice *sq*))
           (setf (chessboard-color ,bb) *color*)
           (setf (chessboard-ep-square ,bb) *ep-square*)
           (setf (chessboard-history ,bb) (slice *history*))
           (setf (chessboard-material ,bb) *material*)
           ,res)))))