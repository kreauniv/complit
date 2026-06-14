Optional: Alternative language
==============================

When discussing parsing patterns in strings in :doc:`parsing2`, our "pattern"
values were procedures that produced ``pattern-match`` structured values when
given a piece of text. We wrote such pattern matcher definitions like this --

.. code:: racket

   (define (character-in charset)
      (define (pattern text)
         (if (> (string-length text) 0)
            (let ([first-char (substring text 0 1)])
               (if (string-contains? charset first-char)
                  (pattern-match first-char (substring text 1))
                  #f))
            #f))
      pattern)

   (define (parse pattern text) (pattern text))

With such a simple definition of ``parse``, all the heavy lifting is being
done by each pattern definition. Within the ``character-in`` above, we're
defining a new "local" procedure and saying that the this procedure represents
the pattern in question.

There are a couple of alternative ways to write this in Racket which has parallels
in other programming languages too.

Lambda procedures
-----------------

The form ``(lambda (arg1 arg2 ...) <expr1> <expr2> ... <exprN>)`` represents a procedure
value that has not been named in the context in which this occurs. In the example
above, ``(define (pattern text) ...)`` is, in Racket, exactly equivalent to 
``(define pattern (lambda (text) ...))``. So we could've written it as --

.. code:: racket

   (define (character-in charset)
      (lambda (text)
         (if (> (string-length text) 0)
            (let ([first-char (substring text 0 1)])
               (if (string-contains? charset first-char)
                  (pattern-match first-char (substring text 1))
                  #f))
            #f)))

.. hint:: If you're intimidated by the word "lambda", you can mentally replace
   it with "procedure" or "abstraction". The "lambda" word has a historical
   origin in its association with Alonzo Church's "lambda calculus" which
   provided a mathematical basis for computation. 

   Depending on the discussion context, we may refer to such ``(lambda ...)``
   terms as "lambda procedures", "lambda abstractions" or "lambda functions",
   and we might drop the "lambda" and refer to them just as "procedures",
   "abstractions" and "functions" where the "unnamed" aspect is not of
   much importance.

Defining meta-compounds
-----------------------

We referred to words like ``character-in`` as "procedures" and
expressiong using such procedures ``(character-in "0123456789")``
as "compound terms" which we can roughly relate to sentences
in ordinary language. The definition of ``parse`` indicates that
such a compound term is itself intended to be used as a procedure
like this --

.. code:: racket

   ((character-in "0123456789") "42")

So Racket provides an even simpler syntax for defining such procedures
that themselves result in procedures like this --

.. code:: racket

   (define ((character-in charset) text)
      (if (> (string-length text) 0)
            (let ([first-char (substring text 0 1)])
               (if (string-contains? charset first-char)
                  (pattern-match first-char (substring text 1))
                  #f))
            #f))

What the form ``((character-in charset) text)`` says is that the word being
defined -- ``character-in`` -- is intended to be used in a compound term like
``((character-in "0123456789") "42")`` which in turn implies that the compound
term ``(character-in "0123456789")`` is itself procedure-valued that requires
a piece of text to fully determine its in-context meaning.

Procedures as abstractions
--------------------------

Because a procedure word on its own is just declared as a "procedure value" and
it doesn't get to be concrete until it is provided with in-context values --
its "arguments" -- it is said to **abstract** over all possible values it can
possibly resolve to and therefore can be called an **abstraction**.

Procedures are not the only means of abstraction in programming languages, but
we'll limit ourselves to procedures (named or unnamed) in this course. All
other abstractions in programming can be understood in terms of procedures,
so they are foundational.

