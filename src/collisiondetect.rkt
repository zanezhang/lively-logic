#lang racket

(struct posn (x y [z #:auto])
  #:auto-value 0
  #:transparent
  #:mutable)

(define (xmult p1-x p1-y p2-x p2-y p3-x p3-y)
  (-(*(- p1-x p3-x) (- p2-y p3-y)) (*(- p2-x p3-x)(- p1-y p3-y))))
(define (mymult p1-x p1-y p2-x p2-y p-x p-y)
  (-(*(- p1-y p2-y) (- p-x p1-x)) (*(- p1-x p2-x)(- p-y p1-y))))
(define sameside
  (lambda (f l1-p1-x l1-p1-y l1-p2-x l1-p2-y l2-p1-x l2-p1-y l2-p2-x l2-p2-y)
    (cond [(> (* (f l1-p1-x l1-p1-y l1-p2-x l1-p2-y l2-p1-x l2-p1-y)
                 (f l1-p1-x l1-p1-y l1-p2-x l1-p2-y l2-p2-x l2-p2-y)) 0)
           #t]
          [else #f])))
(define intersect-in
  (lambda (l1-p1-x l1-p1-y l1-p2-x l1-p2-y l2-p1-x l2-p1-y l2-p2-x l2-p2-y)
    (and (not (sameside mymult l1-p1-x l1-p1-y l1-p2-x l1-p2-y l2-p1-x l2-p1-y l2-p2-x l2-p2-y))
         (not (sameside mymult l2-p1-x l2-p1-y l2-p2-x l2-p2-y l1-p1-x l1-p1-y l1-p2-x l1-p2-y)))))
(define intersect
  (lambda (l1-p1-x l1-p1-y l1-p2-x l1-p2-y l2-p1-x l2-p1-y l2-p2-x l2-p2-y)
    (let ([tt (-(*(- l1-p1-x l1-p2-x) (- l2-p1-y l2-p2-y)) (* (- l1-p1-y l1-p2-y) (- l2-p1-x l2-p2-x)))])
      (cond [(= tt 0) #f]
            [else
             (let* ([t (/(-(*(- l1-p1-x l2-p1-x) (- l2-p1-y l2-p2-y)) (* (- l1-p1-y l2-p1-y) (- l2-p1-x l2-p2-x))) tt)]
                    [x (+ l1-p1-x (* (- l1-p2-x l1-p1-x) t))]
                    [y (+ l1-p1-y (* (- l1-p2-y l1-p1-y) t))])
               (posn x y))]))))

(define detect-two-line-cross
  (lambda (l1-p1-x l1-p1-y l1-p2-x l1-p2-y l2-p1-x l2-p1-y l2-p2-x l2-p2-y)
    (cond [(intersect-in l1-p1-x l1-p1-y l1-p2-x l1-p2-y l2-p1-x l2-p1-y l2-p2-x l2-p2-y)
           (intersect l1-p1-x l1-p1-y l1-p2-x l1-p2-y l2-p1-x l2-p1-y l2-p2-x l2-p2-y)]
          [else #f])))
(struct line (x1 y1 x2 y2 direct)
  #:transparent
  #:mutable)
(struct rect (x y width height)
  #:transparent
  #:mutable)
(provide line)
(provide line-direct)
(provide line-x2)
(provide line-y2)
(define goback
  (lambda (l2 l1)
    (let ([pos (detect-two-line-cross (line-x1 l1) (line-y1 l1) (line-x2 l1) (line-y2 l1)(line-x1 l2) (line-y1 l2) (line-x2 l2) (line-y2 l2))])
      (cond [pos
             ;(case (line-direct l2)
             ;  [(0 3) (line (line-x1 l1) (line-y1 l1) (line-x2 l1) (posn-y pos) (line-direct l2))]
             ;[(1 2) (line (line-x1 l1) (line-y1 l1) (posn-x pos) (line-y2 l1) (line-direct l2))])
             (line (line-x1 l1) (line-y1 l1) (posn-x pos) (posn-y pos) (line-direct l2))
             ]
            [else
             l1]))))

(define (merge-rect up1 left1 right1 down1 up2 left2 right2 down2)
  (let ([up
         (if (< up1 up2) up1 up2)]
        [left
         (if (< left1 left2) left1 left2)]
        [right
         (if (< right1 right2) right2 right1)]
        [down
         (if (< down1 down2) down2 down1)])
    (begin
      ;(printf "merge-rect")
      (rect left up (- right left) (- down up)))))
;(define (detect-collision-barrier-iner x y vect tile-width tile-height tile-step)
; (let ([ref-num (inexact->exact (+ (floor (/ x tile-width)) (* (floor (/ y tile-height)) tile-step)))])
; (cond
; [(> (vector-ref vect ref-num) 0) ref-num]
; [else #false])))
(define line-offset
  (lambda (l x y)
    (line (+ x (line-x1 l)) (+ y (line-y1 l))(+ x (line-x2 l))(+ y (line-y2 l))(line-direct l))))
(define getlinelist
  (lambda (x y width height vect tile-width tile-height tile-step)
    (let ([linelist '()]
          [vectlength (vector-length vect)]
          [foo (lambda (up left right down)
                 (list (line left up right up 0) (line left up left down 1)(line right up right down 2)(line left down right down 3)))])
      (begin
        (for ([i (in-range (floor (/ x tile-width)) (+ (floor (/ (+ x width) tile-width)) 1))])
          (for ([j (in-range (floor (/ y tile-height)) (+ (floor (/ (+ y height) tile-height))1))])
            (let ([ref (inexact->exact (+ i (* j tile-step)))])
              (cond
                [(and (< ref vectlength)(>= ref 0) (> (vector-ref vect ref) 0))
                 (begin
                   ;(printf "youxi")
                   (set! linelist (append (foo (* j tile-height)(* i tile-width)(+ (* i tile-width) tile-width -1)(+ (* j tile-height) tile-height -1)) linelist)))]))))
        ; (printf "getlinelist : ~a" linelist) 
        linelist))))
(define (detect-collision-barrier x y width height offset-x offset-y vect tile-width tile-height tile-step mapwidth mapheight)
  (let* ([mrect (merge-rect y x (+ x width) (+ y height) (+ y offset-y)(+ x offset-x) (+ x offset-x width)(+ y offset-y height))]
         [linlist (getlinelist (rect-x mrect) (rect-y mrect)(rect-width mrect)(rect-height mrect) vect tile-width tile-height tile-step)]
         [myline (line x y (+ x offset-x) (+ y offset-y) -1) ])
    (begin
      ;(printf "rect: ~a" mrect)
      (set! linlist (append linlist (list (line -1 -1 mapwidth -1 3) (line -1 -1 -1 mapheight 2)(line mapwidth -1 mapwidth mapheight 1)(line mapwidth mapheight -1 mapheight 0))))
      (set! myline (foldr goback myline linlist)) 
      (set! myline (line-offset myline width 0))
      (set! myline (foldr goback myline linlist)) 
      (set! myline (line-offset myline 0 height))
      (set! myline (foldr goback myline linlist)) 
      (set! myline (line-offset myline (- 0 width) 0))
      (set! myline (foldr goback myline linlist)) 
      (set! myline (line-offset myline 0 (- 0 height)))
      (line (line-x1 myline) (line-y1 myline) (- (line-x2 myline) (/ offset-x 1000000))(- (line-y2 myline)(/ offset-y 1000000)) (line-direct myline))
      
      )))
(define (detect-collision-rect x y width height offset-x offset-y x1 y1 width1 height1)
  (let* ([linlist (list (line x1            y1          (+ x1 width1) y1 0) 
                        (line x1            y1           x1          (+ height1 y1) 1)
                        (line (+ x1 width1) y1          (+ x1 width1)(+ y1 height1) 2)
                        (line (+ x1 width1)(+ y1 height1)x1          (+ y1 height1) 3))]
         [myline (line x y (+ x offset-x) (+ y offset-y) -1)])
    (begin
      ;(printf "~a ~a ~a ~a ~a ~a ~a ~a ~a ~a \n" x y width height offset-x offset-y x1 y1 width1 height1)
      (set! myline (foldr goback myline linlist)) 
      (set! myline (line-offset myline width 0))
      (set! myline (foldr goback myline linlist)) 
      (set! myline (line-offset myline 0 height))
      (set! myline (foldr goback myline linlist)) 
      (set! myline (line-offset myline (- 0 width) 0))
      (set! myline (foldr goback myline linlist)) 
      (set! myline (line-offset myline 0 (- 0 height)))
      (line (line-x1 myline) (line-y1 myline) (- (line-x2 myline) (/ offset-x 1000000))(- (line-y2 myline)(/ offset-y 1000000)) (line-direct myline))
      )))
(define rect-intersection
  (lambda (up1 left1 right1 down1 up2 left2 right2 down2)
    (cond
      [(or (< down1 up2) (< down2 up1) (< right2 left1) (< right1 left2))
       #false]
      [else #true])))
(provide rect-intersection)
(provide detect-collision-rect)
(provide detect-collision-barrier)

