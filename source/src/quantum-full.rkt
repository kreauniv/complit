#lang racket
(require racket/contract)
(require racket/flonum)
(require math/flonum)

(provide run-circuit)

(define operator-name/c (or/c 'H 'cnot 'swap 'cswap)) 
(define operator/c (-> operator-name/c any/c ... void?))
(define measure/c (-> nonnegative-integer?))
(define program/c (-> operator/c measure/c any))
(define (qubit-index/c N) (and/c integer? (>=/c 0) (</c N)))

#|
program = (λ (op measure) ...)
Below, i, j, k are qubit indices, theta is an angle in radians.
Gates usage -
  (op 'H i)
  (op 'cnot i j)
  (op 'swap i j)
  (op 'cswap i j k)
  (op 'toffoli i j k)
  (op 'X i)
  (op 'Y i)
  (op 'Z i)
  (op 'S i)
  (op 'T i)
  (op 'Rx i theta)
  (op 'Ry i theta)
  (op 'Rz i theta)
  (measure) -> integer state index
|#
(define/contract (run-circuit N initial-state program)
  (-> positive-integer? nonnegative-integer? program/c any/c)
  (define reg (make-statevec N initial-state))
  (define/contract (H i)
    (-> (qubit-index/c N) void?)
    (with-qubits reg N (list i)
      (λ (x ibit)
        (let* ([amp0 (svamp reg x)]
               [amp1 (svamp reg (+ x ibit))]
               [amp0h (* invsqrt2 (+ amp0 amp1))]
               [amp1h (* invsqrt2 (- amp0 amp1))])
          (svsetamp! reg x amp0h)
          (svsetamp! reg (+ x ibit) amp1h)))))
  (define/contract (cnot i j)
    (-> (qubit-index/c N) (qubit-index/c N) void?)
    (with-qubits reg N (list i j)
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
  (define/contract (toffoli i j k)
    (-> (qubit-index/c N) (qubit-index/c N) (qubit-index/c N) void?)
    (with-qubits N (list i j k)
      (λ (x ibit jbit kbit)
        (let* ([b110 (+ x ibit jbit)]
               [b111 (+ x ibit jbit kbit)]
               [amp110 (svamp reg b110)]
               [amp111 (svamp reg b111)])
          (svsetamp! reg b110 amp111)
          (svsetamp! reg b111 amp110)))))
  (define/contract (X i)
    (-> (qubit-index/c N) void?)
    (with-qubits N (list i)
      (λ (x ibit)
        (let ([a (svamp reg x)]
              [b (svamp reg (+ x ibit))])
          (svsetamp! reg (+ x ibit) a)
          (svsetamp! reg x b)))))
  (define/contract (Y i)
    (-> (qubit-index/c N) void?)
    (with-qubits N (list i)
      (λ (x ibit)
        (let ([a (svamp reg x)]
              [b (svamp reg (+ x ibit))])
          (svsetamp! reg (+ x ibit) (* 0+1i a))
          (svsetamp! reg x (* 0-1i b))))))
  (define/contract (Z i)
    (-> (qubit-index/c N) void?)
    (with-qubits N (list i)
      (λ (x ibit)
        (let ([amp1 (svamp reg (+ x ibit))])
          (svsetamp! reg (+ x ibit) (- amp1))))))
  (define/contract (S i)
    (-> (qubit-index/c N) void?)
    (with-qubits N (list i)
      (λ (x ibit)
        (let ([amp1 (svamp reg (+ x ibit))])
          (svsetamp! reg (+ x ibit) (* 0+1i amp1))))))
  (define/contract (T i)
    (-> (qubit-index/c N) void?)
    (with-qubits N (list i)
      (λ (x ibit)
        (let ([amp1 (svamp reg (+ x ibit))])
          (svsetamp! reg (+ x ibit) (* invsqrt2 1+1i amp1))))))
  (define/contract (Rx i theta)
    (-> (qubit-index/c N) real? void?)
    (let ([c (cos (* 0.5 theta))]
          [s (* 0-1i (sin (* 0.5 theta)))])
      (with-qubits N (list i)
        (λ (x ibit)
          (let* ([amp0 (svamp reg x)]
                 [amp1 (svamp reg (+ x ibit))]
                 [amp0rx (+ (* c amp0) (* s amp1))]
                 [amp1rx (+ (* s amp0) (* c amp1))])
            (svsetamp! reg x amp0rx)
            (svsetamp! reg (+ x ibit) amp1rx))))))
  (define/contract (Ry i theta)
    (-> (qubit-index/c N) real? void?)
    (let ([c (cos (* 0.5 theta))]
          [s (* -1 (sin (* 0.5 theta)))])
      (with-qubits N (list i)
        (λ (x ibit)
          (let* ([amp0 (svamp reg x)]
                 [amp1 (svamp reg (+ x ibit))]
                 [amp0ry (+ (* c amp0) (* s amp1))]
                 [amp1ry (+ (* s amp0) (* c amp1))])
            (svsetamp! reg x amp0ry)
            (svsetamp! reg (+ x ibit) amp1ry))))))
  (define/contract (Rz i theta)
    (-> (qubit-index/c N) real? void?)
    (let ([phinv (exp (* 0.5 0-1i theta))]
          [ph (exp (* 0.5 0+1i theta))])
      (with-qubits N (list i)
        (λ (x ibit)
          (let* ([amp0 (svamp reg x)]
                 [amp1 (svamp reg (+ x ibit))]
                 [amp0rz (* phinv amp0)]
                 [amp1rz (* ph amp1)])
            (svsetamp! reg x amp0rz)
            (svsetamp! reg (+ x ibit) amp1rz))))))
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
      [(swap) (apply swap args)]
      [(cswap) (apply cswap args)]
      [(toffoli) (apply toffoli args)]
      [(X) (apply X args)]
      [(Y) (apply Y args)]
      [(Z) (apply Z args)]
      [(S) (apply S args)]
      [(T) (apply T args)]
      [(Rx) (apply Rx args)]
      [(Ry) (apply Ry args)]
      [(Rz) (apply Rz args)]))
  (program op measure))

(define/contract sqrt2 flonum? (fl (sqrt 2)))
(define/contract invsqrt2 flonum? (fl (/ 1.0 sqrt2)))

; Performs the procedure `proc` once for each subspace of gate inputs.
(define/contract (with-qubits N bits proc)
  (->i ((N exact-positive-integer?)
        (bits (N) (listof (qubit-index/c N)))
        (proc procedure?))
       (result void?))
  (let* ([bitplaces (map (λ (k) (expt 2 k)) bits)]
         [bitmask (apply + bitplaces)])
    (let loop ([x 0] [xN (expt 2 N)])
      (when (< x xN)
        (when (= 0 (bitwise-and x bitmask))
          (apply proc x bitplaces))
        (loop (+ x 1) xN)))))

(define/contract (cabs2 c)
  (-> complex? real?)
  (real-part (* c (conjugate c))))

(define/contract (probability-accumulator)
  (-> (-> complex? real?))
  (let ([p 0.0])
    (lambda (c)
      (begin0 p (set! p (+ p (cabs2 c)))))))

(struct/contract statevec ((qubits exact-positive-integer?)
                           (length exact-positive-integer?)
                           (amps flvector?)))

(define/contract (cumulative-probability-distribution N reg)
  (-> positive-integer? statevec? (vectorof flonum?))
  (let* ([pacc (probability-accumulator)]
         [probs (for/vector #:length (+ N 1)
                  ((i (in-range 0 N)))
                  (pacc (svamp reg i)))])
    (vector-set! probs N (pacc 0.0))
    probs))

(define/contract (random-select cpdf)
  (-> (vectorof flonum?) exact-nonnegative-integer?)
  (let ([N (- (vector-length cpdf) 1)]
        [p (random)])
    (let loop ([i (- N 1)])
      (if (>= i 0)
          ; We can do binary search to speed this up, but keeping
          ; it simple for illustration.
          (if (>= p (vector-ref cpdf i)) i (loop (- i 1)))
          0))))

(define (state-index/c sv)
  (and/c exact-nonnegative-integer?
         (</c (expt 2 (statevec-qubits sv)))))

(define/contract (svamp sv i)
  (->i ((sv statevec?)
        (i (sv) (state-index/c sv)))
       (result complex?))
  (let ([amps (statevec-amps sv)]
        [ix (* 2 i)])
    (make-rectangular (flvector-ref amps ix)
                      (flvector-ref amps (+ 1 ix)))))
(define/contract (svsetamp! sv i v)
  (->i ((sv statevec?)
        (i (sv) (state-index/c sv))
        (v complex?))
       (result void?))
  (let ([amps (statevec-amps sv)]
        [ix (* i 2)])
    (flvector-set! amps ix (fl (real-part v)))
    (flvector-set! amps (+ 1 ix) (fl (imag-part v)))))
(define/contract (square x)
  (-> number? number?)
  (* x x))
(define/contract (svnorm sv)
  (-> statevec? real?)
  (let sum ([i 0] [N (* 2 (statevec-length sv))] [acc 0.0])
    (if (>= i N)
        acc
        (sum (+ i 1) (+ acc (square (flvector-ref statevec-amps i)))))))

(define/contract (make-statevec qubits initial-state)
  (-> exact-positive-integer? exact-nonnegative-integer? statevec?)
  ; Even index positions are real part, odd index positions are imaginary part
  ; in the amplitudes vector.
  (let* ([N (expt 2 qubits)]
         [sv (statevec qubits N (make-flvector (* 2 N) 0.0))])
    (svsetamp! sv initial-state 1+0i)
    sv))
