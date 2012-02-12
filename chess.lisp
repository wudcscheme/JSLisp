
(defvar *EMPTY* 0)
(defvar *WHITE* 1)
(defvar *BLACK* 2)
(defvar *COLOR* (+ *WHITE* *BLACK*))
(defvar *PIECE* (logxor (1- (ash 8 2)) *COLOR*))
(defvar *OUT*   (+ *WHITE* *BLACK*))
(defvar *PAWN*   (ash 1 2))
(defvar *ROOK*   (ash 2 2))
(defvar *KNIGHT* (ash 3 2))
(defvar *BISHOP* (ash 4 2))
(defvar *QUEEN*  (ash 5 2))
(defvar *KING*   (ash 6 2))

(defvar *WQF*    (ash 1 0))
(defvar *WKF*    (ash 1 1))
(defvar *BQF*    (ash 1 2))
(defvar *BKF*    (ash 1 3))
(defvar *CFLAGS* (+ *WQF* *WKF* *BQF* *BKF*))

(defvar *WP* (+ *WHITE* *PAWN*))
(defvar *WR* (+ *WHITE* *ROOK*))
(defvar *WN* (+ *WHITE* *KNIGHT*))
(defvar *WB* (+ *WHITE* *BISHOP*))
(defvar *WQ* (+ *WHITE* *QUEEN*))
(defvar *WK* (+ *WHITE* *KING*))

(defvar *BP* (+ *BLACK* *PAWN*))
(defvar *BR* (+ *BLACK* *ROOK*))
(defvar *BN* (+ *BLACK* *KNIGHT*))
(defvar *BB* (+ *BLACK* *BISHOP*))
(defvar *BQ* (+ *BLACK* *QUEEN*))
(defvar *BK* (+ *BLACK* *KING*))

(defvar ---- *EMPTY*)
(defvar -xx- *OUT*)

(defun tosq (y x)
  (+ (* 10 y) x 21))

(defun sq (x)
  (tosq (index (aref x 1) "87654321")
        (index (aref x 0) "abcdefgh")))

(dolist (x "abcdefgh")
  (dolist (y "12345678")
    (setf (symbol-value (intern ~"{x}{y}"))
          (sq ~"{x}{y}"))))

(defvar *UFLAGS*
  (let ((x (list)))
    (dotimes (i 120)
      (push -1 x))
    (setf (aref x (sq "A8")) (- *CFLAGS* *BQF*))
    (setf (aref x (sq "H8")) (- *CFLAGS* *BKF*))
    (setf (aref x (sq "E8")) (- *CFLAGS* *BQF* *BKF*))
    (setf (aref x (sq "A1")) (- *CFLAGS* *WQF*))
    (setf (aref x (sq "H1")) (- *CFLAGS* *WKF*))
    (setf (aref x (sq "E1")) (- *CFLAGS* *WQF* *WKF*))
    x))

(defvar *ROOK-DIR* (list 1 -1 10 -10))
(defvar *KNIGHT-DIR* (list 8 -8 12 -12 19 -19 21 -21))
(defvar *BISHOP-DIR* (list 9 -9 11 -11))
(defvar *QUEEN-DIR* (append *ROOK-DIR* *BISHOP-DIR*))
(defvar *KING-DIR* *QUEEN-DIR*)

;; The chessboard
(defvar *sq*)
(defvar *color*)
(defvar *ep-square*)
(defvar *flags*)
(defvar *history*)

;; [x] -> (aref *sq* x)
;; [+ x 1] -> (aref *sq* (+ x 1))
(setf (reader "[")
      (lambda (src)
        (funcall src 1)
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
        (color *WHITE*)
        (flags 0)
        (epsq 0))
    (do ((y 0)
         (x 0))
        ((and (= y 7) (= x 8)))
      (let ((c (aref fen (1- (incf i)))))
        (cond
          ((<= "1" c "8")
           (incf x (parse-value c))
           (unless (<= x 8) (error "Invalid FEN string")))
          ((find c "prnbqkPRNBQK")
           (unless (< x 8) (error "Invalid FEN string"))
           (setf (aref sq (tosq y x))
                 (aref (list *BP* *BR* *BN* *BB* *BQ* *BK*
                             *WP* *WR* *WN* *WB* *WQ* *WK*)
                       (index c "prnbqkPRNBQK")))
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
       (setf color *WHITE*))
      ((= (aref fen i) "b")
       (setf color *BLACK*))
      (true (error "Invalid FEN string")))
    (incf i)
    (do () ((or (>= i (length fen))
                (/= (aref fen i) " ")))
      (incf i))
    (do () ((or (>= i (length fen))
                (= (aref fen i) " ")))
      (if (find (aref fen i) "QKqk-")
          (setf flags (logior flags
                              (aref (list *WQF* *WKF* *BQF* *BKF* 0)
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
            (= (aref fen (1+ i)) (if (= color *WHITE*) 6 3)))
       (setf epsq (tosq (if (= color *WHITE*) 2 5)
                        (index (aref fen i) "abcdefgh")))
       (incf i))
      (true (error "Invalid FEN string")))
    (setf *sq* sq)
    (setf *color* color)
    (setf *flags* flags)
    (setf *ep-square* epsq)
    (setf *history* (list))))

(defvar *pnames* (js-object (#.*WP* "P")
                            (#.*WR* "R")
                            (#.*WN* "N")
                            (#.*WB* "B")
                            (#.*WQ* "Q")
                            (#.*WK* "K")
                            (#.*BP* "p")
                            (#.*BR* "r")
                            (#.*BN* "n")
                            (#.*BB* "b")
                            (#.*BQ* "q")
                            (#.*BK* "k")))

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
      (when (and (= y 0) (= *BLACK* *color*))
        (setf res (+ res " *")))
      (when (and (= y 7) (= *WHITE* *color*))
        (setf res (+ res " *")))
      (setf res (+ res "\n")))
    (+ res "\n")))

(defstruct move
  x0 x1 np)

(defun move (x0 x1 &optional np)
  (make-move :x0 x0
             :x1 x1
             :np (or np [x0])))

(defun play (move)
  "Play a move on the chessboard"
  (let ((x0 (move-x0 move))
        (x1 (move-x1 move))
        (np (move-np move)))
    (push (list x0 x1 np [x0] [x1] *ep-square* *flags*)
          *history*)
    (setf [x1] np)
    (setf [x0] #.*EMPTY*)
    (setf *flags* (logand *flags*
                          (aref *UFLAGS* x0)
                          (aref *UFLAGS* x1)))
    (when (= x1 *ep-square*)
      (cond
        ((= np #.*WP*) (setf [- x1 10] #.*EMPTY*))
        ((= np #.*BP*) (setf [+ x1 10] #.*EMPTY*))))
    (when (= (logand np #.*PIECE*) #.*KING*)
      (cond
        ((= (- x1 x0) 2)
         (setf [1+ x0] [1+ x1])
         (setf [1+ x1] #.*EMPTY*))
        ((= (- x0 x1) 2)
         (setf [1- x0] [- x1 2])
         (setf [- x1 2] #.*EMPTY*))))
    (cond
      ((and (= np #.*WP*) (= (- x1 x0) -20))
       (setf *ep-square* (+ x1 10)))
      ((and (= np #.*BP*) (= (- x1 x0) 20))
       (setf *ep-square* (- x1 10)))
      (true
       (setf *ep-square* 0)))
    (setf *color* (logxor #.*COLOR* *color*))))

(defun undo ()
  "Undo last move on the chessboard"
  (dlet (x0 x1 np px0 px1 epsq flags) (pop *history*)
        (setf [x0] px0)
        (setf [x1] px1)
        (setf *ep-square* epsq)
        (setf *flags* flags)
        (setf *color* (logxor #.*COLOR* *color*))
        (when (= x1 epsq)
          (cond
            ((= np #.*WP*) (setf [- x1 10] #.*BP*))
            ((= np #.*BP*) (setf [+ x1 10] #.*WP*))))
        (when (= (logand np #.*PIECE*) #.*KING*)
          (cond
            ((= (- x1 x0) 2)
             (setf [1+ x1] [1+ x0])
             (setf [1+ x0] #.*EMPTY*))
            ((= (- x0 x1) 2)
             (setf [- x1 2] [1- x0])
             (setf [1- x0] #.*EMPTY*))))))

(defun attacks (x color)
  "True if square x is formally attacked by specified color"
  (let ((pdir (if (= color #.*WHITE*) -10 10))
        (p (+ color #.*PAWN*))
        (r (+ color #.*ROOK*))
        (n (+ color #.*KNIGHT*))
        (b (+ color #.*BISHOP*))
        (q (+ color #.*QUEEN*))
        (k (+ color #.*KING*)))
    #.`(or (= [+ x pdir -1] p)
           (= [+ x pdir 1] p)
           ,@(map (lambda (d) `(= [+ x ,d] n))
                  *KNIGHT-DIR*)
           ,@(map (lambda (d) `(= [+ x ,d] q))
                  *QUEEN-DIR*)
           ,@(map (lambda (d) `(= [+ x ,d] k))
                  *QUEEN-DIR*)
           ,@(map (lambda (d) `(= [+ x ,d] r))
                  *ROOK-DIR*)
           ,@(map (lambda (d) `(= [+ x ,d] b))
                  *BISHOP-DIR*)
           ,@(map (lambda (d)
                    (labels ((step (i f)
                               `(and (= [+ x ,(* i d)] #.*EMPTY*)
                                     (or (= [+ x ,(* (1+ i) d)] q)
                                         (= [+ x ,(* (1+ i) d)] ,f)
                                         ,@(if (< i 6)
                                               (list (step (1+ i) f))
                                               (list))))))
                      (step 1 (if (find d *ROOK-DIR*) 'r 'b))))
                  *QUEEN-DIR*))))

(defun check ()
  "True if player is currently under check"
  (attacks (index (+ *color* #.*KING*) *sq*) (logxor #.*COLOR* *color*)))

(defun pmove-map (f)
  "Calls the specified function passing all pseudo-legal moves"
  (let ((opponent (logxor #.*COLOR* *color*)))
    (when (/= *ep-square* 0)
      (when (= [+ *ep-square* (if (= *color* *WHITE*) 9 -9)] (+ *color* *PAWN*))
        (funcall f (move (+ *ep-square* (if (= *color* *WHITE*) 9 -9)) *ep-square*)))
      (when (= [+ *ep-square* (if (= *color* *WHITE*) 11 -11)] (+ *color* *PAWN*))
        (funcall f (move (+ *ep-square* (if (= *color* *WHITE*) 11 -11)) *ep-square*))))
    (dotimes (x 120)
      (let ((p (logxor [x] *color*)))
        (when (= 0 (logand p *COLOR*))
          (cond
            ((= [x] #.*WP*)
             (when (= (logand [- x 9] #.*COLOR*) #.*BLACK*)
               (funcall f (move x (- x 9))))
             (when (= (logand [- x 11] #.*COLOR*) #.*BLACK*)
               (funcall f (move x (- x 11))))
             (when (= [- x 10] #.*EMPTY*)
               (funcall f (move x (- x 10)))
               (when (and (= [- x 20] #.*EMPTY*)
                          (= [+ x 20] #.*OUT*))
                 (funcall f (move x (- x 20))))))

            ((= [x] #.*BP*)
             (when (= (logand [+ x 9] #.*COLOR*) #.*WHITE*)
               (funcall f (move x (+ x 9))))
             (when (= (logand [- x 11] #.*COLOR*) #.*WHITE*)
               (funcall f (move x (- x 11))))
             (when (= [+ x 10] #.*EMPTY*)
               (funcall f (move x (+ x 10)))
               (when (and (= [+ x 20] #.*EMPTY*)
                          (= [- x 20] #.*OUT*))
                 (funcall f (move x (+ x 20))))))

            ((= p #.*KNIGHT*)
             (dolist (d *KNIGHT-DIR*)
               (let ((y (+ x d)))
                 (when (or (= [y] #.*EMPTY*)
                           (= (logand [y] #.*COLOR*) opponent))
                   (funcall f (move x y))))))

            ((= p #.*ROOK*)
             (dolist (d *ROOK-DIR*)
               (do ((y (+ x d) (+ y d)))
                   ((/= [y] #.*EMPTY*)
                      (when (= (logand [y] #.*COLOR*) opponent)
                        (funcall f (move x y))))
                 (funcall f (move x y)))))

            ((= p #.*BISHOP*)
             (dolist (d *BISHOP-DIR*)
               (do ((y (+ x d) (+ y d)))
                   ((/= [y] #.*EMPTY*)
                      (when (= (logand [y] #.*COLOR*) opponent)
                        (funcall f (move x y))))
                 (funcall f (move x y)))))

            ((= p #.*QUEEN*)
             (dolist (d *QUEEN-DIR*)
               (do ((y (+ x d) (+ y d)))
                   ((/= [y] #.*EMPTY*)
                      (when (= (logand [y] #.*COLOR*) opponent)
                        (funcall f (move x y))))
                 (funcall f (move x y)))))

            ((= p #.*KING*)
             (dolist (d *QUEEN-DIR*)
               (let ((y (+ x d)))
                 (when (or (= [y] #.*EMPTY*)
                           (= (logand [y] #.*COLOR*) opponent))
                   (funcall f (move x y)))))
             (when (and (logand *flags* (if (= *color* *WHITE*) *WKF* *BKF*))
                        (= [+ x 1] 0)
                        (= [+ x 2] 0)
                        (not (check))
                        (not (attacks (+ x 1) opponent)))
               (funcall f (move x (+ x 2))))
             (when (and (logand *flags* (if (= *color* *WHITE*) *WQF* *BQF*))
                        (= [- x 1] 0)
                        (= [- x 2] 0)
                        (= [- x 3] 0)
                        (not (check))
                        (not (attacks (- x 1) opponent)))
               (funcall f (move x (- x 2)))))))))))

(defun move-map (f)
  "Calls the specified function with all legal moves"
  (pmove-map (lambda (m)
               (play m)
               (let ((x (attacks (index (logxor *color* *COLOR* *KING*) *sq*)
                                 *color*)))
                 (undo)
                 (unless x
                   (if (and (= (move-np m) (+ *color* #.*PAWN*))
                            (= [+ (move-x1 m) (if (= *color* #.*WHITE*) -10 10)] #.*OUT*))
                       (dolist (y '(#.*QUEEN* #.*KNIGHT* #.*ROOK* #.*BISHOP*))
                         (funcall f (move (move-x0 m) (move-x1 m) (+ *color* y))))
                       (funcall f m)))))))

(defmacro play-moves (&rest moves)
  `(progn ,@(map (lambda (m)
                   (if (= (length m) 3)
                       `(play (move ,(first m) ,(second m) ,(third m)))
                       `(play (move ,(first m) ,(second m)))))
                 moves)))

(defun perft (n)
  (if (= n 0)
      1
      (let ((count 0))
        (move-map (lambda (m)
                    (play m)
                    (incf count (perft (1- n)))
                    (undo)))
        count)))

(init-board "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq -")
(display (perft 1))
(display (perft 2))
