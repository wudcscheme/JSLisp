(defun random-color ()
  (let ((r (+ 128 (random-int 64)))
        (g (+ 128 (random-int 64)))
        (b (+ 128 (random-int 64))))
    ~"rgb({r},{g},{b})"))

(defmacro with-canvas (canvas &rest body)
  (let ((ctx (gensym)))
    `(let ((,ctx (funcall (. ,canvas getContext) "2d")))
       (macrolet ((,#"save" ()
                    `(funcall (. ,',ctx save)))
                  (,#"restore" ()
                    `(funcall (. ,',ctx restore)))
                  (,#"begin-path" ()
                    `(funcall (. ,',ctx beginPath)))
                  (,#"close-path" ()
                    `(funcall (. ,',ctx closePath)))
                  (,#"move-to" (x y)
                    `(funcall (. ,',ctx moveTo) ,x ,y))
                  (,#"line-to" (x y)
                    `(funcall (. ,',ctx lineTo) ,x ,y))
                  (,#"bez2-to" (x1 y1 x2 y2)
                    `(funcall (. ,',ctx quadraticCurveTo) ,x1 ,y1 ,x2 ,y2))
                  (,#"bez3-to" (x1 y1 x2 y2 x3 y3)
                    `(funcall (. ,',ctx bezierCurveTo) ,x1 ,y1 ,x2 ,y2 ,x3 ,y3))
                  (,#"fill-style" (x)
                    `(setf (. ,',ctx fillStyle) ,x))
                  (,#"stroke-style" (x)
                    `(setf (. ,',ctx strokeStyle) ,x))
                  (,#"line-width" (x)
                    `(setf (. ,',ctx lineWidth) ,x))
                  (,#"fill" ()
                    `(funcall (. ,',ctx fill)))
                  (,#"stroke" ()
                    `(funcall (. ,',ctx stroke)))
                  (,#"shadow" (color dx dy blur)
                    `(progn
                       (setf (. ,',ctx shadowColor) ,color)
                       (setf (. ,',ctx shadowOffsetX) ,dx)
                       (setf (. ,',ctx shadowOffsetY) ,dy)
                       (setf (. ,',ctx shadowBlur) ,blur)))
                  (,#"font" (x)
                    `(setf (. ,',ctx font) ,x))
                  (,#"text-width" (x)
                    `(. (funcall (. ,',ctx measureText) ,x) width))
                  (,#"fill-text" (text x y)
                    `(funcall (. ,',ctx fillText) ,text ,x ,y))
                  (,#"stroke-text" (text x y)
                    `(funcall (. ,',ctx strokeText) ,text ,x ,y))
                  (,#"arc" (x y r start-angle end-angle ccw)
                    `(funcall (. ,',ctx arc) ,x ,y ,r ,start-angle ,end-angle ,ccw))
                  (,#"line" (x0 y0 x1 y1)
                    `(progn
                       (,#"begin-path")
                       (,#"move-to" ,x0 ,y0)
                       (,#"line-to" ,x1 ,y1)
                       (,#"stroke")))
                  (,#"circle" (x y r)
                    `(progn
                       (,#"begin-path")
                       (,#"arc" ,x ,y ,r 0 (* 2 pi) false)))
                  (,#"rect" (x0 y0 w h)
                    (let ((xa '#.(gensym))
                          (ya '#.(gensym))
                          (xb '#.(gensym))
                          (yb '#.(gensym)))
                      `(let* ((,xa ,x0)
                              (,ya ,y0)
                              (,xb (+ ,xa ,w))
                              (,yb (+ ,ya ,h)))
                         (,#"begin-path")
                         (,#"move-to" ,xa ,ya)
                         (,#"line-to" ,xb ,ya)
                         (,#"line-to" ,xb ,yb)
                         (,#"line-to" ,xa ,yb)
                         (,#"close-path"))))
                  (,#"image-smoothing" (x)
                    `(setf (. ,',ctx imageSmoothingEnabled) ,x))
                  (,#"image" (src x y &optional w h sx sy sw sh)
                    (cond
                      ((undefined? w)
                       `(funcall (. ,',ctx drawImage) ,src ,x ,y))
                      ((undefined? sx)
                       `(funcall (. ,',ctx drawImage) ,src ,x ,y ,w ,h))
                      (true
                       `(funcall (. ,',ctx drawImage) ,src ,sx ,sy ,sw ,sh ,x ,y ,w ,h)))))
         ,@body))))

(export random-color
        with-canvas)
