#lang racket
(define make-interval
  (lambda ()
    (let ([mycurrent-time 0])
      (lambda ()
        (let ([now-time 0]
              [interval 0])
          (begin 
            (cond [(= mycurrent-time 0)
                   (set!  mycurrent-time (current-milliseconds))])              
            (set! now-time (current-milliseconds))
            (set! interval (- now-time mycurrent-time))
            (set! mycurrent-time now-time)
            interval))))))

(provide make-interval)