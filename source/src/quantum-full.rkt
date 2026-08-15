#lang racket
(require racket/flonum)
(require math/flonum)

(provide run-circuit)

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
(define (run-circuit N initial-state program)
  (define reg (make-statevec N initial-state))
  (define (H i)
    (with-qubits reg N (list i)
      (λ (x ibit)
        (let* ([amp0 (svamp reg x)]
               [amp1 (svamp reg (+ x ibit))]
               [amp0h (* invsqrt2 (+ amp0 amp1))]
               [amp1h (* invsqrt2 (- amp0 amp1))])
          (svsetamp! reg x amp0h)
          (svsetamp! reg (+ x ibit) amp1h)))))
  (define (cnot i j)
    (with-qubits reg N (list i j)
      (λ (x ibit jbit)
        (let* ([b10 (+ x ibit)]
               [b11 (+ x ibit jbit)]
               [amp10 (svamp reg b10)]
               [amp11 (svamp reg b11)])
          (svsetamp! reg b10 amp11)
          (svsetamp! reg b11 amp10)))))
  (define (swap i j)
    (with-qubits reg N (list i j)
      (λ (x ibit jbit)
        (let* ([b10 (+ x ibit)]
               [b01 (+ x jbit)]
               [amp10 (svamp reg b10)]
               [amp01 (svamp reg b01)])
          (svsetamp! reg b10 amp01)
          (svsetamp! reg b01 amp10)))))
  (define (cswap i j k)
    (with-qubits reg N (list i j k)
      (λ (x ibit jbit kbit)
        (let* ([b101 (+ x ibit kbit)]
               [b110 (+ x ibit jbit)]
               [amp101 (svamp reg b101)]
               [amp110 (svamp reg b110)])
          (svsetamp! reg b101 amp110)
          (svsetamp! reg b110 amp101)))))
  (define (toffoli i j k)
    (with-qubits reg N (list i j k)
      (λ (x ibit jbit kbit)
        (let* ([b110 (+ x ibit jbit)]
               [b111 (+ x ibit jbit kbit)]
               [amp110 (svamp reg b110)]
               [amp111 (svamp reg b111)])
          (svsetamp! reg b110 amp111)
          (svsetamp! reg b111 amp110)))))
  (define (X i)
    (with-qubits reg N (list i)
      (λ (x ibit)
        (let ([a (svamp reg x)]
              [b (svamp reg (+ x ibit))])
          (svsetamp! reg (+ x ibit) a)
          (svsetamp! reg x b)))))
  (define (Y i)
    (with-qubits reg N (list i)
      (λ (x ibit)
        (let ([a (svamp reg x)]
              [b (svamp reg (+ x ibit))])
          (svsetamp! reg (+ x ibit) (* 0+1i a))
          (svsetamp! reg x (* 0-1i b))))))
  (define (Z i)
    (with-qubits reg N (list i)
      (λ (x ibit)
        (let ([amp1 (svamp reg (+ x ibit))])
          (svsetamp! reg (+ x ibit) (- amp1))))))
  (define (S i)
    (with-qubits reg N (list i)
      (λ (x ibit)
        (let ([amp1 (svamp reg (+ x ibit))])
          (svsetamp! reg (+ x ibit) (* 0+1i amp1))))))
  (define (T i)
    (with-qubits reg N (list i)
      (λ (x ibit)
        (let ([amp1 (svamp reg (+ x ibit))])
          (svsetamp! reg (+ x ibit) (* invsqrt2 1+1i amp1))))))
  (define (Rx i theta)
    (let ([c (cos (* 0.5 theta))]
          [s (* 0-1i (sin (* 0.5 theta)))])
      (with-qubits reg N (list i)
        (λ (x ibit)
          (let* ([amp0 (svamp reg x)]
                 [amp1 (svamp reg (+ x ibit))]
                 [amp0rx (+ (* c amp0) (* s amp1))]
                 [amp1rx (+ (* s amp0) (* c amp1))])
            (svsetamp! reg x amp0rx)
            (svsetamp! reg (+ x ibit) amp1rx))))))
  (define (Ry i theta)
    (let ([c (cos (* 0.5 theta))]
          [s (* -1 (sin (* 0.5 theta)))])
      (with-qubits reg N (list i)
        (λ (x ibit)
          (let* ([amp0 (svamp reg x)]
                 [amp1 (svamp reg (+ x ibit))]
                 [amp0ry (+ (* c amp0) (* s amp1))]
                 [amp1ry (+ (* s amp0) (* c amp1))])
            (svsetamp! reg x amp0ry)
            (svsetamp! reg (+ x ibit) amp1ry))))))
  (define (Rz i theta)
    (let ([phinv (exp (* 0.5 0-1i theta))]
          [ph (exp (* 0.5 0+1i theta))])
      (with-qubits reg N (list i)
        (λ (x ibit)
          (let* ([amp0 (svamp reg x)]
                 [amp1 (svamp reg (+ x ibit))]
                 [amp0rz (* phinv amp0)]
                 [amp1rz (* ph amp1)])
            (svsetamp! reg x amp0rz)
            (svsetamp! reg (+ x ibit) amp1rz))))))
  (define (measure)
    (let* ([probs (cumulative-probability-distribution (expt 2 N) reg)]
           [state (random-select probs)]
           [amp (svamp reg state)])
      ; Collapse the state
      (for ([i (in-range 0 (expt 2 N))])
        (svsetamp! reg i 0+0i))
      ; Preserve the phase.
      (svsetamp! reg state (/ amp (sqrt (cabs2 amp))))
      state))
  (define (op name . args)
    (case name
      [('H) (apply H args)]
      [('cnot) (apply cnot args)]
      [('swap) (apply swap args)]
      [('cswap) (apply cswap args)]
      [('toffoli) (apply toffoli args)]
      [('X) (apply X args)]
      [('Y) (apply Y args)]
      [('Z) (apply Z args)]
      [('S) (apply S args)]
      [('T) (apply T args)]
      [('Rx) (apply Rx args)]
      [('Ry) (apply Ry args)]
      [('Rz) (apply Rz args)]
      [else (error (format "Unknown operator: ~a" name))]))
  (program op measure))

(define sqrt2 (fl (sqrt 2)))
(define invsqrt2 (fl (/ 1.0 sqrt2)))

; Performs the procedure `proc` once for each subspace of gate inputs.
(define (with-qubits reg N bits proc)
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

(define (random-select cpdf)
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
