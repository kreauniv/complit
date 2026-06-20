TicTacToe
=========

The program below implements a two-player tictactoe game.

.. literalinclude:: tictactoe.rkt
   :language: racket
   :linenos:
   :caption: Simple two player tictactoe game.

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

.. tip:: A good rule of thumb is that when the pattern of an expression repeats
   in some sense, there is perhaps a concept waiting to be abstracted from the
   repetitions.


.. _Systematic program design: https://htdp.org/2026-5-28//Book/part_preface.html#(part._sec~3asystematic-design)
