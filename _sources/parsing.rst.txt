Parsing
=======

We represent many kinds of data as text -- i.e. as a sequence of characters.
Computing with such data therefore involves two processes --

1. Given the data, represent it as a sequence of characters. What ``display``
   does in Racket, for example.
2. Given a sequence of characters and information about what structure it
   has, produce the data that it corresponds to.

While we're familiar with the first, the second type of computation is
called "parsing" and is a very useful category of programs to examine.

List of words
-------------

Let's take a simple program that, when given a string (i.e. a sequence of
characters), produces a "list of words" in the order they're found in the
string.

.. code:: racket

   (define (list-of-words text)
      (when (not (string? text))
         (error "Expected a string"))
      (list-of-words-from text 0))

   (define (list-of-words-from text start-pos)
      (if (>= start-pos (string-length text))
          empty
          (if (char-alphabetic? (string-ref text start-pos))
              (let* ([word (next-word-from text start-pos start-pos)]
                     [next-pos (+ start-pos (string-length word))])
                  (cons word (list-of-words-from text next-pos)))
              (list-of-words-from text (+ 1 start-pos)))))

   (define (next-word-from text first last)
      (if (< last (string-length text))
          (if (char-alphabetic? (string-ref text last))
              (next-word-from text first (+ 1 last))
              (substring text first last))
          (substring text first)))

      
Again, no comments have been given to us and we have to figure it all
out by "reading" this program.

Btw, ``let*`` is just like ``let``, except that the expression whose value is
bound to the second identifier being introduced, can make use of the first
identifier. Similarly the expression for the third identifier can use the first
or second identifier and so on. This is not permitted in ``let``, which
introduces all the identifiers "at the same time". In this example, the
expression for ``next-pos`` depends on ``word``. So we use ``let*``.

The vocabulary of lists
-----------------------

When we scan the program, we find two words we haven't yet encountered --
``empty`` and ``cons``. You can look up their documentation, but here
is a brief description of them --

Now ``cons`` is a biggie. It is the first means to structure data that we're
encountering, so it deserves some attention. ``cons`` is short for "construct
a pair". We see that it is taking two arguments, so we might guess that
the two arguments form the two parts of a "pair". The value returned by the
``cons`` procedure is therefore called a "cons pair" somewhat redundantly.
For historical reasons, the first of the pair is called the pair's ``car``
and the second it's ``cdr``. [#carcdr]_

Here is a set of interactions that might help clarify what ``cons`` does for
you.

.. code:: racket

   > (cons 1 2)
   '(1 . 2) ; This is the notation Racket used for a pair.
   > (define p12 (cons 1 2))
   > p12
   '(1 . 2)
   > (car p12)
   1
   > (cdr p12)
   2

Now, the interesting thing about pairs is that we can put pairs within pairs
to make more complex structures. In particular, when we make a structure where
the second part of a pair is always a pair, we call it a "list".

.. code:: racket

   > (cons 1 (cons 2 empty))
   '(1 2)
   > (define p3 (cons 1 (cons 2 (cons 3 empty))))
   > p3
   '(1 2 3)
   > (length p3)
   3
   > (define q3 (list 1 2 3))
   '(1 2 3)
   > (car q3)
   1
   > (cdr q3)
   '(2 3)
   > (list? (cons 1 2))
   #f
   > (list? (list 1 2))
   #t
   > (cdr p3)
   '(2 3)
   > (cons 100 (cdr p3))
   '(100 2 3)
   > (cdr (cdr p3))
   '(3)
   > (cdr (cdr (cdr p3)))
   '()
   > empty
   '()

i.e., a list that contains nothing at all is called an "empty list" and
that is exactly what ``empty`` is. So ``(cons 2 empty)`` makes a one
element list with the value 2 at its "head". Notice that both ``p3`` and
``q3`` are being shown exactly the same. In Racket, the two ways of making
a list cannot be distinguished -- i.e. once the list is constructed, there is
no way to tell whether it was done using ``cons`` or using ``list``. They
are the same and they can both be "taken apart" using ``car`` and ``cdr``.

If you notice, Racket is printing out a list like ``'(100 2 3)`` with the
items within parentheses. We've all along been writing expressions like
``(list-of-words "hello world")`` within parenthesis as well. If you
actually wondered about this, bravo! And yes, Racket represents all expressions
and programs as ordinary lists! This is a big deal and it has consequences
for what the language can accomplish. See the following interaction to
understand how this works --

.. code:: racket

   > (define ex '(list-of-words "hello world"))
   > ex
   '(list-of-words "hello world")
   > (cons? ex)
   #t
   > (pair? ex)
   #t
   > (length ex)
   2
   > (list? ex)
   #t
   > (symbol? (car ex))
   #t
   > (cdr ex)
   '("hello world")
   > (string? (car (cdr ex)))
   #t
   > (cdr (cdr ex))
   '()
   > (cons 'list-of-words (cons "hello world" empty))
   '(list-of-words "hello world")
   > (list 'list-of-words "hello world")
   '(list-of-words "hello world")

In Racket, a "list" is therefore a special pair such that if you keep following
the ``cdr`` of the pair, you'll either get a pair or ``empty``.

.. admonition:: **Vocabulary**

   ``cons?`` or ``pair?`` can be used to check whether something is a pair.
   ``list?`` can be used to check whether something is a valid list. Note that
   ``list?`` must necessarily examine all the ``cdr``s to figure that out.
   ``empty?`` can tell you whether you have the special empty list on hand.
   All empty lists are the same and equal to each other. You can count the number
   of elements in a list ``ls`` using ``(length ls)``.


.. [#carcdr] ``car`` is short for "contents of address register" and ``cdr`` is
   short for "contents of decrement register". These refer to two registers that
   formed the "pair" in the oldest machines on which LiSP ran, and the names
   stuck. In fact, programmers even got creative and decided that ``(cadr x)``
   should mean ``(car (cdr x))`` and ``(cadar x)`` should mean ``(car (cdr (car
   x)))`` and so on. Don't use these names directly in your code as they make
   understanding the code much harder.
