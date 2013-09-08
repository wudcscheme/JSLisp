(import * from gui)
(import * from layout)

(defun edit-hv-node (n cback)
  (let** ((w (window 0 0 370 200 title: "Layout node"))
          (min (add-widget w (input "minimum size" autofocus: true)))
          (max (add-widget w (input "maximum size")))
          (class (add-widget w (input "class")))
          (weight (add-widget w (input "weight")))
          (ok (add-widget w (button "OK" #'ok)))
          (cancel (add-widget w (button "Cancel" #'cancel)))
          (#'cancel () (hide-window w))
          (#'ok ()
            (setf n.min (or (atoi (text min)) undefined))
            (setf n.max (or (atoi (text max)) infinity))
            (setf n.class (or (atoi (text class)) 1))
            (setf n.weight (or (atoi (text weight)) 100))
            (hide-window w)
            (funcall cback)))
    (set-layout w (V border: 8 spacing: 8
                     size: 40
                     (H (dom min) (dom max))
                     (H (dom class) (dom weight))
                     :filler:
                     size: 30
                     (H :filler:
                        size: 80
                        (dom ok) (dom cancel)
                        :filler:)))
    (setf (text min) (or n.min ""))
    (setf (text max) (or n.max ""))
    (setf (text class) n.class)
    (setf (text weight) n.weight)
    (show-window w modal: true center: true)))

(defun layout-edit (n hv-node cback)
  (let** ((w (window 0 0 370 200 title: "Layout group edit"))
          (border (add-widget w (input "border" autofocus: true)))
          (spacing (add-widget w (input "spacing")))
          (editnode (add-widget w (button "Layout" #'layout)))
          (delete (add-widget w (button "Delete" #'delete)))
          (ok (add-widget w (button "OK" #'ok)))
          (cancel (add-widget w (button "Cancel" #'cancel)))
          (#'layout () (edit-hv-node hv-node (lambda ())))
          (#'delete () (baloon "To do"))
          (#'cancel () (hide-window w))
          (#'ok ()
            (setf n.border (or (atoi (text border)) undefined))
            (setf n.spacing (or (atoi (text spacing)) undefined))
            (hide-window w)
            (funcall cback)))
    (setf (text border) n.border)
    (setf (text spacing) n.spacing)
    (unless hv-node (setf editnode.disabled "disabled"))
    (set-layout w (V border: 8 spacing: 8
                     size: 40
                     (H (dom border) (dom spacing))
                     :filler:
                     size: 30
                     (H :filler:
                        size: 80
                        (dom editnode) (dom delete) (dom ok) (dom cancel)
                        :filler:)))
    (show-window w modal: true center: true)))

(defun button-edit (b hv-node cback)
  (let** ((w (window 0 0 300 230 title: "Button properties"))
          (name (add-widget w (input "name" autofocus: true)))
          (caption (add-widget w (input "caption")))
          (default-button (add-widget w (checkbox "Default (Enter)")))
          (cancel-button (add-widget w (checkbox "Cancel (ESC)")))
          (editnode (add-widget w (button "Layout" #'layout)))
          (ok (add-widget w (button "OK" #'ok)))
          (cancel (add-widget w (button "Cancel" #'cancel)))
          (#'layout () (edit-hv-node hv-node (lambda ())))
          (#'cancel () (hide-window w))
          (#'ok ()
            (setf b.data-name (text name))
            (setf (caption b) (text caption))
            (setf b.default (checked default-button))
            (setf b.cancel (checked cancel-button))
            (hide-window w)
            (funcall cback)))
    (setf (text caption) (caption b))
    (setf (text name) (or b.data-name ""))
    (setf (checked default-button) b.default)
    (setf (checked cancel-button) b.cancel)
    (unless hv-node (setf editnode.disabled "disabled"))
    (set-layout w (V border: 8 spacing: 8
                     size: 40
                     (dom name)
                     (dom caption)
                     size: 30
                     (H (dom default-button) (dom cancel-button))
                     :filler:
                     size: 30
                     (H :filler: size: 80
                        (dom editnode) (dom ok) (dom cancel)
                        :filler:)))
    (show-window w center: true modal: true)))

(defun input-edit (b hv-node cback)
  (let** ((w (window 0 0 300 230 title: "Input properties"))
          (name (add-widget w (input "name" autofocus: true)))
          (caption (add-widget w (input "caption")))
          (autofocus (add-widget w (checkbox "Autofocus")))
          (autoselect (add-widget w (checkbox "Autoselect")))
          (editnode (add-widget w (button "Layout" #'layout)))
          (ok (add-widget w (button "OK" #'ok)))
          (cancel (add-widget w (button "Cancel" #'cancel)))
          (#'layout () (edit-hv-node hv-node (lambda ())))
          (#'cancel () (hide-window w))
          (#'ok ()
            (setf b.data-name (text name))
            (setf (caption b) (text caption))
            (setf b.autofocus (checked autofocus))
            (setf b.autoselect (checked autoselect))
            (hide-window w)
            (funcall cback)))
    (setf (text caption) (caption b))
    (setf (text name) (or b.data-name ""))
    (setf (checked autofocus) (or b.autofocus false))
    (setf (checked autoselect) (or b.autoselect false))
    (unless hv-node (setf editnode.disabled "disabled"))
    (set-layout w (V border: 8 spacing: 8
                     size: 40
                     (dom name)
                     (dom caption)
                     size: 30
                     (H (dom autofocus) (dom autoselect))
                     :filler:
                     size: 30
                     (H :filler: size: 80
                        (dom editnode) (dom ok) (dom cancel)
                        :filler:)))
    (show-window w center: true modal: true)))

(defun checkbox-edit (b hv-node cback)
  (let** ((w (window 0 0 300 200 title: "Checkbox properties"))
          (name (add-widget w (input "name" autofocus: true)))
          (caption (add-widget w (input "caption")))
          (editnode (add-widget w (button "Layout" #'layout)))
          (ok (add-widget w (button "OK" #'ok)))
          (cancel (add-widget w (button "Cancel" #'cancel)))
          (#'layout () (edit-hv-node hv-node (lambda ())))
          (#'cancel () (hide-window w))
          (#'ok ()
            (setf b.data-name (text name))
            (setf (caption b) (text caption))
            (hide-window w)
            (funcall cback)))
    (setf (text caption) (caption b))
    (setf (text name) (or b.data-name ""))
    (unless hv-node (setf editnode.disabled "disabled"))
    (set-layout w (V border: 8 spacing: 8
                     size: 40
                     (dom name)
                     (dom caption)
                     :filler:
                     size: 30
                     (H :filler: size: 80
                        (dom editnode) (dom ok) (dom cancel)
                        :filler:)))
    (show-window w center: true modal: true)))

(defun textarea-edit (b hv-node cback)
  (let** ((w (window 0 0 300 200 title: "Textarea properties"))
          (name (add-widget w (input "name" autofocus: true)))
          (caption (add-widget w (input "caption")))
          (editnode (add-widget w (button "Layout" #'layout)))
          (ok (add-widget w (button "OK" #'ok)))
          (cancel (add-widget w (button "Cancel" #'cancel)))
          (#'layout () (edit-hv-node hv-node (lambda ())))
          (#'cancel () (hide-window w))
          (#'ok ()
            (setf b.data-name (text name))
            (setf (caption b) (text caption))
            (hide-window w)
            (funcall cback)))
    (setf (text caption) (caption b))
    (setf (text name) (or b.data-name ""))
    (unless hv-node (setf editnode.disabled "disabled"))
    (set-layout w (V border: 8 spacing: 8
                     size: 40
                     (dom name)
                     (dom caption)
                     :filler:
                     size: 30
                     (H :filler: size: 80
                        (dom editnode) (dom ok) (dom cancel)
                        :filler:)))
    (show-window w center: true modal: true)))

(defun color-edit (b hv-node cback)
  (let** ((w (window 0 0 300 200 title: "Color input properties"))
          (name (add-widget w (input "name" autofocus: true)))
          (caption (add-widget w (input "caption")))
          (editnode (add-widget w (button "Layout" #'layout)))
          (ok (add-widget w (button "OK" #'ok)))
          (cancel (add-widget w (button "Cancel" #'cancel)))
          (#'layout () (edit-hv-node hv-node (lambda ())))
          (#'cancel () (hide-window w))
          (#'ok ()
            (setf b.data-name (text name))
            (setf (caption b) (text caption))
            (hide-window w)
            (funcall cback)))
    (setf (text caption) (caption b))
    (setf (text name) (or b.data-name ""))
    (unless hv-node (setf editnode.disabled "disabled"))
    (set-layout w (V border: 8 spacing: 8
                     size: 40
                     (dom name)
                     (dom caption)
                     :filler:
                     size: 30
                     (H :filler: size: 80
                        (dom editnode) (dom ok) (dom cancel)
                        :filler:)))
    (show-window w center: true modal: true)))

(defun date-edit (b hv-node cback)
  (let** ((w (window 0 0 300 200 title: "Date input properties"))
          (name (add-widget w (input "name" autofocus: true)))
          (caption (add-widget w (input "caption")))
          (editnode (add-widget w (button "Layout" #'layout)))
          (ok (add-widget w (button "OK" #'ok)))
          (cancel (add-widget w (button "Cancel" #'cancel)))
          (#'layout () (edit-hv-node hv-node (lambda ())))
          (#'cancel () (hide-window w))
          (#'ok ()
            (setf b.data-name (text name))
            (setf (caption b) (text caption))
            (hide-window w)
            (funcall cback)))
    (setf (text caption) (caption b))
    (setf (text name) (or b.data-name ""))
    (unless hv-node (setf editnode.disabled "disabled"))
    (set-layout w (V border: 8 spacing: 8
                     size: 40
                     (dom name)
                     (dom caption)
                     :filler:
                     size: 30
                     (H :filler: size: 80
                        (dom editnode) (dom ok) (dom cancel)
                        :filler:)))
    (show-window w center: true modal: true)))

(defun radio-edit (b hv-node cback)
  (let** ((w (window 0 0 300 200 title: "Radio button properties"))
          (name (add-widget w (input "name" autofocus: true)))
          (group (add-widget w (select "group" (range 1 11))))
          (caption (add-widget w (input "caption")))
          (editnode (add-widget w (button "Layout" #'layout)))
          (ok (add-widget w (button "OK" #'ok)))
          (cancel (add-widget w (button "Cancel" #'cancel)))
          (#'layout () (edit-hv-node hv-node (lambda ())))
          (#'cancel () (hide-window w))
          (#'ok ()
            (setf b.data-name (text name))
            (setf (caption b) (text caption))
            (setf (node b).name (text group))
            (hide-window w)
            (funcall cback)))
    (setf (text caption) (caption b))
    (setf (text name) (or b.data-name ""))
    (setf (text group) (or (node b).name ""))
    (unless hv-node (setf editnode.disabled "disabled"))
    (set-layout w (V border: 8 spacing: 8
                     size: 40
                     (H (dom name) size: 50 (dom group))
                     (dom caption)
                     :filler:
                     size: 30
                     (H :filler: size: 80
                        (dom editnode) (dom ok) (dom cancel)
                        :filler:)))
    (show-window w center: true modal: true)))

(defun select-edit (b hv-node cback)
  (let** ((w (window 0 0 300 400 title: "Select properties"))
          (name (add-widget w (input "name" autofocus: true)))
          (caption (add-widget w (input "caption")))
          (values (add-widget w (text-area "values")))
          (editnode (add-widget w (button "Layout" #'layout)))
          (ok (add-widget w (button "OK" #'ok)))
          (cancel (add-widget w (button "Cancel" #'cancel)))
          (#'layout () (edit-hv-node hv-node (lambda ())))
          (#'cancel () (hide-window w))
          (#'ok ()
            (setf b.data-name (text name))
            (setf (caption b) (text caption))
            (do () ((not (node b).firstChild))
              (remove-child (node b) (node b).firstChild))
            (dolist (L (split (text values) "\n"))
              (when (> (length L) 0)
                (let ((opt (append-child (node b)
                                         (create-element "option"))))
                  (setf opt.textContent L))))
            (hide-window w)
            (funcall cback)))
    (setf (text caption) (caption b))
    (setf (text name) (or b.data-name ""))
    (setf (text values) (join (map (get textContent) (node b).children) "\n"))
    (unless hv-node (setf editnode.disabled "disabled"))
    (set-layout w (V border: 8 spacing: 8
                     size: 40
                     (dom name)
                     (dom caption)
                     size: undefined
                     (dom values)
                     size: 30
                     (H :filler: size: 80
                        (dom editnode) (dom ok) (dom cancel)
                        :filler:)))
    (show-window w center: true modal: true)))

(defun editor ()
  (let** ((w (window 0 0 0.75 0.75 title: "GUI editor"))
          (area (set-style (create-element "div")
                           overflow "auto"
                           position "absolute"))
          (widget-list (set-style (create-element "div")
                                  position "absolute"
                                  background-color "#EEE"
                                  overflow "auto"))
          (current null)
          (#'set-current (x)
            (when current
              (set-style (aref current.children 1)
                         backgroundColor "rgba(0,0,0,0.02)")
              (set-style (aref current.children 2)
                         display "none")
              (set-style (aref current.children 3)
                         display "none")
              (set-style (aref current.children 4)
                         display "none"))
            (setf current x)
            (when current
              (set-style (aref current.children 1)
                         backgroundColor "rgba(255,0,0,0.25)")
              (set-style (aref current.children 2)
                         display "block")
              (set-style (aref current.children 3)
                         display "block")
              (set-style (aref current.children 4)
                         display "block")))
          (#'rect-selection (event)
            (set-current null)
            (let** ((x0 (first (relative-pos event area)))
                    (y0 (second (relative-pos event area)))
                    (x1 x0)
                    (y1 y0)
                    (d (set-style (create-element "div")
                                  position "absolute"
                                  px/left x0
                                  px/top y0
                                  px/width 0
                                  px/height 0
                                  backgroundColor "rgba(255,0,0,0.25)")))
              (append-child area d)
              (tracking (lambda (x y)
                          (setf x1 x)
                          (setf y1 y)
                          (set-style d
                                     px/left (min x0 x1)
                                     px/top (min y0 y1)
                                     px/width (abs (- x1 x0))
                                     px/height (abs (- y1 y0))))
                        (lambda ()
                          (remove-child area d)
                          (let** ((widgets (filter (lambda (d)
                                                     (and (>= d.offsetLeft (min x0 x1))
                                                          (>= d.offsetTop (min y0 y0))
                                                          (<= (+ d.offsetLeft d.offsetWidth) (max x0 x1))
                                                          (<= (+ d.offsetTop d.offsetHeight) (max y0 y1))))
                                                   area.children))
                                  (n (length widgets))
                                  (#'x (d) (+ d.offsetLeft (/ d.offsetWidth 2)))
                                  (#'y (d) (+ d.offsetTop (/ d.offsetHeight 2)))
                                  (x-avg (/ (reduce #'+ (map #'x widgets)) n))
                                  (y-avg (/ (reduce #'+ (map #'y widgets)) n))
                                  (h-score (reduce #'+ (map (lambda (d) (expt (- (y d) y-avg) 2)) widgets)))
                                  (v-score (reduce #'+ (map (lambda (d) (expt (- (x d) x-avg) 2)) widgets))))
                            (when (> n 1)
                              (let** ((ww (if (< h-score v-score)
                                              (+ (* (1- (length widgets)) 8)
                                                 (reduce #'+ (map (get offsetWidth) widgets)))
                                              (apply #'max (map (get offsetWidth) widgets))))
                                      (hh (if (< h-score v-score)
                                              (apply #'max (map (get offsetHeight) widgets))
                                              (+ (* (1- (length widgets)) 8)
                                                 (reduce #'+ (map (get offsetHeight) widgets)))))
                                      (d (set-style (create-element "div")
                                                    position "absolute"
                                                    px/left 0
                                                    px/top 0
                                                    px/width ww
                                                    px/height hh))
                                      (layout (if (< h-score v-score)
                                                  (H border: 0 spacing: 8)
                                                  (V border: 0 spacing: 8)))
                                      (spacers (any (w widgets) w.firstChild.data-spacer))
                                      (xa (apply #'min (map (get offsetLeft) widgets)))
                                      (ya (apply #'min (map (get offsetTop) widgets)))
                                      (node #((children (list))
                                              (text (if (< h-score v-score) "H-group" "V-group"))
                                              (item layout)
                                              (propedit #'layout-edit))))
                                (nsort widgets (if (< h-score v-score)
                                                   (lambda (a b) (< a.offsetLeft b.offsetLeft))
                                                   (lambda (a b) (< a.offsetTop b.offsetTop))))
                                (dolist (w widgets)
                                  (if spacers
                                      (if w.firstChild.data-spacer
                                          (add-element layout (dom w))
                                          (add-element layout
                                                       size: (if (< h-score v-score)
                                                                 w.offsetWidth
                                                                 w.offsetHeight)
                                                       (dom w)))
                                      (add-element layout
                                                   weight: (if (< h-score v-score)
                                                               w.offsetWidth
                                                               w.offsetHeight)
                                                   (dom w)))
                                  (set-style (aref w.children 1)
                                             backgroundColor "none")
                                  (nremove w.data-node tree.children)
                                  (push w.data-node node.children)
                                  (setf w.data-node.hv-node (last layout.elements))
                                  (append-child d w))
                                (setf d.data-resize (lambda (x0 y0 x1 y1)
                                                      (set-coords layout 0 0 (- x1 x0) (- y1 y0))))
                                (let ((box (wrap d xa ya)))
                                  (setf box.data-node node)
                                  (setf node.box box)
                                  (push node tree.children)
                                  (wtree.rebuild))))))
                        "pointer"
                        (element-pos area))))
          (#'wrap (d x0 y0)
            (let** ((box (set-style (create-element "div")
                                    position "absolute"))
                    (glass (set-style (create-element "div")
                                      position "absolute"
                                      px/left -4
                                      px/top -4
                                      px/right -4
                                      px/bottom -4
                                      cursor "move"
                                      backgroundColor "rgba(0,0,0,0.02)"))
                    (width-handle (set-style (create-element "div")
                                             position "absolute"
                                             px/width 8
                                             px/height 8
                                             cursor "e-resize"
                                             backgroundColor "#F00"))
                    (double-handle (set-style (create-element "div")
                                              position "absolute"
                                              px/width 8
                                              px/height 8
                                              cursor "se-resize"
                                              backgroundColor "#F00"))
                    (height-handle (set-style (create-element "div")
                                              position "absolute"
                                              px/width 8
                                              px/height 8
                                              cursor "s-resize"
                                              backgroundColor "#F00"))
                    (#'fix-box ()
                      (set-style d
                                 px/width box.offsetWidth
                                 px/height box.offsetHeight)
                      (when d.data-resize
                        (d.data-resize 0 0 d.offsetWidth d.offsetHeight))
                      (set-style height-handle
                                 px/left (+ -4 (/ box.offsetWidth 2))
                                 px/top (+ -4 box.offsetHeight))
                      (set-style double-handle
                                 px/left (+ -4 box.offsetWidth)
                                 px/top (+ -4 box.offsetHeight))
                      (set-style width-handle
                                 px/left (+ -4 box.offsetWidth)
                                 px/top (+ -4 (/ box.offsetHeight 2)))))
              (setf box.data-resize #'fix-box)
              (append-child box d)
              (append-child box glass)
              (append-child box width-handle)
              (append-child box height-handle)
              (append-child box double-handle)
              (append-child area box)
              (set-style box
                         px/left x0
                         px/top y0
                         px/width d.offsetWidth
                         px/height d.offsetHeight)
              (fix-box)
              (set-handler box onmousedown
                (event.preventDefault)
                (event.stopPropagation)
                (set-current box)
                (let (((x y) (event-pos event)))
                  (dragging box x y)))
              (set-handler width-handle onmousedown
                (event.preventDefault)
                (event.stopPropagation)
                (let ((x (first (event-pos event))))
                  (tracking (lambda (xx yy)
                              (declare (ignorable yy))
                              (let ((dx (- xx x)))
                                (setf x xx)
                                (setf box.style.width ~"{(max 10 (min (+ box.offsetWidth dx)))}px"))
                              (fix-box)))))
              (set-handler double-handle onmousedown
                (event.preventDefault)
                (event.stopPropagation)
                (let ((x (first (event-pos event)))
                      (y (second (event-pos event))))
                  (tracking (lambda (xx yy)
                              (let ((dx (- xx x))
                                    (dy (- yy y)))
                                (setf x xx)
                                (setf y yy)
                                (set-style box
                                           width ~"{(max 10 (min (+ box.offsetWidth dx)))}px"
                                           height ~"{(max 10 (min (+ box.offsetHeight dy)))}px"))
                              (fix-box)))))
              (set-handler height-handle onmousedown
                (event.preventDefault)
                (event.stopPropagation)
                (let ((y (second (event-pos event))))
                  (tracking (lambda (xx yy)
                              (declare (ignorable xx))
                              (let ((dy (- yy y)))
                                (setf y yy)
                                (setf box.style.height ~"{(max 10 (min (+ box.offsetHeight dy)))}px"))
                              (fix-box)))))
              (set-current box)
              box))
          (#'add-widget-button (text builder ww hh &optional propedit)
            (let** ((c (button text (lambda ())))
                    (#'add (x y)
                      (let* ((box (wrap (set-style (funcall builder)
                                                   position "absolute"
                                                   px/width ww
                                                   px/height hh)
                                        0 0))
                             (node #((children (list))
                                     (text text)
                                     (box box)
                                     (propedit propedit))))
                        (setf box.data-node node)
                        (push node tree.children)
                        (wtree.rebuild)
                        (set-style box
                                   px/left (- x (/ box.offsetWidth 2))
                                   px/top (- y (/ box.offsetHeight 2)))
                        box)))
              (set-handler c onmousedown
                (event.preventDefault)
                (event.stopPropagation)
                (let** ((x (first (relative-pos event area)))
                        (y (second (relative-pos event area)))
                        (box (add x y)))
                  (tracking (lambda (xx yy)
                              (set-style box
                                         px/left (+ box.offsetLeft (- xx x))
                                         px/top (+ box.offsetTop (- yy y)))
                              (setf x xx)
                              (setf y yy))
                            undefined
                            "move"
                            (element-pos area))))
              (append-child widget-list c)))
          (#'fix-widget-list ()
            (do ((c widget-list.firstChild c.nextSibling)
                 (i 0 (1+ i)))
              ((not c))
              (set-style c
                         position "absolute"
                         px/left 2
                         px/top (+ (* i 30) 2)
                         px/right 2
                         px/height 26)))
          (tree #((children (list))
                  (text "Window")))
          (#'refresh ()
            (dolist (w area.children)
              (when w.data-resize
                (funcall w.data-resize 0 0 w.offsetWidth w.offsetHeight))))
          (#'node-click (n)
            (cond
              (n.propedit
                (n.propedit (or n.item n.box.firstChild) n.hv-node #'refresh))
              (n.hv-node
                (edit-hv-node n.hv-node #'refresh))))
          (wtree (set-style (tree-view tree onclick: #'node-click)
                            position "absolute"
                            overflow "auto"))
          (vs (v-splitter widget-list wtree))
          (hs (add-widget w (h-splitter area vs split: 80)))
          (widgets (list))
          (layout null))
    (setf widget-list.data-resize #'fix-widget-list)
    (set-handler area onmousedown
      (event.preventDefault)
      (event.stopPropagation)
      (rect-selection event))

    (add-widget-button "Button" (lambda () (button "Button" (lambda ()))) 80 30 #'button-edit)
    (add-widget-button "Input" (lambda () (input "Input field")) 200 40 #'input-edit)
    (add-widget-button "Select" (lambda () (select "Select field" (range 10))) 200 40 #'select-edit)
    (add-widget-button "Checkbox" (lambda () (checkbox "Checkbox")) 200 40 #'checkbox-edit)
    (add-widget-button "Radio" (lambda () (radio 1 "Radio button")) 200 40 #'radio-edit)
    (add-widget-button "Textarea" (lambda () (text-area "Text area")) 200 80 #'textarea-edit)
    (add-widget-button "Color" (lambda () (css-color-input "Color")) 200 40 #'color-edit)
    (add-widget-button "Date" (lambda () (date-input "Date")) 120 40 #'date-edit)
    (add-widget-button "Spacer" (lambda () (set-style (let ((d (create-element "div")))
                                                        (setf d.data-spacer true)
                                                        d)
                                                      backgroundColor "#CEE"))
                       20 20)

    (set-layout w (H spacing: 8 border: 8
                     (dom hs)))
    (show-window w center: true)))

(defun main ()
  (editor))

(main)