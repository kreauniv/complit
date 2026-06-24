Representations
===============

We saw how we can work with sequences of characters as a representation for
textual material. We called such values "strings". Are other representations
possible for text? Consider the following questions --

- Suppose we wish to work with a collection of textual material that span
  several 100 GBs. Would it work for us to load it all up into memory and
  reference it as a single "string of characters"?

- Suppose we're working with text as part of an editor application. Should we
  still represent a complete file as a single string of characters? Consider
  how we'll do an editing operation like "delete like 147 to 149".

- Suppose we're analyzing a piece of text for its literary value and so we're
  concerned mostly with words, phrases and sentences in the text. Does it still
  make sense to treat it as a sequence of characters if we want to answer
  questions like "how many times does each word occur in the body of text?".

The import of the above considerations is that different ways of looking at
some data may be important in different application contexts.

When we're trying to understand a domain more precisely though, we might be at
a loss for what representation we should be using. Thanks to Alonzo Church's
"lambda calculus" and the Church-Turing thesis, we know that no matter what
we're trying to model, we can always start with representing a value as a
procedure! While this is seen as a fundamental result in computing, its value
for us is that it gives us a way in **every** circumstance.

``cons`` pairs
--------------

As a simple example, consider the "cons pair" we've used so far. The basic
operations we need to do with these are --

1. ``(cons a b)`` makes a pair.
2. ``(car p)`` gets the first item of a pair ``p``. i.e. ``(car (cons a b)) =
   a`` for all ``a`` and ``b``.
3. ``(cdr p)`` gets the second item of a pair ``p``. i.e. ``(cdr (cons a b)) =
   b`` for all ``a`` and ``b``.

Racket provides such "cons pairs" for us, but what if it didn't? Can we make
them on our own? Here is one way to make pairs just using procedures.

.. code-block:: racket
   :caption: Implementing pairs using procedures

   (define (.first a b) a)
   (define (.second a b) b)

   (define (our-cons a b) (lambda (select) (select a b)))
   (define (our-car p) (p .first))
   (define (our-cdr p) (p .second))

If we can represent pairs using "lambda procedures", we can build any complex
structure this way. For example, a sequence of values can be represented as
nested pairs like ``(cons a1 (cons a2 (cons a3 ... (cons aN empty))))``,
which is how Racket represents "a list of values".

We won't go deeper into the Church-Turing thesis at this point. For now, it is
enough to know what when we need a representation for a domain we're playing
with, we can always try to come up with an initial one based on
procedures/functions alone. Later on, when we're clearer about what we'd like
to do with domain values of interest to us, we can improve the representation
based on the newly discovered considerations such as "efficient memory usage"
or making certain operations efficient, or ease of access over a network.

Since we're not concerned with such aspects in this course and are more
concerned with programs and what they mean to us, we'll continue to use
procedure-based modelling such as we did with images.



