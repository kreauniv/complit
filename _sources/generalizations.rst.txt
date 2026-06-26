Generalizing
============

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

Generalization finger exercises
-------------------------------

TODO


      
