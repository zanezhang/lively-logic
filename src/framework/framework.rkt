#lang racket/gui
(require framework)
(require "time-interval.rkt")
(require "statevect.rkt")
(struct sexp-st (start end sexp)
      #:transparent
      #:mutable)
(provide myframework%)
(define myframework%
  (class object%
    (init itv mainf showf drawpointf inits copystate keyeventfilter mouseeventfilter)                ; initialization argument
    ; field
    (define mainfstring mainf);主循环所在文件的文件名
    (define showfun showf);显示函数，用来向canvas输出
    (define timeinteval itv);游戏每帧的间隔
    (define drawpointfun drawpointf);用来向canvas输出轨迹
    (define track-state 0);是否画轨迹的标记
    (define nowstate #f)
    (define ispause #f)
    (define statelen 133);录像的长度
    (define myinitstate inits);游戏的初始状态
    (define mykeyeventfilter keyeventfilter);键盘事件过滤器
    (define mymouseeventfilter mouseeventfilter);鼠标事件过滤器
    (define mycopystate copystate);游戏状态的copy函数
    (define get-interval (make-interval));获取时间间隔
    (define statequeue (new vectmanager% [length statelen][val myinitstate]));游戏状态队列
    (define eventqueue (new vectmanager% [length statelen][val '()]));事件队列
    (define eventlist '())
    (define initcomplete #f)
    (define editor-change #f)
    (define canvas-on-focus #f)
    (define focus-pen
      (new pen% [color (make-object color% 0 255 0)]	 	 	 	 
 	 	[width 3]	 	 	 	 
 	 	[style 'solid]))
    (define non-focus-pen
      (new pen% [color (make-object color% 255 255 255)]	 	 	 	 
 	 	[width 2]	 	 	 	 
 	 	[style 'solid]))
    (define mainloop 
          (lambda (x y z)
            (void)));游戏主循环
    (define my-frame% 
      (class frame%
        (super-new)
        (define/augment (on-close)
          (cond [(and editor-change (symbol=? 'yes (message-box	 """代码已被修改，是否保存?" #f (list 'yes-no))))
          (send mytext save-file)]))))
    (define myframe (new my-frame% [label "game-editor"]
                         [width 1200]
                         [height 800]))
    (define v-panel (new vertical-panel% [parent myframe]))
    (define h-panel (new horizontal-panel% [parent v-panel][ stretchable-height #f]))
    (define slider-cb
      (lambda (b e)
        (let* ([ref (send b get-value)]
               [c-s (send statequeue getdata ref)])
          (begin
            (set! nowstate c-s)
            (send game-canvas on-paint)
            ; (showoncanvas c-s)
            ;(cond [(= track-state 1)
                   ;(draw-track)])
            )))) 
    (define draw-track
      (lambda ()
        (let* ([dc (send game-canvas get-dc)]
               [draw-point-inner 
                (let ([num 0])
                  (lambda (c-s)
                    (begin 
                      (cond [(and c-s (= 0 (remainder num 5)))
                             (drawpointfun dc c-s)])
                      (set! num (add1 num)))))])
          (begin
            (send dc suspend-flush)
            (send dc set-alpha 0.2)
            (vector-map draw-point-inner (send statequeue getvector))
            (send dc set-alpha 1)
            (send dc resume-flush)))))
    (define myslider (new slider%
                          [label "&slider"]	 
                          [min-value 0]	 
                          [max-value (- statelen 1)]
                          [init-value (- statelen 1)]
                          [parent h-panel]
                          [enabled #f]
                          [callback slider-cb]))
    
    (define mypanel (new horizontal-panel% [parent v-panel]))
    
    (define pause
      (lambda ()
        (begin
          (send maintimer stop)
          (send myslider set-value (- statelen 1))
          (set! ispause #t)
          (send game-canvas on-paint)
          (send myslider enable #t))))
    (define continue
      (lambda ()
        (begin
          (send playtimer start timeinteval)
          )))
    (define track
      (lambda ()
        (begin
          (set! track-state (- 1 track-state))
          (cond
            [(> track-state 0)
             (draw-track)])
          )))
    (define playtimer 
      (new timer%
           [interval #f]
           [notify-callback
            (lambda ()
              (let ([ref (send myslider get-value)])
                (cond [(= ref (- statelen 1))
                       (begin 
                         (send playtimer stop)
                         (send myslider enable #f)
                         (set! get-interval (make-interval))
                         (set! ispause #f)
                         (send maintimer start timeinteval))]
                      [else
                       (begin
                         
                         (send myslider set-value (+ ref 1))
                         (slider-cb myslider 'slider))])))])) 
    (define my-canvas% 
      (class canvas%
        (super-new)
        (define/override (on-char event)
          (begin
            (let([key (send event get-key-code)])
              (cond
                [(char? key) 
                 (case key
                   [(#\p) (pause)]
                   [(#\c) (continue)]
                   [(#\t) (track)])])))
          (let ([e (mykeyeventfilter event)])
            (cond [e (set! eventlist (append  eventlist (list e) ))])))
        (define/override (on-event event)
          (let ([e (mymouseeventfilter event)])
            (cond [e (set! eventlist (append  eventlist (list e) ))])))
        (define/override (on-paint)
          (begin
            ;(printf "onpaint")
            (showoncanvas nowstate)
            (cond [(and (= track-state 1) ispause)
                   (draw-track)])
            ))
        
        (define/override (on-focus on?)
          (begin 
            (set! canvas-on-focus on?)
            (send this on-paint)
            ;(display canvas-on-focus)
            ))))
    (define game-canvas (new my-canvas% [parent mypanel]	))
    (define showoncanvas
      (lambda (s)
        (let ([dc (send game-canvas get-dc)])
          (let-values ([(w h)(send game-canvas get-size)])
            (send dc suspend-flush)
            (send dc erase)
            (send dc draw-rectangle 0 0 w h)
            (showfun dc s)
            (define oldpen (send dc get-pen))
            (cond
              [canvas-on-focus
               (send dc set-pen focus-pen)]
              [else
               (send dc set-pen non-focus-pen)])
            (send dc draw-line 0 0 0 h) 
            (send dc draw-line 0 0 w 0)
            (send dc draw-line w h w 0)
            (send dc draw-line w h 0 h)
            (send dc set-pen oldpen)
            (send dc resume-flush)
            
          ))))
    (define editor-panel (new vertical-panel% [parent mypanel]))
    (define editor-canvas (new editor-canvas% [parent editor-panel]))
   ; (define outputmsg (new message% [label "sss" ] [parent editor-panel][min-height 150][stretchable-height #f]))
    (define output-canvas (new editor-canvas% [parent editor-panel][min-height 150][stretchable-height #f]))
    (define my-text% 
      (class racket:text%
        (super-new)
        (define/override (on-char event)
          (let([key (send event get-key-code)]
               [cd (send event get-control-down)])
            (begin
              (cond 
                [;(and cd (char? key)(char-ci=? key #\m))
                 (and (symbol? key)(symbol=? key 'escape))
                 (do-adjust)]
                [else (super on-char event)]))))
        (define/augment (on-change)
          (begin
            (set! editor-change #t)
            (with-handlers ([exn:fail? (lambda (exn) (outputerror exn))])
              ; (printf "change1\n")
              (set! mainloop (test (send this get-text)))
              ; (printf "change2\n")
              (recalculate)
              (outputsuccess)
              ))
          )))
    

    
    
    (define (get-out-exp)
      (let* ([posnow (send mytext get-start-position)]
             [posstart (send mytext find-up-sexp posnow)])
        (cond [posstart
               (let ([posend (send mytext get-forward-sexp posstart)])
                 (cond
                   [posend
                    (sexp-st posstart posend (send mytext get-text posstart posend))]
                   [else #f]))]
              [else #f])))
    (define (get-right-exp)
      (let* ([posnow (send mytext get-start-position)]
             [posend (send mytext get-forward-sexp posnow)])
        (cond [posend
               (let ([posstart (send mytext get-backward-sexp posend)])
                 (cond 
                   [posstart
                    (sexp-st posstart posend (send mytext get-text posstart posend))]
                   [else
                    #f]))]
              [else #f])))
    
    
    (define (get-left-exp)
      (let* ([posnow (send mytext get-start-position)]
             [posstart (send mytext get-backward-sexp posnow)])
        (cond [posstart
               (let ([posend (send mytext get-forward-sexp posstart)])
                 (cond 
                   [posend
                    (sexp-st posstart posend (send mytext get-text posstart posend))]
                   [else
                    #f]))]
              [else #f])))
    (define adjust-num
      (let ([mydialog 'null]
            [myslider 'null]
            [num 0]
            [startpos 0]
            [granularity 0];粒度
            [endpos 0])
        (lambda (s e n)
          (begin
            (define cb
              (lambda (b e)
                (let* ([s-v (/ (send b get-value) 10.0)]
                       [newnum (+ num (* granularity (* s-v s-v s-v)))]
                       [newstr (number->string newnum)]
                       [strlen (string-length newstr)])
                  (begin
                    (send mytext insert newstr startpos endpos)
                    (set! endpos (+ startpos strlen))))))
            (set! num n)
            (cond
              [(= 0 n)
               (set! granularity 0.1)]
              [else (set! granularity (exact->inexact (abs (/ n 100))))])
            (set! startpos s)
            (set! endpos e)
            (set! mydialog (new dialog% [label "adjust num"]))
            (set! myslider (new slider% [label "d"]	 
                                [min-value -100]	 
                                [max-value 100]
                                [style (list 'plain 'horizontal)]
                                [init-value 0]
                                [callback cb]
                                [parent mydialog]))
            (send mydialog show #t)))))
    (define (detect-adjust-color amt)
      #f)
    (define (detect-adjust-num amt)
      (let ([num (string->number (sexp-st-sexp amt))])
        (cond [num
               (adjust-num (sexp-st-start amt) (sexp-st-end amt) num)]
              [else #f])))
    (define (do-adjust)
      (let ([done #f])
        (begin 
          (cond [(not done)
                 (let ([nowsexp (get-out-exp)])
                   (cond [nowsexp
                          (set! done (or (detect-adjust-color nowsexp) (detect-adjust-num nowsexp)))]))])
          (cond [(not done)
                 (let ([nowsexp (get-left-exp)])
                   (cond [nowsexp
                          (set! done (or (detect-adjust-color nowsexp) (detect-adjust-num nowsexp)))]))])
          (cond [(not done)
                 (let ([nowsexp (get-right-exp)])
                   (cond [nowsexp
                          (set! done (or (detect-adjust-color nowsexp) (detect-adjust-num nowsexp)))]))]))))                 
    
    (define mytext (new my-text%))
    (define outputtext (new racket:text%))
  
    (define (outputsuccess)
      (begin
        (send outputtext erase)
        (send outputtext insert "success\n" 0)))
    (define (outputerror amt)
      (begin
        (send outputtext erase)
        
        (send outputtext insert "#error:\n" 0)
        (define outputs (open-output-string))
        (display amt outputs)
        (send outputtext insert (get-output-string outputs) (send outputtext last-position ))
        (cond
          [(send outputtext get-dc)
           (begin
            ; (printf "find dc")
             (send (send outputtext get-dc) set-background (make-object color% 0 255 0)))])))
        
        
   
    
    (define mb (new menu-bar% [parent myframe]))
    (define m-edit (new menu% [label "Edit"] [parent mb]))
    (define m-font (new menu% [label "Font"] [parent mb]))
    (append-editor-operation-menu-items m-edit #f)
    (append-editor-font-menu-items m-font)
    ;(define-namespace-anchor nsanchor)
    ;(define nsid (namespace-anchor->namespace nsanchor))
    ;(namespace-require 'racket)
    (define (test mystring)
      (define code-p (open-input-string mystring))
      (define code (read-syntax "  " code-p))
      (eval code))
    
    
    (define maintimer 
      (new timer%
           [interval timeinteval]
           [notify-callback
            (lambda ()
              (with-handlers ([exn:fail? (lambda (exn) (void)) ])
                ;(display "kk")

                (begin
                  (cond [(not initcomplete)
                         (begin
                           (send mytext on-change)
                           (set! editor-change #f)
                           (set! initcomplete #t))])
                  (define currentstate (mainloop (get-interval) eventlist (send statequeue getdata (- statelen 1))))
                  
                  (send eventqueue insert eventlist)
                  (send statequeue insert (mycopystate currentstate))
                  (set! eventlist '())
                  (set! nowstate currentstate)
                  (send game-canvas on-paint)
                  ;(showoncanvas currentstate)
                  
                  )
                  ))]))
    
   
    (super-new)                ; superclass initialization
    (define/public recalculate
      (lambda ()
        (let ([ref (send myslider get-value)])
          (cond [(< ref (- statelen 1))
                 (let ([n (send statequeue backto ref)]
                       
                       [ms (send statequeue getdata ref)])
                   (begin
                     (for ([i (in-range ref (+ ref n))])
                       (let* ([e (send eventqueue getdata (+ i 1))])
                         (begin
                           (with-handlers ([exn:fail? (lambda (exn) (send statequeue insertwitholddata))])
                             (set! ms (mainloop timeinteval e (mycopystate ms) ))
                             (send statequeue insert ms))))
                     )
                     (slider-cb myslider 'slider))
                   )]))))
   (define/public (run)
     (begin 
        (send editor-canvas set-editor mytext)
        (send output-canvas set-editor outputtext)
        (send (send output-canvas get-dc) set-font (make-object font% 150 'default))
        (send myframe show #t)
        (send mytext load-file mainfstring 'text)
        ))
       ))
