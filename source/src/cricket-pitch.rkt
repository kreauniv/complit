#lang racket
(require 2htdp/image)

(define (front colour)
  (rectangle 40 40 'solid colour))

(define colour 'brown)


(place-image (above
              (beside (rectangle 10 4 'solid 'red)
                      (rectangle 3 4 'solid 'transparent)
                      (rectangle 10 4 'solid 'red))              
              (beside (rectangle 6 50 'solid 'lightbrown)
                      (rectangle 4 50 'solid 'transparent)
                      (rectangle 6 50 'solid 'lightbrown)
                      (rectangle 4 50 'solid 'transparent)
                      (rectangle 6 50 'solid 'lightbrown)))
             40 325
             (above 
              (beside (rectangle 10 4 'solid 'red)
                      (rectangle 3 4 'solid 'transparent)
                      (rectangle 10 4 'solid 'red))              
              (beside (rectangle 6 50 'solid 'lightbrown)
                      (rectangle 4 50 'solid 'transparent)
                      (rectangle 6 50 'solid 'lightbrown)
                      (rectangle 4 50 'solid 'transparent)
                      (rectangle 6 50 'solid 'lightbrown))
              (rectangle 80 300 'solid 'lightgreen)))

