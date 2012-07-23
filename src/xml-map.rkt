#lang racket
(require xml)
(require xml/path)
(provide read-map-xml)
(define (read-map-xml filename)
  (map power-foo (file->datalist filename)))
    
(define file->datalist 
  (lambda (filename)
    (se-path*/list '(data) (xml->xexpr (document-element (read-xml (open-input-file filename)))))))

(define power-foo 
  (lambda (x)
    (list->vector
     (map (lambda (data)
           (- (char->integer data) (char->integer #\0)))
         (filter (lambda (data)
                   (and (char<=? data #\9) (char>=? data #\0))) 
                 (string->list x))))))


