#lang racket
(require 2htdp/image)

(place-image (above
              (beside (rectangle 10 4 'solid 'red)
                      (rectangle 3 4 'solid 'white)
                      (rectangle 10 4 'solid 'red))              
              (beside (rectangle 6 50 'solid 'brown)
                      (rectangle 4 50 'solid 'white)
                      (rectangle 6 50 'solid 'brown)
                      (rectangle 4 50 'solid 'white)
                      (rectangle 6 50 'solid 'brown)))
             40 325
             (above 
              (beside (rectangle 10 4 'solid 'red)
                      (rectangle 3 4 'solid 'white)
                      (rectangle 10 4 'solid 'red))              
              (beside (rectangle 6 50 'solid 'brown)
                      (rectangle 4 50 'solid 'white)
                      (rectangle 6 50 'solid 'brown)
                      (rectangle 4 50 'solid 'white)
                      (rectangle 6 50 'solid 'brown))
              (rectangle 80 300 'solid 'lightgreen)))
                    
