IPD: Incremental Program Development
====================================

When beginning to write slightly larger programs than single purpose
"functions", you might find yourself in a situation where you know **what** the
program should do and also **how** it should do it. In principle, this should
be sufficient for you to declare the program as "done" and LLMs might actually
take you from there to a working program. But the real task in front of you is
in how to express the program in such a way that it is legible to another one
reading it?

What we're calling "incremental program development" here is an approach you
can use to take your understanding of the **what** and the **how** and, step by
step, translate it into a full program. The facilities provided by languages
like Racket [#likeracket]_ are expressive in ways you might not yet appreciate,
but will become clearer as you write programs in this style.

Principles
----------

When developing a program using IPD, your focus is on **narrating** how the
task is to be accomplished. The goal is that the **what** must be as apparent
as possible in the code without having to explain all that much more. A comment
here and a comment there is ok within your program, but if you're having to
write a very long comment that talks about the contents of your program only
and seeks to explain its working, you're not doing a good job of writing the
program legibly.

1. Start by naming the activity your program must accomplish and what it
   needs in order to do that. This is easily modelled as an ordinary abstraction
   (a.k.a. "procedure", "function").

2. Write expressions that appear to define that abstraction using Racket
   syntax and inventing identifiers that stand for concepts you need as you
   go along, without worrying about whether those concepts are available or not.
   The goal in such a step is to add some non-zero level of detail about the
   abstraction you need. 

3. For each of the identifiers you used above which remain undefined, add a new
   definition -- either as a value in simple cases, or (usually) an abstraction
   again. For abstractions, look at the way you've referred to the identifier
   to gauge things like how many arguments it must have, what kinds of values
   must those arguments admit and so on.

4. Apply IPD to the definition of each of these new as yet undefined abstractions!
   Remember that at each step, you must ensure you're adding some non-zero level of
   detail. Otherwise this process will never finish!

5. As you're developing the definitions, you might want to check your understanding
   in the interactions window. Since Racket will complain about undefined identifiers,
   you can define simple but on-character implementations. For example, if you needed
   a random number in the range 1 to some ``max-number``, you can define it to always
   produce ``1`` since that is valid in all usage contexts. Later on, you can figure
   out which of Racket's provided words you can use to capture that concept.

At the end of this process, you should have a working program that ought to be
relatively easy [#easy]_ for someone reading it to understand without doing much.

Number guessing game (again)
----------------------------

Since it is a simple enough example, we'll go through this process for the
number guessing game which we know how it should work and therefore meets
the criterion for starting IPD.

Our first level definition will start out like this --

.. code-block:: Racket

   (define (play-number-guessing-game max-number)
        ...)

There may be different values we might want for ``max-number`` and so it makes
sense to express this program as an abstraction over the ``max-number``.

We might elaborate our thinking like this below to the next level of detail --

.. code-block:: Racket

   (define (play-number-guessing-game max-number)
      (introduce-game max-number)
      (define secret (choose-secret-number max-number))
      (play-round-with-user-until user-guesses-secret secret))

We can now get some of the easier definitions out of our way. Note that 
we know that playing a round requires knowledge of the secret and so we
pass the ``secret`` as a parameter.

.. code-block:: Racket

   (define (introduce-game max-number)
        (displayln "Welcome to the number guessing game.")
        (display "I'll choose a number from 1 to ") (display max-number)
        (displayln " at random and keep it a secret.")
        (displayln "You have to guess the secret in the fewest attempts you can."))

    (define (choose-secret-number max-number)
        (random 1 (+ 1 max-number)))

If you didn't know about the ``random`` word provided by Racket yet, you can still
proceed by temporarily defining ``choose-secret-number`` like below --

.. code:: Racket

    (define (choose-secret-number max-number) (- max-number 1))

Now we're left with two intriguing words ``play-round-with-user-until`` and
``user-guesses-secret``.

It is good to first clarify what the "parameters" (the values that map to arguments
of an abstraction) are before proceeding with abstractions which use them. In this case,
that's ``user-guesses-secret``. That looks like an abstraction because you need
to know two things to determine whether the user has correctly guessed the secret --
the ``secret`` and a ``guess`` given by the user.

.. code:: Racket

   (define (user-guesses-secret secret guess)
        ...)

We know that the user guessed right if the secret equals the guess. This abstraction
therefore simple seems to be a boolean comparison.

.. code:: Racket

    (define (user-guesses-secret secret guess)
        (= secret guess))

Now let's tackle ``play-round-with-user-until``.

.. code:: Racket

    (define (play-round-with-user-until stop-condition secret)
        ...)

Note how we're giving a somewhat abstract term for the specific
``user-guesses-secret``. The constraint on ``stop-condition`` is that it must
now be an abstraction that takes two arguments -- the secret and the
user's guess.

.. code:: Racket

   (define (play-round-with-user-until stop-condition secret)
        (define guess (ask-users-guess-within max-number))
        (if (stop-condition secret guess)
            (user-won guess)
            (play-round-with-user-until stop-condition secret)))

We know that ``(stop-condition secret guess)`` is either ``#true`` or
``#false``, so we must take a call based on this. This leads us to using ``(if ...)``.
But if you noticed, we've missed something -- ``ask-users-guess-within``
needs ``max-number`` and we don't have it available in this context.
We should add it to the argument list and that changes our program a bit.
So we have this so far --

.. code-block:: Racket

   (define (play-number-guessing-game max-number)
      (introduce-game max-number)
      (define secret (choose-secret-number max-number))
      (play-round-with-user-until user-guesses-secret secret max-number))

   (define (introduce-game max-number)
        (displayln "Welcome to the number guessing game.")
        (display "I'll choose a number from 1 to ") (display max-number)
        (displayln " at random and keep it a secret.")
        (displayln "You have to guess the secret in the fewest attempts you can."))

    (define (choose-secret-number max-number)
        (random 1 (+ 1 max-number)))

    (define (user-guesses-secret secret guess)
        (= secret guess))

   (define (play-round-with-user-until stop-condition secret max-number)
        (define guess (ask-users-guess-within max-number))
        (if (stop-condition secret guess)
            (user-won guess)
            (play-round-with-user-until stop-condition secret)))

Now we can proceed to define the missing words --

.. code-block:: Racket

    (define (ask-users-guess-within max-number)
        (tell-user-to-guess-within max-number)
        (define guess (read))
        (if (guess-valid? guess max-number)
            guess
            (ask-users-guess-within max-number)))

    (define (tell-user-to-guess-within max-number)
        (display "What's your guess? (max ")
        (display max-number)
        (display "): "))

    (define (guess-valid? guess max-number)
        (and (number? guess)
             (integer? guess)
             (>= guess 1)
             (<= guess max-number)))

Here I've skipped a few steps to define the new words. Work these
out for yourself and convince yourself of their validity.
Note here that we've defined ``ask-users-guess-within`` to always
result in a valid guess. If the user fails to provide a valid guess
(by typing, say ``woof`` instead of a number) this will keep
asking the user until they provide a valid one.


The only remaining word is ``user-won``.

.. code:: Racket

    (define (user-won guess)
        (display "Your guess ")
        (display guess)
        (displayln " is correct! You won!"))

The final program
-----------------

So putting all that together gives us the following program --

.. code-block:: Racket
   :linenos:
   :caption: The final complete program

   (define (play-number-guessing-game max-number)
      (introduce-game max-number)
      (define secret (choose-secret-number max-number))
      (play-round-with-user-until user-guesses-secret secret max-number))

   (define (introduce-game max-number)
        (displayln "Welcome to the number guessing game.")
        (display "I'll choose a number from 1 to ") (display max-number)
        (displayln " at random and keep it a secret.")
        (displayln "You have to guess the secret in the fewest attempts you can."))

    (define (choose-secret-number max-number)
        (random 1 (+ 1 max-number)))

    (define (user-guesses-secret secret guess)
        (= secret guess))

   (define (play-round-with-user-until stop-condition secret max-number)
        (define guess (ask-users-guess-within max-number))
        (if (stop-condition secret guess)
            (user-won guess)
            (play-round-with-user-until stop-condition secret)))

    (define (ask-users-guess-within max-number)
        (tell-user-to-guess-within max-number)
        (define guess (read))
        (if (guess-valid? guess max-number)
            guess
            (ask-users-guess-within max-number)))

    (define (tell-user-to-guess-within max-number)
        (display "What's your guess? (max ")
        (display max-number)
        (display "): "))

    (define (guess-valid? guess max-number)
        (and (number? guess)
             (integer? guess)
             (>= guess 1)
             (<= guess max-number)))

    (define (user-won guess)
        (display "Your guess ")
        (display guess)
        (displayln " is correct! You won!"))

Some tasks
----------

.. admonition:: **Task 1**

   Put all that together and check whether the program flow and purpose 
   is easy to follow.

.. admonition:: **Task 2**

   We want to tell the user how many incorrect guesses they've made so far, and
   also once they've guessed right, tell them the total number of guesses they
   took. Modify the program (using IPD) to add this "feature" to the game.
   Before starting to implement, make sure you know all the details of this
   feature and how a game will look like with this feature. Remember that
   that's the precondition to start IPD.

.. admonition:: **Task 3**

   Modify the game to also take a ``max-guesses`` argument and have the game
   terminate with a "you lost!" if the user took more than these many guesses.

.. admonition:: **Task 4**

   If you start writing this same program again, you might come up with
   another way to express it. Try it as many times as you want.

Notes
-----

1. What if we had written ``(play-round-with-user-until-user-guesses-secret
   secret)`` initially instead of ``(play-round-with-user-until
   user-guesses-secret secret)``? Yes we can. However we'll soon be required to
   add more detail. Splitting it right here into the two required concepts
   loses no clarity of expression and therefore it is worth doing it right
   here. There is nothing wrong with using one more definition step though and
   you'll know where to split a concept without compromising readability as you
   practice more.

2. The concept ``play-round-with-user-until`` is defined in terms of itself.
   What we're saying with that is that if the user has not won, it is as though
   we're back to square one and must play another round. A similar pattern also
   occurs with ``ask-users-guess-within``. Familiarize yourself with this
   pattern and understand how it can work. In particular, there must be
   something within the definition that will take a "different path to the
   finish line" in some cases while in other cases it "tries again". These are
   respectively referred to as the "termination condition" [#basecase]_ and the
   "recursion step", formally. (You don't need to know these terms for now.)

3. When we defined ``ask-users-guess-within``, we defined the abstraction to be
   complete -- in the sense that in any specific usage context, the expression
   using the abstraction is always guaranteed to stand for a valid guess. This
   is a desirable trait of abstractions. However it is not possible to do this
   in all cases and some abstractions must be limited in the contexts in which
   they can be applied.

.. [#likeracket] (and all the languages that have borrowed these ideas from
   languages like Racket, such as JavaScript and Python)

.. [#easy] Doesn't mean "takes no work". Just that it would take a *lot* more
   work had your program not been written legibly, like with some of the
   example picture drawing programs we initially made legible through rewrites.

.. [#basecase] sometimes also called "the base case"
