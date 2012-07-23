#lang racket/gui
(require framework)
(require racket/match)
(require "xml-map.rkt")
(require "framework/framework.rkt")
(require "collisiondetect.rkt")

(define vect-list (read-map-xml "2.tmx"))
(define barrier-vect (car vect-list));储存砖块信息
(define myforegmap (read-bitmap "brick.png"))
(define mariomap(read-bitmap "mario-small.png"))
(define mariomap2 (read-bitmap "mario-small2.png"))
(define mariogirlmap(read-bitmap "m-gz.png"))
(define marioxxmap(read-bitmap "m-xx.png"))
(define  wgmap (read-bitmap "yazi.png"))
(define map-width 600)
(define map-height 700)
(define tile-width 50)
(define tile-height 50)
(define tile-step 12)
(struct state (x y d m v-x v-y r die win pitui cr cg cb csize totaltime tx )
  #:transparent
  #:mutable)
(struct tortoise (x y d stop time pitui) 
  #:transparent
  #:mutable)
(define mario-state (state 1 1 0 0 0 0 0 0 0 0 0 0 0 100 0 (tortoise 220 504 1 0 -1 0 )))
(define (draw-point dc mario-s)
  (send dc draw-bitmap-section mariomap 
        (state-x mario-s) (state-y mario-s) 
        (* (state-m mario-s) 41)
        (* (state-d mario-s) 40) 38 38))
(define mef
  (lambda (event)
    (cond
      [(and (send event button-down? 'left)(send  event get-control-down))
       (let ([x (send event get-x)]
             [y (send event get-y)])
         (begin
           (change-barrier x y 1)
           #f))]
      [(and (send event button-down? 'right)(send  event get-control-down))
       (let ([x (send event get-x)]
             [y (send event get-y)])
         (begin
           (change-barrier x y 0)
           #f))]
      [(and (send event dragging?)(send event get-left-down)(send  event get-control-down))
       (let ([x (send event get-x)]
             [y (send event get-y)])
         (begin
           (change-barrier x y 1)
           #f))]
      [(and (send event dragging?)(send event get-right-down)(send  event get-control-down))
       (let ([x (send event get-x)]
             [y (send event get-y)])
         (begin
           (change-barrier x y 0)
           #f))]
      [else #f]
      )))
(define kef
  (lambda (event)
    (let([key (send event get-key-code)]
         [releasekey (send event get-key-release-code)]
         [parse (lambda (type cmd)
                  (cond
                    [(symbol=? type 'press)
                     (cond
                       [(char? cmd) 
                        (let ([tempcmd (char-downcase cmd)])
                          (case tempcmd
                            [(#\space)(list 'jump)]
                            [else #f]))]
                       [(symbol? cmd)
                        (cond 
                          [(symbol=? cmd 'left)(list 'left 'down)]
                          [(symbol=? cmd 'right)(list 'right 'down)]
                          [else #f])])]
                    [(symbol=? type 'release)
                     (cond
                       [(char? cmd) #f]
                       [(symbol? cmd)
                        (cond 
                          [(symbol=? cmd 'left)(list 'left 'release)]
                          [(symbol=? cmd 'right)(list 'left 'release)]
                          [else #f]
                          )])]))])
      (cond 
        [(and (key-code-symbol? key) (symbol=? key 'release))
         (parse 'release releasekey)]
        [else (parse 'press key)]))))

(define change-barrier
  (lambda (x y amt)
    (let ([ref-num (+ (* tile-step (floor (/ y tile-height))) (floor (/ x tile-width)))])
      (begin
        (vector-set! (car vect-list) ref-num amt)
        (send mario-example recalculate)
        ))))


(define mydisplay
  (lambda (dc mario-s)
    (cond [mario-s
           (begin
             (define draw-mario
               (lambda (dc)
                 (cond [(= 0 (state-r mario-s))
                        (send dc draw-bitmap-section mariomap 
                              (state-x mario-s) (state-y mario-s) 
                              (* (state-pitui mario-s) 41)
                              (* (state-d mario-s) 40) 38 38)]
                       [else 
                        (send dc draw-bitmap-section mariomap2 
                              (state-x mario-s) (state-y mario-s) 
                              (* (- 1 (state-pitui mario-s)) 41)
                              (* (state-d mario-s) 40) 38 38)])))
             
             (define draw-foreg
               (lambda (dc vect map)
                 (let* ([draw-one-iner (lambda (dc type loc)
                                         (let ([x (* (remainder loc (/ map-width tile-width))  tile-width)]
                                               [y (* (quotient loc (/ map-width tile-width)) tile-height)])
                                           (cond
                                             [(> type 0) (send dc draw-bitmap-section map x y 1 0 tile-width tile-height)])))])
                   (let loop ([n 0])
                     (cond
                       [(< n (/ (* map-width map-height) (* tile-width tile-height))) 
                        (begin
                          (draw-one-iner dc (vector-ref vect n) n)
                          (loop (add1 n)))]))
                   )))
             (define (draw-wugui dc)
               (let ([pos 0]
                     [tx (state-tx mario-s)])
                 (begin
                   (cond 
                     [(= (tortoise-stop tx) 1)
                      (set! pos 0)]
                     [(= (tortoise-d tx) -1)
                      (set! pos (+ 1 (tortoise-pitui tx)))]
                     [(= (tortoise-d tx) 1)
                      (set! pos (+ 3 (tortoise-pitui tx)))])
                   (send dc draw-bitmap-section wgmap (tortoise-x (state-tx mario-s)) (tortoise-y (state-tx mario-s)) (* pos 40) 0 40 46))))
             (define (draw-win dc)
               (begin
                 ;(send dc set-rotation (* 180 (cos(sin (/ (state-totaltime mario-s)108)))))
                 (send dc set-font (make-object font% (state-csize mario-s) 'roman))
                 (send dc set-text-foreground (make-object color% (state-cr mario-s)(state-cg mario-s)(state-cb mario-s)))
                 (let-values ([(w h a b)(send dc get-text-extent "win!")]) 
                   (send  dc draw-text "win!" (- 300 (/ w 2))(- 300 (/ h 2))))
                 ;(send dc set-rotation 0)
                 )) 	 	 	 	 
             
             
             (send dc draw-rectangle 0 0 600 700)
             (draw-foreg dc barrier-vect myforegmap)
             (send dc draw-bitmap-section mariogirlmap 520 450 0 0 50 50)
             (send dc draw-bitmap-section marioxxmap 420 260 0 0 50 50)
             (draw-wugui dc)
             (draw-mario dc)
             (cond 
               [(= 1 (state-win mario-s))
                (draw-win dc)])
             )])))
  
  
  (define state-copy
    (lambda (x)
      (begin 
        (define ret(struct-copy state x))
        (set-state-tx! ret (struct-copy tortoise (state-tx x)))
        ret)))
  
  (define mario-example (new myframework% [itv 30][mainf "editor1.txt"][showf mydisplay][drawpointf draw-point][inits mario-state]
                             [copystate state-copy]
                             [keyeventfilter kef]
                             [mouseeventfilter mef]))
  (send mario-example run)
  
  
  
  
  
  
  