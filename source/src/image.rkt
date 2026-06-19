#lang racket

; When (require "./image.rkt") is done, these three words
; will be "provided" to the rest of the definitions file.
(provide read-ppm-image-properties-from-file
         ppm-image-from-file
         write-ppm-image-to-file)
         
; A "colour" consists of three mixed primary colours
; red, green and blue, and an overall opacity indicator
; called "alpha". All four numbers range from 0.0 to 1.0
(struct colour (alpha red green blue))

; Some info about an image
(struct image-properties (width height maxcolourval))

; Reads the dimensions and colour representation of the image
; into an image-properties structure for the currently open
; PPM image file. After this is information is read, only
; the colour data remains to be read.
(define (read-ppm-image-properties)
  (define P6 (read))
  (when (not (equal? P6 'P6))
    (error "Magic code must be P6"))
  (define width (read))
  (when (not (positive-integer? width))
    (error "Width must be a positive integer"))
  (define height (read))
  (when (not (positive-integer? height))
    (error "height must be a positive integer"))
  (define maxcolourval (read))
  (when (not (positive-integer? maxcolourval))
    (error "maxcolourval must be > 0 and an integer - usually 255"))
  (define white-space (read-char))
  (when (not (char-whitespace? white-space))
    (error "Must have one white space character after the maxcolourval"))
  (image-properties width height maxcolourval))
 
(define (read-ppm-image-properties-from-file filename)
  (with-input-from-file filename read-ppm-image-properties))

; Represents the PPM-format image in the given named file
; as an Image that we know how to work with -- i.e.
; a mapping from (x,y) coordinates to colour.
;
; PPM image format -
; https://netpbm.sourceforge.net/doc/ppm.html
; 
; The mapping preserves the "aspect ratio" -- i.e. the
; ratio of width to height. For example, if the image
; dimensions are 400 pixels wide x 300 pixes tall, then
; the aspect ratio (assuming square pixels) is said to be
; 4:3 and the resultant image will have its x-coordinate
; span from 0.0 to 4/3 (~=1.333) and y-coordinate span
; from 0.0 to 1.0.
;
; Also, the y-coordinate in our reference frame points "upwards"
; whereas typically rasterized images are stored top-row first.
; So we'll have to flip our y-coordinate to access the correct row
; of pixels.
(define (ppm-image-from-file filename)
  (with-input-from-file filename
    (lambda ()
      (define improps (read-ppm-image-properties))
      (define width (image-properties-width improps))
      (define height (image-properties-height improps))
      (define maxcolourval (image-properties-maxcolourval improps))

      (define raster (read-raster-image-to-vector width height maxcolourval))
      
      (define transparent-black (colour 0.0 0.0 0.0 0.0))
      (define xmax (/ width height))
      (define ymax 1.0)

      ; Maintain aspect ratio.
      (define (map-x-to-pixels x) (exact-floor (* x height)))

      ; Image colour rows are presented top-down.
      ; So we'll have to flip the y-coordinate.
      (define (map-y-to-pixels y) (exact-floor (* (- ymax y) height)))

      (define (out-of-bounds xi yi)
        (or (< xi 0) (>= xi width) (< yi 0) (>= yi height)))

      ; The colour index into the rasterized image
      ; stored as a vector of rows of colours.
      (define (raster-index x y)
        (let ([xi (map-x-to-pixels x)]
              [yi (map-y-to-pixels y)])
          (if (out-of-bounds xi yi)
              #f
              (+ xi (* yi width)))))

      ; Now construct the (x,y) -> colour mapping
      (lambda (x y)
        (let ([index (raster-index x y)])
          (if index
              (vector-ref raster index)
              transparent-black))))))

(define (read-raster-image-to-vector width height maxcolourval)
  (when (not (and (positive-integer? width)
                  (positive-integer? height)))
    (error "Image dimensions must be positive integers -- at least 1x1"))
  (when (not (and (positive-integer? maxcolourval)
                  (< maxcolourval 256)))
    (error "Unsupported colour component size. Must be 1 byte sized."))
  
  ; Here we're constructing the raster image as a row-by-row
  ; sequence of colours. Equivalently, we can also have separate
  ; rasters for each colour component or use one vector for each
  ; row.
  (define raster (make-vector (* width height) (colour 0.0 0.0 0.0 0.0)))

  (let read-rgb-rows ([i 0])
    (let ([alpha 1.0]
          [red (/ (read-byte) maxcolourval)]
          [green (/ (read-byte) maxcolourval)]
          [blue (/ (read-byte) maxcolourval)])
      (vector-set! raster i (colour alpha red green blue))
      (read-rgb-rows (+ i 1))))

  raster)

  
#| THIS IS A BLOCK COMMENT

; A sample "image" that's a coloured disc of the given radius.
; Typically, you'd want the "outside-colour" to be totally
; transparent - i.e. have its alpha value be 0.0.
(define (disc radius inside-colour outside-colour)
  (lambda (x y)
    (if (<= (+ (* x x) (* y y)) (* radius radius))
        inside-colour
        outside-colour)))
|#

; Writes an image given as a mapping from (x,y) to colour as
; a PPM format file of the given name. The file must not already
; exist on the storage.
;
; The rectangular region of the image spanned by the bottom-left
; coordinates (x0,y0) and the top-right coordinates (x1,y1)
; are mapped to a "width x height" PPM image.
(define (write-ppm-image-to-file filename image x0 y0 x1 y1 width height)
  (with-output-to-file filename
    (lambda ()
      (write 'P6)
      (write-char #\space)
      (write width)
      (write-char #\space)
      (write height)
      (write-char #\space)
      (write 255) ; maxcolourval
      (write-char #\newline)

      (let ([dx (/ (- x1 x0) width)]
            [dy (/ (- y1 y0) height)])
        (let write-rgb-rows ([n (* width height)]
                             [x (+ x0 (* 0.5 dx))]
                             [y (- y1 (* 0.5 dy))])
          (when (> n 0)
            (let ([c (image x y)])
              (let ([r (* (colour-alpha c) (colour-red c))]
                    [g (* (colour-alpha c) (colour-green c))]
                    [b (* (colour-alpha c) (colour-blue c))])
                (write-byte (exact-round (* 255 r)))
                (write-byte (exact-round (* 255 g)))
                (write-byte (exact-round (* 255 b)))))
            (if (> (+ x dx) x1)
                (write-rgb-rows (- n 1) x0 (- y dy) dx dy)
                (write-rgb-rows (- n 1) (+ x dx) y dx dy))))))))
