(import * from gui)
(import * from graphics)
(import * from layout)

(defconstant PIXEL-SCALE 16)
(defconstant WORLD-SIZE 32)
(defconstant FULLSIZE (* PIXEL-SCALE WORLD-SIZE))
(defconstant WALL 0)
(defconstant FREE 1)
(defconstant PAINT 2)
(defconstant SEED 3)

(defun frontier-filler (x y get set)
  (let ((current-active (list (list x y)))
        (next-active (list))
        (phase :run:)
        (i 0))
    (funcall set x y PAINT)
    (labels ((to-paint (x y)
               (and (< -1 x WORLD-SIZE)
                    (< -1 y WORLD-SIZE)
                    (not (find (funcall get x y) (list WALL SEED PAINT))))))
      (lambda ()
        (ecase phase
          (:stop:)
          (:run:
             (let (((x y) (aref current-active i)))
               (funcall set x y PAINT)
               (dolist ((xx yy) (list (list (1- x) y)
                                      (list (1+ x) y)
                                      (list x (1- y))
                                      (list x (1+ y))))
                 (when (to-paint xx yy)
                   (funcall set xx yy SEED)
                   (push (list xx yy) next-active))))
             (incf i)
             (when (>= i (length current-active))
               (setf current-active next-active)
               (setf next-active (list))
               (setf i 0)
               (when (= 0 (length current-active))
                 (setf phase :stop:)))))
        (/= phase :stop:)))))

(defun scanline-filler (x y get set)
  (let ((todo (list (list x y)))
        (phase :start:)
        (look-above false)
        (look-below false))
    (labels ((to-paint (x y)
               (and (< -1 x WORLD-SIZE)
                    (< -1 y WORLD-SIZE)
                    (not (find (funcall get x y) (list WALL PAINT))))))
      (lambda ()
        (ecase phase
          (:stop:)
          (:start:
             (if (= (length todo) 0)
                 (setf phase :stop:)
                 (let (((xx yy) (pop todo)))
                   (when (to-paint xx yy)
                     (setf x xx)
                     (setf y yy)
                     (setf phase :left:)))))
          (:left:
             (if (to-paint (1- x) y)
                 (decf x)
                 (progn
                   (setf phase :right:)
                   (setf look-above true)
                   (setf look-below true))))
          (:right:
             (when (> y 0)
               (let ((above-free (to-paint x (1- y))))
                 (cond
                   ((and look-above above-free)
                    (push (list x (1- y)) todo)
                    (funcall set x (1- y) SEED)
                    (setf look-above false))
                   ((and (not look-above) (not above-free))
                    (setf look-above true)))))
             (when (< y (1- WORLD-SIZE))
               (let ((below-free (to-paint x (1+ y))))
                 (cond
                   ((and look-below below-free)
                    (push (list x (1+ y)) todo)
                    (funcall set x (1+ y) SEED)
                    (setf look-below false))
                   ((and (not look-below) (not below-free))
                    (setf look-below true)))))
             (funcall set x y PAINT)
             (incf x)
             (unless (to-paint x y)
               (setf phase :start:))))
        (/= phase :stop:)))))

(defun fill-window ()
  (macrolet ((set-all (color)
               `(dotimes (y WORLD-SIZE)
                  (dotimes (x WORLD-SIZE)
                    (set x y ,color))))
             (aw (&rest x) `(add-widget w (,@x))))
    (let** ((w (window 0 0 (+ FULLSIZE 16)(+ FULLSIZE 16 40)
                       resize: false title: "Flood fill"))
            (canvas (aw set-style (create-element "canvas")
                        position "absolute"
                        px/width FULLSIZE
                        px/height FULLSIZE))
            (world (make-array (list WORLD-SIZE WORLD-SIZE) FREE))
            (clear (aw lbutton "clear" (set-all FREE)))
            (random (aw lbutton "random" (set-all (if (random-int 4) FREE WALL))))
            (draw (aw lbutton "draw" (set-mode :draw:)))
            (ffill (aw lbutton "f-fill" (set-mode :ffill:)))
            (sfill (aw lbutton "s-fill" (set-mode :sfill:)))
            (mode :draw:)
            (#'get (x y)
                   (aref world y x))
            (#'dot (x y color)
                   (with-canvas canvas
                     (fill-style (ecase color
                                   (FREE  "#FFFFFF")
                                   (WALL  "#888888")
                                   (PAINT "#FF0000")
                                   (SEED  "#00FF00")))
                     (fill-rect (* x PIXEL-SCALE) (* y PIXEL-SCALE)
                                PIXEL-SCALE PIXEL-SCALE)))
            (#'set (x y color)
                   (setf (aref world y x) color)
                   (dot x y color))
            (#'repaint ()
                       (setf canvas.width FULLSIZE)
                       (setf canvas.height FULLSIZE)
                       (set-all (get x y)))
            (#'set-mode (m)
                        (setf mode m)
                        (set-all (if (= (get x y) WALL) WALL FREE))))
      (set-handler canvas onmousedown
        (event.stopPropagation)
        (event.preventDefault)
        (macrolet ((px (y x)
                     `(aref world
                            (floor (/ ,y PIXEL-SCALE))
                            (floor (/ ,x PIXEL-SCALE)))))
          (let (((x y) (relative-pos event canvas)))
            (if (= mode :draw:)
                (let ((color (if (= WALL (px y x)) FREE WALL)))
                  (setf (px y x) color)
                  (repaint)
                  (tracking (lambda (x y)
                              (let (((cx cy) (element-pos canvas)))
                                (decf x cx)
                                (decf y cy)
                                (setf (px y x) color))
                              (repaint))))
                (when (= (px y x) FREE)
                  (let** ((f (funcall (if (= mode :ffill:)
                                          #'frontier-filler
                                          #'scanline-filler)
                                      (floor (/ x PIXEL-SCALE))
                                      (floor (/ y PIXEL-SCALE))
                                      #'get #'set))
                          (id (set-interval (lambda ()
                                              (unless (funcall f)
                                                (clear-interval id)))
                                            10)))))))))
      (setf canvas."data-resize" #'repaint)
      (set-layout w (V spacing: 8 border: 8
                       (dom canvas)
                       size: 30
                       (H :filler:
                          size: 80
                          (dom clear)
                          (dom random)
                          (dom draw)
                          (dom sfill)
                          (dom ffill)
                          :filler:)))
      (show-window w center: true))))

(defun main ()
  (fill-window))

(main)