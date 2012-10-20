
(defun hline (data x0 x1 y r g b a)
  "Draws an horizontal line on canvas image [data] from [x0] to [x1] at height [y] with color [r g b a]"
  (let ((width (. data width))
        (pixels (. data data)))
    (do ((p (* (+ (* y width) x0) 4) (+ p 4))
         (count (- x1 x0) (1- count)))
        ((= count 0))
      (setf (aref pixels p)       r)
      (setf (aref pixels (+ p 1)) g)
      (setf (aref pixels (+ p 2)) b)
      (setf (aref pixels (+ p 3)) a))))

(defun box (data x0 y0 x1 y1 color)
  "Fills a box on canvas image [data] from [x0 y0] to [x1 y1] with [color]"
  (let ((width (. data width))
        (height (. data height)))
    (when (< x0 0) (setf x0 0))
    (when (> x1 width) (setf x1 width))
    (when (< y0 0) (setf y0 0))
    (when (> y1 height) (setf y1 height))
    (when (< x0 x1)
      (do ((y y0 (1+ y))
           (r (first color))
           (g (second color))
           (b (third color))
           (a (fourth color)))
          ((>= y y1))
        (hline data x0 x1 y r g b a)))))

(defun clear (data color)
  "Clears the whole canvas image [data] with specified [color]"
  (box data 0 0 (. data width) (. data height) color))

(defun frame (data x0 y0 x1 y1 pw ph color)
  "Draws a rectangular frame with specified pen size [pw ph] and [color]"
  (if (or (>= (+ x0 pw) (- x1 pw))
          (>= (+ y0 ph) (- y1 ph)))
      (box data x0 y0 x1 y1 color)
      (progn
        (box data x0 y0 x1 (+ y0 ph) color)
        (box data x0 (+ y0 ph) (+ x0 pw) (- y1 ph) color)
        (box data (- x1 pw) (+ y0 ph) x1 (- y1 ph) color)
        (box data x0 (- y1 ph) x1 y1 color))))

(defun line (data x0 y0 x1 y1 pw ph color)
  "Draws a line from [x0 y0] to [x1 y1] with specified pen size [pw ph] and [color]"
  (let ((width (. data width))
        (height (. data height)))
    (if (or (> pw 1) (> ph 1))
          ;; "Fat" line
          (let ((xa (max 0 (min x0 x1)))
                (xb (min width (+ pw (max x0 x1)))))
            (when (> y0 y1)
              (swap y0 y1)
              (swap x0 x1))
            (if (or (= x0 x1) (= y0 y1))
                (box data xa y0 xb (+ y1 ph) color)
                (let* ((k (/ (- x1 x0) (- y1 y0)))
                       (dx (abs (* ph k))))
                  (do ((r (first color))
                       (g (second color))
                       (b (third color))
                       (a (fourth color))
                       (y y0 (1+ y))
                       (yend (+ y1 ph))
                       (left (+ (/ k 2) 0.5 (if (< x0 x1) (- x0 dx) x0)) (+ left k))
                       (right (+ (/ k 2) 0.5 (if (< x0 x1) (+ x0 pw) (+ x0 pw dx))) (+ right k)))
                      ((>= y yend))
                    (let ((x0 (max (floor left) xa))
                          (x1 (min (floor right) xb)))
                      (when (< x0 x1)
                        (hline data x0 x1 y r g b a)))))))
        ;; "Thin" line (DDA)
        (let* ((ix (if (< x0 x1) 1 -1))
               (ix4 (* ix 4))
               (dx (abs (- x1 x0)))
               (iy (if (< y0 y1) 1 -1))
               (iyw (* iy width 4))
               (dy (abs (- y1 y0)))
               (m (max dx dy))
               (cx (ash m -1))
               (cy cx)
               (r (first color))
               (g (second color))
               (b (third color))
               (a (fourth color))
               (dst (. data data))
               (p (* (+ (* y0 width) x0) 4)))
          (repeat (1+ m)
            (when (and (<= 0 x0 (1- width))
                       (<= 0 y0 (1- height)))
              (setf (aref dst p) r)
              (setf (aref dst (+ p 1)) g)
              (setf (aref dst (+ p 2)) b)
              (setf (aref dst (+ p 3)) a))
            (when (>= (incf cx dx) m)
              (decf cx m)
              (incf x0 ix)
              (incf p ix4))
            (when (>= (incf cy dy) m)
              (decf cy m)
              (incf y0 iy)
              (incf p iyw)))))))

(defun bezier (data p0 p1 p2 p3 pw ph color)
  "Draws a cubic Bezier arc from [p0] to [p3] using [p1 p2] as control points"
  (let* ((hw (ash pw -1))
         (hh (ash ph -1)))
    (labels ((avg (a b)
               (list (/ (+ (first a) (first b)) 2)
                     (/ (+ (second a) (second b)) 2)))
             (bezdraw (a b c d levels)
               (if (= levels 0)
                   (line data
                         (floor (- (first a) hw)) (floor (- (second a) hh))
                         (floor (- (first d) hw)) (floor (- (second d) hh))
                         pw ph
                         color)
                   (let* ((ab (avg a b))
                          (bc (avg b c))
                          (cd (avg c d))
                          (abc (avg ab bc))
                          (bcd (avg bc cd))
                          (abcd (avg abc bcd)))
                     (bezdraw a ab abc abcd (1- levels))
                     (bezdraw abcd bcd cd d (1- levels))))))
      (bezdraw p0 p1 p2 p3 4))))

(defun ellipse (data x0 y0 x1 y1 color)
  "Fills an ellipse from [x0 y0] to [x1 y1] with specified [color]"
  (let ((x0 (min x0 x1))
        (y0 (min y0 y1))
        (x1 (max x0 x1))
        (y1 (max y0 y1)))
    (when (and (< x0 x1) (< y0 y1))
      (let ((width (. data width))
            (height (. data height))
            (r (first color))
            (g (second color))
            (b (third color))
            (a (fourth color)))
        (let ((cx (/ (+ x0 x1) 2))
              (cy (/ (+ y0 y1) 2))
              (ya (max 0 y0))
              (yb (min height y1))
              (r2 (* (- y1 y0) (- y1 y0) 0.25))
              (ratio (/ (- x1 x0) (- y1 y0))))
          (do ((y ya (1+ y)))
              ((= y yb))
            (let* ((dy (- (+ y 0.5) cy))
                   (dx (* ratio (sqrt (- r2 (* dy dy)))))
                   (xa (max 0 (floor (- cx dx -0.5))))
                   (xb (min width (floor (+ cx dx 0.5)))))
              (when (< xa xb)
                (hline data xa xb y r g b a)))))))))

(defun ellipse-frame (data x0 y0 x1 y1 pw ph color)
  "Draws an ellipse from [x0 y0] to [x1 y1] with specified [color] and [pw ph] pen size"
  (let ((x0 (min x0 x1))
        (y0 (min y0 y1))
        (x1 (max x0 x1))
        (y1 (max y0 y1)))
    (when (and (< x0 x1) (< y0 y1))
      (if (or (>= (+ x0 pw) (- x1 pw))
              (>= (+ y0 ph) (- y1 ph)))
          (ellipse data x0 y0 x1 y1 color)
          (let ((width (. data width))
                (height (. data height))
                (r (first color))
                (g (second color))
                (b (third color))
                (a (fourth color)))
            (if (or (/= pw 1) (/= ph 1))
                ;; Fat ellipse
                (let ((cx (/ (+ x0 x1) 2))
                      (cy (/ (+ y0 y1) 2))
                      (ya (max 0 y0))
                      (yb (min height y1))
                      (rad (* (- y1 y0) (- y1 y0) 0.25))
                      (ratio (/ (- x1 x0) (- y1 y0)))
                      (rad2 (* (- y1 y0 ph ph) (- y1 y0 ph ph) 0.25))
                      (ratio2 (/ (- x1 x0 pw pw) (- y1 y0 ph ph))))
                  (do ((y ya (1+ y)))
                      ((= y yb))
                    (let* ((dy (- (+ y 0.5) cy))
                           (dx (* ratio (sqrt (- rad (* dy dy)))))
                           (xa (max 0 (floor (- cx dx -0.5))))
                           (xb (min width (floor (+ cx dx 0.5))))
                           (delta (- rad2 (* dy dy))))
                      (if (<= delta 0)
                          (when (< xa xb)
                            (hline data xa xb y r g b a))
                          (let* ((dx2 (* ratio2 (sqrt delta)))
                                 (xa2 (max 0 (floor (- cx dx2 -0.5))))
                                 (xb2 (min width (floor (+ cx dx2 0.5)))))
                            (when (< xa xa2)
                              (hline data xa xa2 y r g b a))
                            (when (< xb2 xb)
                              (hline data xb2 xb y r g b a)))))))
                ;; Thin ellipse Bresenham-like
                (let* ((cx (/ (+ x0 x1) 2))
                       (cy (/ (+ y0 y1) 2))
                       (x (- (+ 0.5 (floor (/ (+ x0 x1) 2))) cx))
                       (y (- cy (+ 0.5 y0)))
                       (ratio (/ (- y1 y0) (- x1 x0)))
                       (k (* ratio ratio))
                       (err (* x x))
                       (dest (. data data)))
                  (labels ((pix (x y)
                             (when (and (<= 0 x (1- width))
                                        (<= 0 y (1- height)))
                               (let ((i (ash (+ (* y width) x) 2)))
                                 (setf (aref dest i) r)
                                 (setf (aref dest (+ i 1)) g)
                                 (setf (aref dest (+ i 2)) b)
                                 (setf (aref dest (+ i 3)) a))))
                           (pix4 ()
                             (let ((xa (logior (+ cx x) 0))
                                   (xb (logior (- cx x) 0))
                                   (ya (logior (+ cy y) 0))
                                   (yb (logior (- cy y) 0)))
                               (pix xa ya)
                               (pix xa yb)
                               (pix xb ya)
                               (pix xb yb))))
                    (do () ((<= y 0) (pix4))
                      (pix4)
                      (let* ((err1 (+ err (* k (+ x x 1))))
                             (err2 (+ err (* k (+ x x 1)) (- 1 y y)))
                             (err3 (+ err (- 1 y y)))
                             (aerr1 (abs err1))
                             (aerr2 (abs err2))
                             (aerr3 (abs err3)))
                        (cond
                          ((<= aerr3 (min aerr1 aerr2))
                           (decf y)
                           (setf err err3))
                          ((<= aerr2 (min aerr1 aerr3))
                           (incf x)
                           (decf y)
                           (setf err err2))
                          (true
                           (incf x)
                           (setf err err1)))))))))))))

(defun byte-array (n)
  "Creates an byte array of size [n]"
  (declare (ignorable n))
  (js-code "(new Uint8Array(d$$n))"))

(defun fill (data x y color)
  "Flood-fills with [color] starting from specified [x y] starting point"
  (let* ((width (. data width))
         (height (. data height))
         (dst (. data data))
         (i0 (ash (+ (* y width) x) 2))
         (tr (aref dst i0))
         (tg (aref dst (+ i0 1)))
         (tb (aref dst (+ i0 2)))
         (ta (aref dst (+ i0 3)))
         (r (first color))
         (g (second color))
         (b (third color))
         (a (fourth color))
         (src (byte-array (* width height))))

    ;; Compute fillable areas
    (let ((rp 0))
      (dotimes (i (* width height))
        (setf (aref src i)
              (if (and (= (aref dst (+ rp 0)) tr)
                       (= (aref dst (+ rp 1)) tg)
                       (= (aref dst (+ rp 2)) tb)
                       (= (aref dst (+ rp 3)) ta))
                  1 0))
        (incf rp 4)))
    (do ((todo (list (list x y))))
        ((= 0 (length todo)))
      (let* ((p (pop todo))
             (x (first p))
             (y (second p))
             (i (+ (* y width) x)))
        (when (aref src i)
          ;; Move to left if you can
          (do () ((or (= x 0) (not (aref src (1- i)))))
            (decf x)
            (decf i))
          ;; Horizontal line fill
          (do ((look-above true)
               (look-below true))
              ((or (= x width) (not (aref src i))))

            ;; Check for holes above
            (when (> y 0)
              (if look-above
                  (when (aref src (- i width))
                    (push (list x (1- y)) todo)
                    (setf look-above false))
                  (unless (aref src (- i width))
                    (setf look-above true))))

            ;; Check for holes below
            (when (< y (1- height))
              (if look-below
                  (when (aref src (+ i width))
                    (push (list x (1+ y)) todo)
                    (setf look-below false))
                  (unless (aref src (+ i width))
                    (setf look-below true))))

            ;; Paint the pixel
            (let ((i4 (* i 4)))
              (setf (aref dst i4) r)
              (setf (aref dst (+ i4 1)) g)
              (setf (aref dst (+ i4 2)) b)
              (setf (aref dst (+ i4 3)) a))

            ;; Ensure this will not be painted again
            (setf (aref src i) 0)

            ;; Move to next pixel
            (incf x)
            (incf i)))))))

(export hline box clear frame line bezier ellipse ellipse-frame fill)
