TicTacToe
=========

The program below implements a two-player tictactoe game.

.. code-block:: racket
   :linenos:
   :caption: Simple two player tictactoe game.

   #lang racket

   (define (tictactoe cross?)
     (let play-turn ([board "........."] [cross? cross?])
       (displayln (string-append (substring board 0 3) "\n"
                                 (substring board 3 6) "\n"
                                 (substring board 6 9) "\n"))
       (if (string-contains? board ".")
           (if (or (string=? "xxx" (substring board 0 3))
                   (string=? "xxx" (substring board 4 6))
                   (string=? "xxx" (substring board 7 9))
                   (string=? "xxx" (string-append (substring board 0 1)
                                                  (substring board 4 5)
                                                  (substring board 8 9)))
                   (string=? "xxx" (string-append (substring board 2 3)
                                                  (substring board 4 5)
                                                  (substring board 6 7)))
                   (string=? "xxx" (string-append (substring board 0 1)
                                                  (substring board 3 4)
                                                  (substring board 6 7)))
                   (string=? "xxx" (string-append (substring board 1 2)
                                                  (substring board 4 5)
                                                  (substring board 7 8)))
                   (string=? "xxx" (string-append (substring board 2 3)
                                                  (substring board 5 6)
                                                  (substring board 8 9))))
               'x-won
               (if (or (string=? "ooo" (substring board 0 3))
                       (string=? "ooo" (substring board 4 6))
                       (string=? "ooo" (substring board 7 9))
                       (string=? "ooo" (string-append (substring board 0 1)
                                                      (substring board 4 5)
                                                      (substring board 8 9)))
                       (string=? "ooo" (string-append (substring board 2 3)
                                                      (substring board 4 5)
                                                      (substring board 6 7)))
                       (string=? "ooo" (string-append (substring board 0 1)
                                                      (substring board 3 4)
                                                      (substring board 6 7)))
                       (string=? "ooo" (string-append (substring board 1 2)
                                                      (substring board 4 5)
                                                      (substring board 7 8)))
                       (string=? "ooo" (string-append (substring board 2 3)
                                                      (substring board 5 6)
                                                      (substring board 8 9))))
                   'o-won
                   (let ([next-pos (- (read) 1)])
                     (if (equal? (string-ref board next-pos) #\.)
                         (play-turn (string-append (substring board 0 next-pos)
                                                   (if cross? "x" "o")
                                                   (substring board (+ 1 next-pos) 9))
                                    (not cross?))
                         (begin (displayln "Invalid position. Try again.")
                                (play-turn board cross?))))))
           (displayln "Game over"))))

.. admonition:: **Task**

   Go through the same process as with the :doc:`number-guessing-game` to arrive
   at a legible program for playing the same game. Remember that when you're
   starting with this, you probably don't "understand" the program and that's
   ok and expected. Your goal is to "interrogate" and along the way edit/rewrite parts
   of the program step by step to arrive at a final version that is more easily
   understood. For reference about documenting abstractions (a.k.a. "procedures"
   or "functions") see `Systematic program design`_.

.. tip:: Approach the process using the scientific method. You're welcome to
   make "guesses" (i.e. "hypotheses") as to what a particular form means, but
   it would then be up to you to verify, at some point, whether your guess
   turned out to be valid.


.. _Systematic program design: https://htdp.org/2026-5-28//Book/part_preface.html#(part._sec~3asystematic-design)
