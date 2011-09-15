(defun v (&rest coords) coords)

(defun x (p) (first p))
(defun y (p) (second p))
(defun z (p) (third p))

(defun v+ (&rest pts)
  (reduce (lambda (a b) (mapn #'+ a b)) pts))

(defun v- (&rest pts)
  (reduce (lambda (a b) (mapn #'- a b)) pts))

(defun v* (v k)
  (map (lambda (x) (* x k)) v))

(defun v/ (v k)
  (map (lambda (x) (/ x k)) v))

(defun v. (a b)
  (reduce #'+ (mapn #'* a b)))

(defun vlen (x)
  (sqrt (v. x x)))

(defun vdir (x)
  (v/ x (vlen x)))

(defun v^ (a b)
  (v (- (* (y a) (z b)) (* (z a) (y b)))
     (- (* (z a) (x b)) (* (x a) (z b)))
     (- (* (x a) (y b)) (* (y a) (x b)))))

(defun camera (from to up dist)
  (let* ((n (vdir (v- to from)))
         (u (v* (vdir (v^ up n)) dist))
         (v (v^ n u)))
    (lambda (p)
      (let* ((x (v- p from))
             (z (v. x n))
             (zs (/ z))
             (xs (* (v. x u) zs))
             (ys (* (v. x v) zs)))
        (v xs ys zs)))))

(defun invcamera (from to up dist)
  (let* ((n (vdir (v- to from)))
         (u (vdir (v^ up n)))
         (v (v^ n u)))
    (lambda (xs ys)
      (v+ from
          (v* u xs)
          (v* v ys)
          (v* n dist)))))

(load (http-get "gui.lisp"))

(defvar *faces* (list))

(dolist (i '(-1 0 1))
  (dolist (j '(-1 0 1))
    (push (list "#0000FF"
                (v (- i 0.5) (- j 0.5) -1.5)
                (v (+ i 0.5) (- j 0.5) -1.5)
                (v (+ i 0.5) (+ j 0.5) -1.5)
                (v (- i 0.5) (+ j 0.5) -1.5)) *faces*)

    (push (list "#FFFF00"
                (v (- i 0.5) (- j 0.5) 1.5)
                (v (+ i 0.5) (- j 0.5) 1.5)
                (v (+ i 0.5) (+ j 0.5) 1.5)
                (v (- i 0.5) (+ j 0.5) 1.5)) *faces*)

    (push (list "#00FF00"
                (v (- i 0.5) -1.5 (- j 0.5))
                (v (+ i 0.5) -1.5 (- j 0.5))
                (v (+ i 0.5) -1.5 (+ j 0.5))
                (v (- i 0.5) -1.5 (+ j 0.5))) *faces*)

    (push (list "#FF00FF"
                (v (- i 0.5) 1.5 (- j 0.5))
                (v (+ i 0.5) 1.5 (- j 0.5))
                (v (+ i 0.5) 1.5 (+ j 0.5))
                (v (- i 0.5) 1.5 (+ j 0.5))) *faces*)

    (push (list "#FF0000"
                (v -1.5 (- i 0.5) (- j 0.5))
                (v -1.5 (+ i 0.5) (- j 0.5))
                (v -1.5 (+ i 0.5) (+ j 0.5))
                (v -1.5 (- i 0.5) (+ j 0.5))) *faces*)

    (push (list "#00FFFF"
                (v 1.5 (- i 0.5) (- j 0.5))
                (v 1.5 (+ i 0.5) (- j 0.5))
                (v 1.5 (+ i 0.5) (+ j 0.5))
                (v 1.5 (- i 0.5) (+ j 0.5))) *faces*)))

(let* ((canvas (create-element "canvas"))
       (layout (:Hdiv canvas))
       (cb null)
       (frame (window 100 100 200 300
                      :title "3d view"
                      :close (lambda () (clear-interval cb))
                      :layout layout))
       (from (v -400 -600 -1000))
       (redraw (lambda ()
                 (let* ((ctx (funcall (. canvas getContext) "2d"))
                        (cam (camera from (v 0 0 0) (v 0 1 0) 800))
                        (w (. canvas width))
                        (h (. canvas height))
                        (zx (/ w 2))
                        (zy (/ h 2)))
                   (setf (. ctx fillStyle) "#808080")
                   (funcall (. ctx fillRect) 0 0 w h)
                   (setf (. ctx strokeStyle) "#000000")
                   (setf (. ctx lineWidth) 1)
                   (let ((xfaces (map (lambda (f)
                                        (let ((xp (map (lambda (p) (funcall cam (v* p 100)))
                                                       (slice f 1))))
                                          (list (max (map #'z xp))
                                                (first f)
                                                xp)))
                                      *faces*)))
                     (nsort xfaces (lambda (a b) (< (first a) (first b))))
                     (dolist (xf xfaces)
                       (setf (. ctx fillStyle) (second xf))
                       (funcall (. ctx beginPath))
                       (let ((pts (third xf)))
                         (funcall (. ctx moveTo)
                                  (+ zx (x (first pts)))
                                  (+ zy (y (first pts))))
                         (dolist (p (slice pts 1))
                           (funcall (. ctx lineTo)
                                    (+ zx (x p))
                                    (+ zy (y p))))
                         (funcall (. ctx closePath))
                         (funcall (. ctx fill))
                         (funcall (. ctx stroke)))))))))

  (append-child frame canvas)

  (setf cb (set-interval (lambda ()
                           (let ((w (. canvas offsetWidth))
                                 (h (. canvas offsetHeight)))
                             (when (or (/= w (. canvas width))
                                       (/= h (. canvas height)))
                               (setf (. canvas width) w)
                               (setf (. canvas height) h)
                               (funcall redraw))))
                         100))

  (set-handler canvas onmousedown
               (funcall (. event preventDefault))
               (funcall (. event stopPropagation))
               (let ((x0 (. event clientX))
                     (y0 (. event clientY)))
                 (tracking (lambda (x y)
                             (let* ((dx (- x x0))
                                    (dy (- y y0))
                                    (icam (invcamera from (v 0 0 0) (v 0 1 0) 800))
                                    (p1 (funcall icam 0 0))
                                    (p2 (funcall icam dx dy)))
                               (setf from
                                     (v* (vdir (v+ from (v* (v- p1 p2) 4)))
                                         (vlen from)))
                               (funcall redraw)
                               (setf x0 x)
                               (setf y0 y))))))

  (set-coords layout 0 20 200 300)

  (show frame))