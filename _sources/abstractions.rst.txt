A guessing game
===============

Consider the following program --

.. code:: racket

   #lang racket

   (define (run-number-guessing-game max-number)
      (greet-player max-number)
      (let ([secret (select-random-secret max-number)]
            [attempts 0])
        (play-game "Guess the number: " secret attempts max-number)))

   (define (play-game prompt secret attempts max-number)
      (let ([guess (ask-user-to-guess prompt attempts max-number)])
         (if (= secret guess)
           (user-won attempts)
           (play-game (prompt-with-clue secret guess)
                      secret
                      (+ 1 attempts)
                      max-number))))

   (define (greet-player max-number)
      (displayln "Welcome to the number guessing game.")
      (display "I'll pick a secret number in the range 1 to ")
      (displayln max-number)
      (displayln "and let's see in how many attempts you manage")
      (displayln "to guess it. I'll give you clues along the way."))

   (define (select-random-secret max-number)
      (random 1 (+ 1 max-number)))

   (define (prompt-with-clue secret guess)
      (if (< secret guess)
          "It's lower. Guess again: "
          "It's higher. Guess again: "))

   (define (user-won attempts)
      (display "You won in ")
      (display attempts)
      (displayln " attempts."))

   (define (ask-user-to-guess prompt attempts max-number)
      (report-attempts attempts)
      (display prompt)
      (let ([guess (read)])
          (if (guess-valid? guess max-number)
              guess
              (ask-user-to-guess (invalid-guess-prompt max-number)
                                 (+ 1 attempts)
                                 max-number))))

    (define (guess-valid? guess max-number)
        (and (integer? guess)
             (>= guess 1)
             (<= guess max-number)))

    (define (report-attempts attempts)
        (display "You have used ")
        (display attempts)
        (displayln " attempts."))

    (define (invalid-guess-prompt max-number)
        (string-append "Not a number in the range 1 to "
                       (number->string max-number) 
                       ". Guess properly: "))


``let`` expressions
-------------------

The above code uses a construct you have not seen yet -- ``(let <bindings>
...)``. It's purpose is to introduce meaning for given identifiers within the
scope of the ``...`` part. It has the following structure --

.. code:: racket

    (let ([<identifier1> <expr1>]
          [<identifier2> <expr2>]
          ...)
         <one-or-more-exprs-that-uses-the-identifiers>)

The value of the entire ``(let..)`` expression will be the value
of the last expression in the sequence of expressions given after
the bindings.

.. admonition:: **Task**

   Based on the above description, construct examples of ``(let...)``
   expression to express the following computations --

   1. Bind ``x`` to 3 and ``y`` to 4 and compute ``(+ (* x x) (* y y))``.
   2. Bind ``prefix`` to ``"planet "`` and compute ``(string-append prefix "earth")``.

Play the game
-------------

Pick, say, a maximum of 100 and play the game. Figure out how to win in the
fewest attempts. Note down your strategy.

Tasks
-----

Your task is to now understand how the program works using both reading
methods we've used so far, as well as interrogation methods. To start
with, copy the whole program to a new Racket file and "Run" it.

The program has no comments to help you understand it. So **your task**
of understanding is to comment the code with descriptions so that
the next student who reads the code would find it easier to tell the
meaning of the code.

1. Figure out the purpose of each of the defined procedures
   and write a purpose statement for each of them.

2. Describe the constraints on the arguments for each of the procedures
   in your comments.

3. For the simple ones that compute values from the arguments, also
   given a couple of examples.

4. For each expression, try to provide a verbal explanation of what it is
   for by inserting a comment above it (one or more lines).

Another version
---------------

Now consider the same program written as shown below --

.. code:: racket

   #lang racket

   (define (run-number-guessing-game max-number)
      (displayln "Welcome to the number guessing game.")
      (display "I'll pick a secret number in the range 1 to ")
      (displayln max-number)
      (displayln "and let's see in how many attempts you manage")
      (displayln "to guess it. I'll give you clues along the way.")
      (define secret (random 1 (+ 1 max-number)))
      (play-game "Guess the number: " secret attempts max-number))

   (define (play-game prompt secret attempts max-number)
      (display "You have used ")
      (display attempts)
      (displayln " attempts.")
      (display prompt)
      (define guess (read))
      (if (= guess secret)
          (displayln (string-append "You won in " (integer->string attempts) " attempts."))
          (play-game (if (< guess secret)
                         "It's higher. Guess again."
                         "It's lower. Guess again.")
                     secret
                     (+ 1 attempts)
                     max-number)))

1. How would you describe the behaviour of this version compared to the first version?

2. Comment this program to express your understanding, pretending that you're reading
   it for the first time.

3. Can you modify this program to behave the same way as the first version? What
   understanding did you have to achieve first before you could make the necessary
   changes? 



