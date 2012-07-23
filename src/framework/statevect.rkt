#lang racket
(provide vectmanager%)
(define vectmanager%
  (class object%
    (init length val)                ; initialization argument
    
    
    ; field
    (define vectlen length)
    (define vect (make-vector length val))
    (define head 0)
    (define tail (- vectlen 1))
   
    
     ; superclass initialization
    (super-new)               
 
    (define/public (insert x)
      (begin
        (set! tail (remainder (+ tail 1) vectlen))
        (vector-set! vect tail x)
        (cond [(= tail head)
               (set! head (remainder (+ head 1) vectlen))])))
    (define/public (insertwitholddata)
      (begin
        (set! tail (remainder (+ tail 1) vectlen))
        (cond [(= tail head)
               (set! head (remainder (+ head 1) vectlen))])))
    (define/public (getdata ref)
      (cond
        [(>= ref vectlen)
         #f]
        [else
         (vector-ref vect (remainder (+ head ref) vectlen))]))

    (define/public (getvector)
      vect)
    (define/public (backto ref)
      (let* ([pos (remainder (+ head ref) vectlen)]
             [ret (remainder (+ (- tail pos) vectlen) vectlen)])
        (set! tail pos)
        ret))
        

    ))