#lang racket
(require racket/contract)
(require racket/flonum)
(require math/flonum)

(provide run-circuit)

(define operator-name/c (or/c 'H 'cnot 'swap 'cswap)) 
(define operator/c (-> operator-name/c any/c ... void?))
(define measure/c (-> nonnegative-integer?))
(define program/c (-> operator/c measure/c any/c ... any/c))
(define (qubit-index/c N) (and/c integer? (>=/c 0) (</c N)))

#|
program = (λ (op measure . args) ...)
Below, i, j, k are qubit indices, theta is an angle in radians.
Gates usage -
  (op 'H i)
  (op 'cnot i j)      ; i is control qubit and j is the controlled qubit.
  (op 'swap i j)
  (op 'cswap i j k)   ; i is the control qubit
  (measure) -> integer state index

Example circuit -

q0 --- H ---o---- H --- [/]
            |
q1 ---------X----------

(run-circuit 2 3 empty
   (lambda (op measure)
      (op 'H 0)
      (op 'cnot 0 1)
      (op 'H 0)
      (measure)))
|#
(define/contract (run-circuit N initial-state args program)
  (-> positive-integer? nonnegative-integer? list? program/c any/c)
  (define reg (make-statevec N initial-state))
  (define/contract (H i)
    (-> (qubit-index/c N) void?)
    (with-qubits N (list i)
      (λ (x ibit)
        (let* ([amp0 (svamp reg x)]
               [amp1 (svamp reg (+ x ibit))]
               [amp0h (* invsqrt2 (+ amp0 amp1))]
               [amp1h (* invsqrt2 (- amp0 amp1))])
          (svsetamp! reg x amp0h)
          (svsetamp! reg (+ x ibit) amp1h)))))
  (define/contract (cnot i j)
    (-> (qubit-index/c N) (qubit-index/c N) void?)
    (with-qubits N (list i j)
      (λ (x ibit jbit)
        (let* ([b10 (+ x ibit)]
               [b11 (+ x ibit jbit)]
               [amp10 (svamp reg b10)]
               [amp11 (svamp reg b11)])
          (svsetamp! reg b10 amp11)
          (svsetamp! reg b11 amp10)))))
  (define/contract (swap i j)
    (-> (qubit-index/c N) (qubit-index/c N) void?)
    (with-qubits N (list i j)
      (λ (x ibit jbit)
        (let* ([b10 (+ x ibit)]
               [b01 (+ x jbit)]
               [amp10 (svamp reg b10)]
               [amp01 (svamp reg b01)])
          (svsetamp! reg b10 amp01)
          (svsetamp! reg b01 amp10)))))
  (define/contract (cswap i j k)
    (-> (qubit-index/c N) (qubit-index/c N) (qubit-index/c N) void?)
    (with-qubits N (list i j k)
      (λ (x ibit jbit kbit)
        (let* ([b101 (+ x ibit kbit)]
               [b110 (+ x ibit jbit)]
               [amp101 (svamp reg b101)]
               [amp110 (svamp reg b110)])
          (svsetamp! reg b101 amp110)
          (svsetamp! reg b110 amp101)))))
  (define/contract (measure) measure/c
    (let* ([probs (cumulative-probability-distribution (expt 2 N) reg)]
           [state (random-select probs)]
           [amp (svamp reg state)])
      ; Collapse the state
      (for ([i (in-range 0 (expt 2 N))])
        (svsetamp! reg i 0+0i))
      ; Preserve the phase.
      (svsetamp! reg state (/ amp (sqrt (cabs2 amp))))
      state))
  (define/contract (op name . args)
    (-> operator-name/c any/c ... any/c)
    (case name
      [(H) (apply H args)]
      [(cnot) (apply cnot args)]
      [(swap) (apply cnot args)]
      [(cswap) (apply cnot args)]))
  (apply program op measure args))

(define sqrt2 (fl (sqrt 2)))
(define invsqrt2 (fl (/ 1.0 sqrt2)))

; Performs the procedure `proc` once for each subspace of gate inputs.
(define (with-qubits N bits proc)
  (let* ([bitplaces (map (λ (k) (expt 2 k)) bits)]
         [bitmask (apply + bitplaces)])
    (let loop ([x 0] [xN (expt 2 N)])
      (when (< x xN)
        (when (= 0 (bitwise-and x bitmask))
          (apply proc x bitplaces))
        (loop (+ x 1) xN)))))

(define (cabs2 c) (real-part (* c (conjugate c))))

(define (probability-accumulator)
  (let ([p 0.0])
    (lambda (c)
      (begin0 p (set! p (+ p (cabs2 c)))))))

(define (cumulative-probability-distribution N reg)
  (let* ([pacc (probability-accumulator)]
         [probs (for/vector #:length (+ N 1)
                  ((i (in-range 0 N)))
                  (pacc (svamp reg i)))])
    (vector-set! probs N (pacc 0.0))
    probs))

(define/contract (random-select cpdf)
  (-> any/c nonnegative-integer?)
  (let ([N (- (vector-length cpdf) 1)]
        [p (random)])
    (let loop ([i (- N 1)])
      (if (>= i 0)
          ; We can do binary search to speed this up, but keeping
          ; it simple for illustration.
          (if (>= p (vector-ref cpdf i)) i (loop (- i 1)))
          0))))
                                  
(struct statevec (qubits length amps))
(define (svamp sv i)
  (let ([amps (statevec-amps sv)]
        [ix (* 2 i)])
    (make-rectangular (flvector-ref amps ix)
                      (flvector-ref amps (+ 1 ix)))))
(define (svsetamp! sv i v)
  (let ([amps (statevec-amps sv)]
        [ix (* i 2)])
    (flvector-set! amps ix (fl (real-part v)))
    (flvector-set! amps (+ 1 ix) (fl (imag-part v)))))
(define (square x) (* x x))
(define (svnorm sv)
  (let sum ([i 0] [N (* 2 (statevec-length sv))] [acc 0.0])
    (if (>= i N)
        acc
        (sum (+ i 1) (+ acc (square (flvector-ref statevec-amps i)))))))

(define (make-statevec qubits initial-state)
  ; Even index positions are real part, odd index positions are imaginary part
  ; in the amplitudes vector.
  (let* ([N (expt 2 qubits)]
         [sv (statevec qubits N (make-flvector (* 2 N) 0.0))])
    (svsetamp! sv initial-state 1+0i)
    sv))
