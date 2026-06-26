#lang racket

(struct pattern-match (result remainder) #:transparent)

(define (parse pattern text)
  (pattern text))

(define (character-in charset)
  (define (pattern text)
    (if (> (string-length text) 0)
        (let ([first-char (string-ref text 0)])
          (if (string-contains? charset (string first-char))
              (pattern-match first-char (substring text 1))
              #f))
        #f))
  pattern)

(define (character-not-in set)
  (define (pattern text)
    (if (> (string-length text) 0)
        (let ([first-char (string-ref text 0)])
          (if (string-contains? set (string first-char))
              #f
              (pattern-match first-char (substring text 1))))
        #f))
  pattern)

(define (sequence pat1 pat2)
  (define (pattern text)
    (let ([p1 (parse pat1 text)])
      (if p1
          (let ([p2 (parse pat2 (pattern-match-remainder p1))])
            (if p2
                (pattern-match (cons (pattern-match-result p1)
                                     (pattern-match-result p2))
                               (pattern-match-remainder p2))
                #f))
          #f)))
  pattern)

(define (sequence* . pats)
  (if (empty? pats)
      empty-pattern
      (sequence (first pats) (apply sequence* (rest pats)))))
             
(define (empty-pattern text)
  (pattern-match empty text))

(define (alternatives . pats)
  (define (pattern text)
    (if (empty? pats)
        #f
        (or (parse (first pats) text)
            (parse (apply alternatives (rest pats)) text))))
  pattern)

(define (one-of pat1 pat2)
  (alternatives pat1 pat2))

(define (optional pat)
  (alternatives pat empty-pattern))

(define-syntax (later syntax-object)
  (syntax-case syntax-object ()
    [(_ pat) #'(lambda (text) (pat text))]))

(define (one-or-more pat)
  (sequence pat (later (zero-or-more pat))))

(define (zero-or-more pat)
  (alternatives (one-or-more pat) empty-pattern))

(define (reinterpret interpretation pat)
  (define (pattern text)
    (let ([p1 (parse pat text)])
      (if p1
          (pattern-match (interpretation (pattern-match-result p1))
                         (pattern-match-remainder p1))
          #f)))
  pattern)

(define (literal str)
  (lambda (text)
    (if (>= (string-length text) (string-length str))
        (if (string-prefix? text str)
            (pattern-match str (substring text (string-length str)))
            #f)
        #f)))

(define (first-occurrence pat)
  (define (pattern text)
    (if (> (string-length text) 0)
        ; Try at the starting position
        (let ([p (parse pat text)])
          (if p
              p
              ; If failed at start, skip one character and
              ; try again. Keep doing this until you either
              ; find a match or reach the end of the string.
              (pattern (substring text 1))))
        #f))
  pattern)

(define (upto-first-occurrence pat (include-end? #t))
  (define (pattern text)
    (let step ([i 0] [N (string-length text)])
      (if (< i N)
          (let ([p (parse pat (substring text i))])
            (if p
                (pattern-match (substring text 0 i) (pattern-match-remainder p))
                (step (+ i 1) N)))
          (if (and (> N 0) include-end?)
              (pattern-match text "")
              #f))))
  pattern)

(define line (upto-first-occurrence (one-of (literal "\r\n")
                                            (literal "\n"))))
(define lines (zero-or-more line))

(define digit (character-in "0123456789"))

(define (decimal-pattern->number result)
  (let ([sign (first result)]
        [main (second result)]
        [dec (third result)])
    (string->number (list->string (apply append
                                         (if (empty? sign) empty (list sign))
                                         (rest result))))))

(define decimal-number
  (reinterpret decimal-pattern->number
               (sequence* (optional (character-in "-+"))
                          (one-or-more digit)
                          (optional (sequence (character-in ".")
                                              (one-or-more digit))))))




