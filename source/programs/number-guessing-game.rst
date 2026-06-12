The number guessing game
========================

In this section we're going to look at a number of implementations of the same
program -- which plays a number guessing game with the user. The program will
pick a secret number in a given range and the player is expected to guess the
value in the smallest number of turns they can manage. Along the way, the
program will give clues about how the player is doing.

A first version
---------------

.. code-block:: racket
   :linenos:
   :caption: The first version.
   :name: nggv1

   (define (run max-number)
      (displayln "Let's play a number guessing game.")
      (display "I'll pick a number from 1 to ") (display max-number) (displayln ".")
      (displayln "You have to guess it in the fewest attempts you can.")
      (define random-number (random 1 (+ 1 max-number)))
      (define user-input (box #f)) 
      (display "Your guess: ")
      (let loop ([attempts 1])
          (set-box! user-input (read))
          (if (= (unbox user-input) random-number)
              (begin (display "You guessed it in ")
                     (display attempts)
                     (displayln "attempts!"))
              (if (< (unbox user-input) random-number)
                  (begin (display "It's higher. Guess again: ")
                         (loop (+ 1 attempts)))
                  (begin (display "It's lower. Guess again: ")
                         (loop (+ 1 attempts)))))))
              
First off, run the program to see what its purpose is.

.. note:: The **purpose** of a program is **what it does**. This is
   a deeper statement than what it looks like at first and which has
   not only consequences for understanding and constructing programs
   (correctly), it also has consequences for the ethics embodied in
   the program. Take five minutes to mull over this if you'd like,
   using examples from your experience (where you only run the programs
   without looking at their code) to examine your thinking.

Consider how you'll describe this program when asked, if you didn't happen
to know it is a number guessing game or much of the vocabulary used in
ordinary Racket programs. It might go something like -

- It looks like this is a program that takes in a "maximum number" to run.
- "Hmm what does ``display`` do? It seems related to ``displayln`` as well."
  (Go away and find out what it does, through the manual or through interrogation.)
- "Ah so the first few lines are printing out some initial messages for the
  user about some 'number guessing game'".
- "Hmm what does ``random`` do?" (again go away and find out). "Why is it
  ``(random 1 (+ 1 max-number))`` and not just ``(random 1 max-number)``?
  (experiment and find out). "Ok so this is picking a random number in the range
  1 to ``max-number``, inclusive."
- "Hmm what is ``box``?" .. and you find out that it makes a box whose contents
  can be retrieved using ``unbox`` and changed using ``set-box!``. So we're making
  a storage place to store the user input.
- We're starting some sort of a loop that seems to be keeping track of ``attempts``.
  (You still don't know what ``(let loop ...)`` does, but proceed with guess work
  for now.)
- The program reads the player's input and store it in the ``user-input`` box.
- If the player entered the same number as the random number selected earlier,
  the program tells the user the number of attempts they took.
- If not, the programs gives a hint about guessing higher or lower and continues
  the loop, incrementing the number of attempts taken so far.

If you're the curious kind (hope so), you'll go ahead and read up what the
``(let loop ..)`` form does and get a little lost in a rabbit hole perhaps, or
stop when you feel you understand it sufficiently.

Notice the following about the above description --

1. You're literally reading the program bit by bit without knowing its purpose.
   This is akin to reading the genetic code of a creature having no idea what
   the A/T/G/C sequences actually do to the creature's form and function. But
   somehow because you can run the program and find things out by
   "interrogation", you now have some idea that this is a number guessing game.

2. You've figured out that the ``random-number`` identifier gets bound to a,
   ahem, random number which is not displayed to the player and thus remains a
   "secret" until the program declares the player to have found it.

3. You've gathered that the ``user-input`` box must store a number that the
   is the user's next guess.

4. You've figure out that each turn of the "loop" plays one "round" of the game,
   and keeps track of the number of attempts made up to the point the player is
   asked for their next guess.

5. The programs gives a "guess higher" and "guess lower" kind of hint to the
   player at each turn.

Now consider the question of how you'd like to have written this program so its
**purpose** is obvious from the form of the program.

To start with, we can rename ``run`` to ``play-number-guess-game`` to make it 
absolutely clear and give strong hints to the reader.

.. code:: racket

    (define (play-number-guessing-game max-number) ...)

Consider the first three lines of the program that greet the player and tell them
about the game and what to do --

.. code:: racket

   (displayln "Let's play a number guessing game.")
   (display "I'll pick a number from 1 to ") (display max-number) (displayln ".")
   (displayln "You have to guess it in the fewest attempts you can.")

The only word that is not already known from the whole program's context is ``max-number``,
which is provided as an argument to ``play-number-guessing-game`` (note changed name).
Apart from that, these three lines are greeting the player. So we can wrap them in
an abstraction that makes the purpose of these three lines clear --

.. code:: racket

   (define (greet-player max-number)
       (displayln "Let's play a number guessing game.")
       (display "I'll pick a number from 1 to ") (display max-number) (displayln ".")
       (displayln "You have to guess it in the fewest attempts you can."))

.. tip:: To make such an "extraction" as ``greet-player``, first identify the what
   you wish to extract by selecting the expressions. In this case, the three ``display..``
   expressions can be considered as though they were nested within a ``(begin ..)``
   form, so we can pull it out this way into the "top level" of the definitions window.
   
   Since ``displayln`` and ``display`` take their meaning from the ``#lang racket``
   context, the only identifier that needs introduction is ``max-number``. So we
   make that an argument of ``greet-player``.

   1. Select those three expressions in DrRacket and "cut" (Cmd-X or Ctrl-X).
   2. Type ``(greet-player max-number)`` in place of the cut expressions.
   3. Now move to the end of the file (or any suitable definition position)
      and type ``(define (greet-player max-number)``, press the <enter> key,
      and paste the cut expressions (using Cmd-V or Ctrl-V).
   4. Close the definitions expression with a final closing parenthesis ``)``.

.. admonition:: **Useful equivalences with ``begin``**

   1. ``(define (proc a1 a2 ...) (begin <expr1> <expr2> ...))`` is
      equivalent to ``(define (proc a1 a2 ...) <expr1> <expr2> ...)``.
   2. ``(begin <expr1> (begin <expr2> <expr3>) <expr4>)`` is
      equivalent to ``(begin <expr1> <expr2> <expr3> <expr4>)``.

   So when you see sequences of expressions within a procedure definition,
   think there is an implicit ``begin`` enclosing them all, or any
   subsequence of the expressions.


Add this definition at the end of the file. Once we do this, the start of the
program can now be rewritten in terms of ``greet-player`` **without any change
in behaviour**.

.. code:: racket

    (define (play-number-guessing-game max-number)
        (greet-player max-number)
        ...)

We now understand that the line ``(define random-number (random 1 (+ 1 max-number)))`` is
picking a secret. So let's do a simple change to make this clearer -- right-click (or ctrl-click)
the identifier ``random-number`` and choose "Rename". Give it a new meaningful name like
``secret``. Notice that all appropriate occurrences of this identifier will be changed
by DrRacket to use the new name.

.. code:: racket

    (define secret (random 1 (+ 1 max-number)))

Similarly, we understand the ``user-input`` box to hold the player's guess, and can
rename it, using the same process, to read ``players-guess`` instead for clarity.

.. code:: racket

   (define players-guess (box #f))

We now understand that each step of the "loop" is a player's turn and can also make that
clear by renaming ``loop`` to ``play-till-win``, using the same renaming steps.

.. code:: racket

   (let play-till-win ...)

The program is still doing exactly the same things, but is starting to read a little clearer
simply due to good names we're choosing.

So now what does the expression ``(set-box! players-guess (read))`` mean? This is asking the
user's next guess (remember we renamed ``user-input`` to ``players-guess``. Since it depends on 
the ``players-guess`` box, we can make the following abstraction to capture this --

.. code:: racket

   (define (ask-players-guess guess)
      (set-box! guess (read)))

And then rewrite the line as ``(ask-players-guess players-guess)``. It seems to
have some redundant words, but we can live with it for now. By now, we can probably
make the connection that each 'turn' of the game involves asking the player's next guess
and incrementing the number of attempts taken. So we can eliminate the use of a "box"
here and reuse the ``play-till-win`` loop like this --

.. code:: racket

   (let play-till-win ([next-guess (read)] [attempts 1])

It's good to examine our whole rewritten program so far --

.. code-block:: racket
   :linenos:
   :caption: The second version
   :name: nggv2

   (define (play-number-guessing-game max-number)
      (greet-player max-number)
      (define secret (random 1 (+ 1 max-number)))
      (display "Your guess: ")
      (let play-till-win ([next-guess (read)]
                           [attempts 1])
          (if (= next-guess secret)
              (begin (display "You guessed it in ")
                     (display attempts)
                     (displayln "attempts!"))
              (if (< next-guess secret)
                  (begin (display "It's higher. Guess again: ")
                         (loop (read) (+ 1 attempts)))
                  (begin (display "It's lower. Guess again: ")
                         (loop (read) (+ 1 attempts)))))))
      
   (define (greet-player max-number)
       (displayln "Let's play a number guessing game.")
       (display "I'll pick a number from 1 to ") (display max-number) (displayln ".")
       (displayln "You have to guess it in the fewest attempts you can."))

Now this is much better since we've simplified by **reducing** the number of
concepts required to understand the program.

Now we're starting to see the intent more clearly. The next step is to see that
``(begin (display ..))`` between lines 8-10 in :ref:`the second version <nggv2>`
declares that the player has won and reports the number of attempts made. So
we can make that clear using an abstraction as well.

.. code:: racket

   (define (declare-win attempts)
       (display "You guessed it in ")
       (display attempts)
       (displayln "attempts!"))

We also see that lines 12-13 and 14-15 of nggv2_ are *nearly* the same except for
"higher" and "lower", which we now understand give the player a clue about how
to proceed. We can capture this redundancy as an abstraction as well --

.. code:: racket

   (define (clue next-guess secret)
      (if (< next-guess secret)
          "It's higher."
          (if (> next-guess secret)
              "It's lower."
              (error "No clue should be needed."))))

We see that this ``clue`` abstraction only deals with the case where
``next-guess`` is **different** from ``secret``. So it must necessarily error
out when they happen to be the same, as no clue remains to be given.
However, in the program, ``clue`` is used exactly in a valid context
only.

.. admonition:: **Terminology**

   Such a ``clue`` procedure that is valid only for some argument values and is
   considered invalid for others and "errors out" is called a **partial
   function**. Conversely if a function [#fn]_ will produce values for any
   arguments that meet some basic type constraints (like ``string?`` or
   ``integer?``) are called **total functions**.

We can now replace line 12-15 with just --

.. code:: racket

   (begin (display (clue next-guess secret))
          (display " Guess again: ")
          (loop (read) (+ 1 attempts)))

Putting all of that together, we get our "version 3" below --
                   
.. code-block:: racket
   :linenos:
   :caption: The third version.
   :name: nggv3

   (define (play-number-guessing-game max-number)
      (greet-player max-number)
      (define secret (random 1 (+ 1 max-number)))
      (display "Your guess: ")
      (let play-till-win ([next-guess (read)]
                           [attempts 1])
          (if (= next-guess secret)
              (declare-win attempts)
              (begin (display (clue next-guess secret))
                     (display " Guess again: ")
                     (play-till-win (read) (+ 1 attempts))))))
      
   (define (greet-player max-number)
       (displayln "Let's play a number guessing game.")
       (display "I'll pick a number from 1 to ") (display max-number) (displayln ".")
       (displayln "You have to guess it in the fewest attempts you can."))

   (define (clue next-guess secret)
      (if (< next-guess secret)
          "It's higher."
          (if (> next-guess secret)
              "It's lower."
              (error "No clue should be needed."))))

   (define (declare-win attempts)
       (display "You guessed it in ")
       (display attempts)
       (displayln "attempts!"))

The moral of this whole story is that the top level
``play-number-guessing-game`` almost reads in a self-explanatory manner, with
our usual understanding of words like ``greet-player`` and ``clue`` filling in
all the details, much like how we can out together "horse in a box cart" to
form a mental image based on our understanding of "horse", "box" and "cart".
We now only need to read line 1-11 in :ref:`the third version <nggv3>` compared
to lines 1-18 in :ref:`the first version <nggv1>` to have a top level understanding
of the program.

Digging deeper into evalution
-----------------------------

With :ref:`the latest version <nggv3>` of the program, it is now possible to
see that the ``(display "Your guess: ")`` is immediately followed by the
``(read)`` step in line 5. The same pattern also occurs when we come to
``play-till-win``, but with a different prompt ``"Guess again: "``. The
purpose of both is the same -- to prompt the user for their next input. We can
therefore club these two and make that purpose clear as well. This particular
step requires a **closer examination** of what's going on than merely paying
attention to the form of the code.

.. code:: racket

   (define (ask-next-guess prompt)
      (display prompt)
      (display " ")
      (read))


With that, the top level procedure now becomes --

.. code-block:: racket
   :caption: The fourth version.
   :linenos:
   :name: nggv4

    (define (play-number-guessing-game max-number)
        (greet-player max-number)
        (define secret (random 1 (+ 1 max-number)))
        (let play-till-win ([next-guess (ask-next-guess "Your guess:")]
                            [attempts 1])
            (if (= next-guess secret)
                (declare-win attempts)
                (begin (display (clue next-guess secret)) (display " ")
                       (play-till-win (ask-next-guess "Guess again:")
                                       (+ 1 attempts))))))

We can now see that ``play-till-win`` is itself a genuine abstraction, though
we're expressing it using ``(let play-till-win ..)`` construct. We can further
make the program accessible by eliminating this construct too and by turning
``play-till-win`` into a stand alone abstraction.

.. code-block:: racket
   :name: nggv5
   :caption: The fifth version.
   :linenos:

    (define (play-number-guessing-game max-number)
        (greet-player max-number)
        (define secret (random 1 (+ 1 max-number)))
        (define attempts 1)
        (play-till-win secret (ask-next-guess "Your guess:") attempts))

    (define (play-till-win secret next-guess attempts)
        (if (= next-guess secret)
            (declare-win attempts)
            (begin (display (clue next-guess secret)) (display " ")
                   (play-till-win secret
                                   (ask-next-guess "Guess again:")
                                   (+ 1 attempts)))))

In this version, we find that ``secret`` which was accessible to the body
of the loop, no longer becomes accessible and we need to pass it as an
argument. Otherwise, the form looks nearly the same and we can understand
the program even more easily.

It is important to note that these kinds of steps are not unique and if you
try it on your own you might end up with a slightly different form. That's ok,
as long as the form makes sense to you and you think it clearly communicates
your intent. For example, we might've done it slightly differently like this --

.. code-block:: racket
   :name: nggv5b
   :caption: Another fifth version.
   :linenos:

    (define (play-number-guessing-game max-number)
        (greet-player max-number)
        (define secret (random 1 (+ 1 max-number)))
        (define attempts 1)
        (play-till-win secret "Your guess:" attempts))

    (define (play-till-win secret prompt attempts)
      (let ([next-guess (ask-next-guess prompt)])
         (if (= next-guess secret)
             (declare-win attempts)
             (begin (display (clue next-guess secret)) (display " ")
                    (play-till-win secret
                                    "Guess again:"
                                    (+ 1 attempts)))))

Here, we've folded the ``ask-next-guess`` step into ``play-till-win`` and
that's fine too.

.. admonition:: **FYI**

   Wrapping a portion of code into an "abstraction" has a cognitive benefit
   for the reader by using our "chunking_" ability. 

.. _chunking: https://www.cognitivepsychology.com/Chunking

Taking stock
------------

The :ref:`latest version <nggv4>` of the top level program is now much
closer to expressing the full intent of the number guessing game. You can
pretty much just read it from start to finish and keep going because we're
using words that are **in the domain** of the program. Words like
"game", "secret", "guess", "turn", "attempt", "greet", "clue" and "win".
These words fully clue the reader into the purpose of the program.

So far, all the modifications we've done to the program to bring it into
this form preserve exactly what :ref:`the first version <nggv1>` did
without any changes. So let's wrap this up by writing a comment explaining
the **purpose** of the program in plain language for the reader, to reduce
their mental load even more.

.. code:: racket

    ; Plays a "number guessing game" with the user as the player.
    ; Given a maximum value, the program pics a secret number in the
    ; range 1 to the maximum and asks the user to guess this secret
    ; in each turn, giving clues along the way. The goal for the player
    ; is to guess the secret in as few attempts as possible.
    ;
    ; `max-number` is expected to be a non-negative integer greater than 1.
    ;
    ; E.g.
    ;   > (play-number-guessing-name 10)
    ;   Let's play a number guessing game.
    ;   I'll pick a number from 1 to 10.
    ;   You have to guess it in the fewest attempts you can.
    ;   Your guess: 5
    ;   It's higher. Guess again: 7
    ;   It's lower. Guess again: 6
    ;   You guessed it in 3 attempts!
    (define (play-number-guessing-game max-number)
        ...)
 
.. admonition:: **Task**

    Write such "purpose statements" for the three abstractions we've introduced,
    ``greet-player``, ``clue`` and ``declare-win``. See "Figure 1" of `HtDP preface`_
    to read about how to describe procedures from a design perspective.

.. admonition:: **Learnings**

   - We learnt how to use abstractions to reduce redundancy in a program code.
   - We learnt how abstractions can also be used to improve clarity and expressed
     meaning of code by introduce **domain** words into the program.
   - We learnt about the **purpose** of the program by systematically rewriting
     parts of it to express the incremental understanding we gained as we
     worked with it.
   - We saw how eliminating concepts used by a program can help **simplify** it
     and help the reader understand its purpose better. (In our case, we
     eliminated the ``box`` construct and the "let loop" construct.)

     .. note:: Which concepts we should eliminate and which programming
        constructs to adopt is determined by human considerations of what your
        team, co-programmers, or audience knows and can comfortably read. In our
        case, we've illustrated the process assuming an audience not too familiar
        with the constructs of Racket. In general, the fewer words pertaining to
        the programming language we can use that are non-domain adjacent, the more
        readable the program is.

   - Such a rewritten version of the program is not necessarily unique in form
     and it is subject to the reading of the programmer.
   - We also saw how :hl:`a definition of an abstraction can refer to itself`.
     We'll see more of this feature, called **named recursion**, later on.

.. _HtDP preface: https://htdp.org/2024-11-6/Book/part_preface.html

Room for improvement
--------------------

Is the original program deficient in any way?

This question is actually much harder to answer with :ref:`the first version <nggv1>` than
with, say, `the fourth version <nggv4>`.

.. admonition:: **Principle**

   To make the purpose of a program clear and robust, clarify the constraints that
   the arguments and results of every abstraction must conform to.

Let's apply that principle to make the program robust. Starting at the top, we
have our first constraint that ``max-number`` argument must be a non-negative integer
that's greater than 1 for the game to be meaningful.

.. code:: racket

   (define (play-number-guessing-game max-number)
      (when (not (and (integer? max-number) (> max-number 1)))
        (error "Expecting a non-negative integer > 1"))
      ...)

In fact, we can make a small abstraction to help make type constraints easier to
enforce.

.. code:: racket

    (define (must-be-an-integer argname arg)
        (when (not (integer? arg))
            (error (string-append "Expecting an integer for " argname "."))))

    (define (must-be-a-string argname arg)
        (when (not (string? arg))
            (error (string-append "Expecting a string for " argname "."))))
        
With this, we can just write --

.. code:: racket

   (define (play-number-guessing-game max-number)
      (must-be-an-integer "max-number" max-number)
      (when (<= max-number 1)
        (error "Expecting a non-negative integer > 1"))
      ...)


   (define (clue next-guess secret)
      (must-be-an-integer "clue:next-guess" next-guess)
      (must-be-an-integer "clue:secret" secret)
      (if (< next-guess secret)...))

   (define (declare-win attempts)
      (must-be-an-integer "declare-win:attempts" attempts)
      ...)

Now we look at an interesting case -- the ``ask-next-guess`` procedure --

.. code:: racket

   (define (ask-next-guess prompt)
      (must-be-a-string "prompt" prompt)
      (display prompt)
      (display " ")
      (read))

We notice that while we can visually inspect that ``clue`` and ``declare-win``
and even ``play-number-guessing-game`` produce correct kinds of output values
(what are there output values?), ``ask-next-guess`` simply passes on what the
user typed. So if the user typed, say, ``meow`` instead of a number, the
program errors out without very descriptive (i.e. **in-domain**) error
messages. Also, it is not clear whether it the whole program should abort if
the **player** made an error. That is in general a bad idea for program design.
:hl:`When the programmer makes an error, that's a good reason to error out in
various ways. But when a user makes an error, it is in general advisable to
catch these errors and report back to the user about what the desired behaviour
actually is.` So let's fix that for ``ask-next-guess`` and some how ensure that
it will always produce an integer as the result.

.. code:: racket

    (define (ask-next-guess prompt)
        (must-be-a-string "prompt" prompt)
        (display prompt)
        (display " ")
        (let ([user-input (read)])
           (if (integer? user-input)
               user-input
               (error "What to do here?"))))

We now have some choices. We can simply error out with an appropriate error message,
but we just saw why that's not a good idea. We need to do something else instead.
A reasonable choice would be to tell the user what is expected and to ask them again.

.. code:: racket

    (define (ask-next-guess prompt)
        (must-be-a-string "prompt" prompt)
        (display prompt)
        (display " ")
        (let ([user-input (read)])
           (if (integer? user-input)
               user-input
               (begin (display "Please give me an integer this time. ")
                      (ask-next-guess prompt)))))

You see what we did there? We simply repeated the process ad nausem so the
player gets tired or aborts the program, but the program won't crash because
of a casual mistake.

We've done something different this time. The rewrite that resulted in the
abstraction ``ask-next-guess`` has shown us a deficiency in the program and
also suggested a route to resolve that deficiency ... all without having to
change the overall flow or meaning of the program.

.. admonition:: **Terminology**

   Rewrites of a program that make it more accessible to programmers and more
   robust without major changes to functionality is often referred to as
   "refactoring". The idea of using the word "factor" here is analogous to
   mathematics where we might use the ease of comprehension of smaller numbers
   to express larger numbers -- e.g. :math:`256 = 16 \times 16`. So the act of
   pulling out smaller abstractions to help articulate the purpose of a larger
   program is seen as analogous to "pulling out a factor".

   There is also a deeper sense in which this connection is true, but we'll
   see that later.

Afterword
---------

In this section, we started with a partially correct but poorly written program
for the number guessing game (from a reader's point of view). The question
before us therefore, how do we avoid that in the first place?

That inverse question assumes that a) we know what problem we want to solve,
and b) we know what we need to do to solve it. However, what we haven't worked
out is how we express that solution as a program.

In many occasions, being able to articulate the problem and your solution in
normal words as succinctly as you can, and work your way down the "ladder
of abstraction" can help construct a program from scratch.

The **key principle** is to add some level of detail to each successive stage
of the expansion from a high level version to a functioning program.
We call this approach "incremental program development" or IPD for short
and will see this in approach as a separate topic.

.. [#fn] A "function" is a procedure whose result value depends only on the
   values of its arguments. This is not a property enforced by Racket, but
   is a useful distinction to keep in mind in many programs.

Exercises
---------

Follow the same process as above for the programs given here to understand them.
The programs, as they stand are poorly written. So you'll need to --

1. Understand what each program does through interrogation
   and reading necessary documentation.
2. Transform the program to a form where its meaning can be
   clearly read, possibly fixing clear deficiencies.
3. The resultant procedures are documented using the recommendation
   in the `HtDP preface`_ .

Program 1
~~~~~~~~~

.. code-block:: racket
   :linenos:
   
   (define (convert str)
      (let loop ([n 0] [p 0])
         (let ([c (string-ref str p)])
            (if (char-numeric? c)
                (loop (+ (* 10 n) (- (char->integer c) (char->integer #\0)))
                      (+ p 1))
                n))))

Program 2
~~~~~~~~~

.. code-block:: racket
   :linenos:

   (define (transform str)
      (let loop ([p1 0] [p2 (string-length str)])
         (if (char-whitespace? (string-ref str p1))
             (if (char-whitespace? (string-ref str (- p2 1)))
                 (loop (+ p1 1) (- p2 1))
                 (loop (+ p1 1) p2))
             (if (char-whitespace? (string-ref str (- p2 1)))
                 (loop p1 (- p2 1))
                 (substring str p1 p2)))))

Program 3
~~~~~~~~~

.. code-block:: racket
   :linenos:

   (define (splice str strs)
      (let loop ([result ""] [strs strs])
         (if (empty? strs)
             result
             (loop (string-append result str (first strs))
                   (rest strs)))))

Program 4
~~~~~~~~~

.. code-block:: racket
   :linenos:

   (define (split str)
      (let loop ([result empty] [p1 0] [p2 0] [n (string-length str)])
         (if (< p2 n)
            (if (equal? #\newline (string-ref str p2))
                (loop (cons (substring str p1 p2) result)
                      (+ p2 1)
                      (+ p2 1)
                      n)
                (loop result p1 (+ p2 1) n))
            (reverse (cons (substring str p1 p2) result)))))
      
Program 5
~~~~~~~~~

.. code-block:: racket
   :linenos:

   (define (whereis pat str)
      (let loop ([n (string-length str)]
                 [pn (string-length pat)]
                 [p 0])
         (if (> (+ p pn) n)
             #f
             (if (equal? (substring str p (+ p pn)) pat)
                 p
                 (loop n pn (+ p 1))))))

Program 6
~~~~~~~~~

.. code-block:: racket
   :linenos:

   (define emojis (list (list "😀" 'smile)
                        (list "🙁" 'frown)
                        (list "😡" 'angry)
                        (list "🙄" 'roll)
                        (list "😆" 'lol)))

   (define (whatisit table)
      (let ([e (list-ref table (random 0 (length table)))])
          (display "What is ")
          (display (first e))
          (display "? ")
          (let loop ([answer (read)])
             (if (equal? answer (second e))
                 (displayln "You got it!")
                 (begin (displayln "Try again.")
                        (loop (read)))))))


                              
      
