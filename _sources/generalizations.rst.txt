Generalizations
===============

Programs afford a unique capability where a procedure that was made
specifically for some circumstance can be (almost) mechanically generalized in
many ways to produce procedures that can be applied in many other
circumstances. A generalization is said to be useful if it provides a concept
that be applied in a number of circumstances other than the one in which it was
constructed. This goes to say that not _all_ generalizations are worth the
effort and, more importantly, the cost of inventing a vocabulary for the
generalization.

.. hint:: Constructing good generalizations is an art learnt by experience,
   but we can give some guidelines towards that.

We'll look at how to generalize procedures in this section, and some examples
of generalizations that people have arrived at that have found such wide use 
that they're now part of common vocabulary of programming.

Let's take a simple example to illustrate the "mechanical" process of
generalizing a procedure. Below is a procedure/function to interprets
a temperature given in ℃  as ℉ .

.. code-block:: racket
   :caption: Interpreting a temperature given in ℃  as ℉ .

   (define (celsius->fahrenheit celsius)
      (+ 32 (* 9/5 celsius)))

.. collapse:: Racket and fractional numbers

   Racket lets you notate exact fractions like 9/5 directly. Such fractions are
   dealt with as fractions without conversion to decimal representation. For
   example, in python -

   .. code:: python

      >>> x = 1/237
      >>> x
      0.004219409282700422
      >>> x * 237
      0.9999999999999999

   ... and the same in Racket is - 

   .. code:: racket

      > (define x 1/237)
      > x
      1/237
      > (* x 237)
      1

   With lower level programming languages, therefore, we need to be wary about
   the level of precision with which numbers are being represented internally
   when performing certain types of computations. This is not necessarily a bad
   thing, since systems programming languages like Rust, OCaML and C provide
   access to machine representations of numbers and therefore opportunity to
   optimize computations with them explicitly.

Another way we can write this is to make it explicit that ``celsius->fahrenheit``
is a "procedure" (or, in this case, a "function" since what it means only depends on
its arguments).

.. code-block:: racket
   :caption: ``celsius->fahreheit`` using ``lambda``
   :linenos:
   :emphasize-lines: 2,3

   (define celsius->fahrenheit 
      (lambda (celsius)
        (+ 32 (* 9/5 celsius))))

.. hint:: Remember that you can always read ``lambda`` as ``procedure`` or
   ``function`` -- with the distinction between the two being a matter of
   whether the computations being described depend only on the argument values
   or have some other extraneous dependency that might cause them to produce
   different values for the same arguments on different occasions.

Now consider how we'll use this definition to figure out what
``(celsius->fahrenheit 35)`` means. First we'll have to substitute the value
referred to by ``celsius->fahrenheit`` (which happens to be a procedure) and
then substitute the value of ``32`` for ``celsius`` within the body.

.. _reduction:

.. code-block:: racket
   :caption: Reducing an expression to what it means.
   :linenos:
   :emphasize-lines: 2,3

   (celsius->fahrenheit 35)
   ; => ((lambda (celsius) (+ 32 (* 9/5 celsius))) 35)
   ; => (+ 32 (* 9/5 35))
   ; => (+ 32 63)
   ; => 95

The key step above is where we replaced the ``(lambda ..)`` with
just its "body" and substituted ``35`` for all occurrences of the argument
identifier ``celsius`` within the body. We then continued to replace
sub-expressions with whatever we know they mean until all we're left
with is an irreducible value -- ``95`` in this case.

Generalization as the reverse of reduction
------------------------------------------

Let's look at what a reversal of the highlighted steps in :numref:`reduction`
looks like --

.. code-block:: racket

   ; => (+ 32 (* 9/5 35))
   ; => ((lambda (celsius) (+ 32 (* 9/5 celsius))) 35)


You might imagine a program where we've done celsius to fahrenheit conversions
in a number of places using explicit expressions like ``(+ 32 (* 9/5 35))``,
``(+ 32 (* 9/5 100))`` and so on. Where we've used the same expression pattern
``(+ 32 (* 9/5 __))`` to do the conversion calculation. What this reversal
of steps does is give you a valid expressions from which we can capture the
generalization ``(lambda (celsius) (+ 32 (* 9/5 celsius)))`` into its own
definition so that the whole expression reads more clearly.

Unless the reader knows what 32 and 9/5 are for in such expressions, it may not
be clear to them why the calculation is being done, but if they see
``(celsius->fahrenheit 35)`` instead, it would make clear to them that ``35``
is a temperature in degrees celsius and the result expression is the
corresponding temperature in degrees fahrenheit.

.. code-block:: racket

   (define celsius->fahrenheit (lambda (celsius) (+ 32 (* 9/5 celsius))))
   (celsius->fahrenheit 35)

Note what we've done here --

1. We've now gained a reusable "word" in our vocabulary. 
2. We've also given a name for the changeable parts of the expression,
   thus clarifying what kind of a thing is expected in the ``___`` area
   of ``(+ 32 (* 9/5 ___))``.

Therefore with each such reverse step, we need to invent two words
-- one for the pattern and one for the ``___`` within the pattern.

.. admonition:: **Repeated code patterns**

   Whenever you find code patterns -- expressions or whole blocks --
   repeated with minor variations in some parts of them, these are
   ripe candidates for generalization because doing so can help reduce
   the redundancy in the code and, more importantly, clarify the
   concept that the repetition is hinting at that we may not have
   acknowledged earlier.

.. admonition:: **Terminology: "Abstracting over ___"**

   We derived a definition for ``celsius->fahrenheit`` by replacing
   the changeable ``35`` part with an identifier ``celsius`` and
   constructing a ``(lambda (celsius) ...)`` capturing the pattern
   using that newly introduced identifier. We refer to this as
   "abstracting over <the-sub-expression>".

These words we add take thought and communicate intent to the reader of the
program. If either word ends up being reusable in many circumstances, then
creating such words becomes valuable cognitive arsenal, much like learning new
words in a language can improve one's understanding of nuances with certain
kinds of expression.

.. admonition:: **Ponder this**

   ``32`` and ``9/5`` are obvious "constants" in this situation. But "constant"
   w.r.t. what? These are constant in the scope of the definition of
   ``celsius->fahrenheit`` -- i.e. values that remain fixed irrespective of the
   context in which the abstraction gets used (sometimes referred to as the
   "invocation context"). Being the argument identifier, ``celsius`` is not a
   constant. Identify the other references that are also constant in this
   scope?

Mechanizing generalization
--------------------------

Our previous construction of the ``celsius->fahrenheit`` function as an
abstraction over repeated conversion patterns is a simple example, but the same
process applies for abstracting a sub-expression over a containing expression.
In this case, we "abstracted ``35`` over the containing expression ``(+ 32 (*
9/5 35))`` to get ``((lambda (celsius) (+ 32 (* 9/5 celsius))) 35)``, from
which we can extract the function ``(lambda (celsius) (+ 32 (* 9/5 celsius)))``
as the generalization.

To abstract a sub-expression over a containing expression, 

1. Select the sub-expression in DrRacket.
2. Figure out a name that describes the sub-expression. (say ``exprname``)
3. "Cut" the selected sub-expression.
4. Type in the name (identifier).
5. Replace the containing expression with
   ``((lambda (exprname) <containing-expression>) <sub-expression>)``

This actually doesn't perform the abstraction. It simply replaces one
expression with another that means exactly the same thing. However, the
first part ``(lambda (exprname) <containing-expression>)`` is a generalization
over the ``<sub-expression>`` and can now be separated out as a definition
with a name.

A creative act
--------------

There are many valid generalizations that lie in the possible combinations
of sub-expressions and containing expressions. For example, even in the simple
example we have, all the following candidate combinations are *possible*.

.. code:: racket

   ; Original expression
   (+ 32 (* 9/5 35))

   ; Candidate sub-expressions for abstractions.
   (+ 32 (* 9/5 ___))
   (+ ___ (* 9/5 35))
   (+ 32 (* ___ 35))
   (+ 32 ___)
   (___ 32 (* 9/5 35))
   (+ 32 (___ 9/5 35))

But not all *possible* generalizations are meaningful. The "meaning" here lies
in whether a particular generalization helps connect the general construct
across a number of different scenarios, like what ``celsius->fahrenheit`` might
be used for.

"Good" generalizations are therefore creative acts that rely on how the one
performing the generalization is able to give meaning to the general construct.

Consider another example --

.. code-block:: racket
   :linenos:
   :caption: Calculating distance between two points.

   (define (distance x1 y1 x2 y2)
      (sqrt (+ (* (- x1 x2) (- x1 x2))
               (* (- y1 y2) (- y1 y2)))))

We see some obvious repetitions here. For example, within
``(* (- x1 x2) (- x1 x2))``, the sub-expression ``(- x1 x2)``
is repeated and therefore is a candidate for being abstracted
over. If we follow the abstraction process, we get --

.. code:: racket

   (* (- x1 x2) (- x1 x2))
   ; => ((lambda (dx) (* dx dx)) (- x1 x2))

We can do the same for the ``(* (- y1 y2) (- y1 y2))`` expression
as well --

.. code:: racket

   (* (- y1 y2) (- y1 y2))
   ; => ((lambda (dy) (* dy dy)) (- y1 y2))

The two transformed expressions **seem** different, but if we look
closer, there is really nothing to distinguish between
``(lambda (dx) (* dx dx))`` and ``(lambda (dy) (* dy dy))``. Since
the meanins of ``dx`` and ``dy`` are purely local to the context of
each respective lambda expression, we could've named them whatever
we wanted and the **meaning** of the lambda expression will not
change. In this sense, we can say that these two are **the same**
function.

.. code:: racket

   (define (distance x1 y1 x2 y2)
      (sqrt (+ ((lambda (dx) (* dx dx)) (- x1 x2))
               ((lambda (dy) (* dy dy)) (- y1 y2)))))

   ; =>

   (define (distance x1 y1 x2 y2)
      (sqrt (+ ((lambda (x) (* x x)) (- x1 x2))
               ((lambda (x) (* x x)) (- y1 y2)))))

Now if we shift our context to the whole ``(sqrt ...)`` expression,
we can abstract over the redundant ``(lambda (x) (* x x))`` to get --

.. code:: racket

   (define square (lambda (x) (* x x)))

   (define (distance/f f x1 y1 x2 y2)
      (sqrt (+ (f (- x1 x2)) (f (- y1 y2)))))

Now we have a more general form ``distance/f`` (read as "distance with ``f``"),
where the additional ``f`` argument can be varied according to circumstance.
Apart from ``square``, we can also pass ``abs`` for the ``f`` argument to get a
different measure. In mathematics, this notion of "k-norm" refers to sums of
the form :math:`(|a_1|^k + |a_2|^k)^{\frac{1}{k}}` and we simply landed on this idea (though
incomplete and needing more thought) through a "mechanical" process of
identifying redundant sub-expressions.

.. note:: In this case, we saw another aspect of the generalization steps. We
   deal with equivalent sub-expressions simultaneously. Although it is common
   for equivalent sub-expressions to really be equivalent in meaning, it is not
   necessary for that to hold in all circumstances and we must be cognizant of
   that when we include multiple equivalent-in-context sub-expressions in the
   process of generalization.

When we say this is "a creative act", what I'm really saying is that I cheated
in performing this *specific* generalization over all other possible ones,
because I've encountered the need for this generalization in my experience many
times, while you probably haven't. The larger the containing expression, the
more the possible generalizations. If we have a mathematical bent of mind
though, we can explore a given generalization to find its uses or discard it.
Therefore such acts of creativity arise from extensive labour.

Some very useful generalizations
--------------------------------

Mapping
~~~~~~~

We often come across situations where we have a sequence of values
and we need to create a derived sequence where there is a one-to-one
correspondence between the values in the input sequence and another
sequence.

For example, if we have a list of strings, the corresponding list
of lengths of these strings can be defined like this --

.. code:: racket

   (define (string-lengths strings)
      (if (empty? strings)
         empty
         (cons (string-length (first strings))
               (string-lengths (rest strings)))))

In another case, maybe we're looking computing the squares of a sequence of numbers --

.. code:: racket

   (define (squares list-of-numbers)
      (if (empty? list-of-numbers)
         empty
         (cons (square (first list-of-numbers))
               (squares (rest list-of-numbers)))))

It is easy to see that these two look very similar to each other though. Much
of the structure of these two definitions is the same and the sameness is
particularly visible if you replace the argument with a generic word like
"list-of-values". The only difference that leaps out is that in
``string-lengths``, we use ``string-length`` and in ``squares``, we use
``square``.

So if we abstract ``string-length`` over the definition of string-lengths,
we get --

.. code:: racket

   (define (string-lengths fn list-of-values)
      (if (empty? list-of-values)
          empty
          (cons (fn (first list-of-values))
                (string-lengths fn (rest list-of-values)))))

   ; Example usage
   > (string-lengths string-length (list "hello" "world"))
   > (string-lengths square (list 1 2 3 4))

It is now obvious that what we have here is no longer specific to
"string-lengths" and what happens to the elements of the supplied
list is entirely up to the behaviour of the procedure passed
in as the first argument. Since now ``string-lengths`` is no longer
an appropriate name, we need to choose a sufficiently generic name
reflective of the flexibility of its usage. This generalization
is readily available in Racket and is named ``map``.

.. code:: racket

   (define (map fn items)
      (if (empty? items)
          empty
          (cons (fn (first items))
                (map fn (rest items)))))

Filtering
~~~~~~~~~

Another common pattern with sequences is where we want to derive another
sequence by only keeping items that fit some condition. For example,
given a list of numbers, only keeping the perfect squares in them. Or
given a list of strings, only keeping the strings that are longer than,
say, 10 characters. Definitions for these two are shown below --

.. code:: racket

   (define (keep-squares numbers)
      (if (empty? numbers)
          empty
          (if (square? (first numbers))
              (cons (first numbers)
                    (keep-squares (rest numbers)))
              (keep-squares (rest numbers)))))

   (define (keep-long-strings strings)
      (if (empty? strings)
          empty
          (if (> (string-length (first strings)) 10)
              (cons (first strings)
                    (keep-long-strings (rest strings)))
              (keep-long-strings (rest strings)))))

Again, just like ``map``, we can see much commonality of structure
between these two definitions, with the majority of the difference
coming from the "condition" in the second ``if`` expression.

Consider the expression ``(> (string-length (first strings)) 10)``.
If we abstract ``(first strings)`` over this expression, we get
``((lambda (s) (> (string-length s) 10)) (first strings))``.
This now has the same structure as ``(square? (first numbers))``
where the ``(lambda (s) ...)`` occurs in place of ``square?``.
So if we generalize over ``square?`` in the first definition,
we get --

.. code:: racket

   (define (keep-squares/f f numbers)
      (if (empty? numbers)
          empty
          (if (f (first numbers))
              (cons (first numbers)
                    (keep-squares/f f (rest numbers)))
              (keep-squares/f f (rest numbers)))))

   (define (keep-squares numbers)
      (keep-squares/f square? numbers))

   (define (keep-long-strings strings)
      (keep-squares/f (lambda (s) (> (string-length s) 10)) strings))

It is obvious that ``keep-squares/f`` (read "keep squares with f") 
is no longer specific to lists of numbers from which to extract the
square numbers. We've generalized it to also be applicable to our
"keep long strings" case. 

This turns out to be another very useful generalization that Racket
provides it for us in the name of ``filter``.

.. code:: racket

   (define (filter f items)
      (if (empty? items)
          empty
          (if (f (first items))
              (cons (first items) (filter f (rest items)))
              (filter f (rest items)))))

   (define (keep-long-strings strings)
      (define (long-string? str) (> (string-length str) 10))
      (filter long-string? strings))

   (define (keep-squares numbers)
      (define (square? x) (integer? (sqrt x)))
      (filter square? numbers))

Other generalizations
~~~~~~~~~~~~~~~~~~~~~

There are many other such generalizations available in Racket that you can pick
up by reading in the manual. Here are some useful ones -- compose_, ormap_,
andmap_, for-each_, sort_, findf_.

.. _compose: https://docs.racket-lang.org/reference/procedures.html#%28def._%28%28lib._racket%2Fprivate%2Flist..rkt%29._compose%29%29
.. _ormap: https://docs.racket-lang.org/reference/pairs.html#%28def._%28%28lib._racket%2Fprivate%2Fmap..rkt%29._ormap%29%29
.. _andmap: https://docs.racket-lang.org/reference/pairs.html#%28def._%28%28lib._racket%2Fprivate%2Fmap..rkt%29._andmap%29%29
.. _for-each: https://docs.racket-lang.org/reference/pairs.html#%28def._%28%28lib._racket%2Fprivate%2Fmap..rkt%29._for-each%29%29
.. _sort: https://docs.racket-lang.org/reference/pairs.html#%28def._%28%28lib._racket%2Fprivate%2Flist..rkt%29._sort%29%29
.. _findf: https://docs.racket-lang.org/reference/pairs.html#%28def._%28%28lib._racket%2Fprivate%2Flist..rkt%29._findf%29%29

Learning about such generalized procedures is, strictly speaking, not necessary
if you're competent with building the generalizations yourself when the need
arises. However, knowing about them will help you recognize common patterns
where they tend to be needed, and avoid any potential mistakes in implementing
the generalized procedures on your own.

Generalization finger exercises
-------------------------------

.. collapse:: Split a string into lines

   You're given a multi-line text as a single string. The task is
   to split the string into a list of strings wherever there is a
   line break. A definition is given below for this task. In what
   ways can you generalize this? Can you imagine purposes for which
   the generalizations could be useful? How would you name the
   generalizations?

   .. code:: racket

      (define (string->lines str)
        (define (scan-line pos)
          (if (>= pos (string-length str))
              str
              (if (equal? (string-ref str pos) #\newline)
                  (substring str 0 pos)
                  (scan-line (+ pos 1)))))

        (let ([first-line (scan-line 0)])
          (if (>= (string-length first-line) (string-length str))
              (list first-line)
              (cons first-line
                    (string->lines (substring str (+ (string-length first-line) 1)))))))

   **Understand** how the definition functions by interrogating it using
   DrRacket's "interaction window", before you attempt to make generalizations.
   Would you want to rewrite this definition in any other way?
               
.. collapse:: Drive a car

   So you're driving a car on a straight course and leave the starting point at
   60kmph. You accelerate at :math:`7m/s^2` for 30 seconds and then decelerate
   at :math:`5m/s^2` for 30 seconds. A HS student tasked with calculating the
   result wrote down the following expression for the scenario. Your task is to
   construct suitable abstractions that help clarify the calculation, and to given
   appropriate names to the concepts that arise.

   .. code:: racket

      (define distance-driven-in-metres
         (+ (+ (* (* 60 1000/3600) 30)
               (* 1/2 7 (* 30 30)))
            (- (* (+ (* 60 1000/3600) (* 7 30)) 30)
               (* 1/2 5 (* 30 30)))))

   .. hint:: Remember that parentheses here are not of the "mathematical
      brackets" kind, but are Racket's parentheses of the form ``(<operator>
      <operand1> <operand2> ..)``. The forms of the expressions have been kept
      structured with repeating elements to help you identify patterns ... though
      I don't expect a HS student to be so considerate :) 

   .. hint:: Not all occurrences of ``30`` have the same meaning.

   .. hint:: Keep in mind that multiple concepts might need to be elucidated
      via the generalization process. You might want to start by turning
      ``distance-driven-in-metres`` into a function instead of a calculated
      number.

.. collapse:: 

