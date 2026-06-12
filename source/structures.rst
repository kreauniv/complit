Structures
==========

At the end of the :doc:`strings` section, we saw how combining two
pieces of information -- a string and an index -- gives us access
to multiple kinds of computations on the string focused on that
position.

.. code:: racket

   > (define str "hello")
   > (string-ref str 3)
   #\l
   > (substring str 3)
   "lo"
   > (substring str 0 3)
   "hel"
   > (string-append (substring str 0 3) (substring str 3))
   "hello"

But how do we keep these two pieces of information together?
That's the job of a ``struct`` which is short for "structure"
which is itself short for "data structure".

In this case we can make a ``cursor`` structure combining the
two pieces of information using the ``(struct ...)`` form.

.. code:: racket

   (struct cursor (str pos))

The ``(struct ...)`` tells us that we're defining a new structure identifier,
much like ``(define ...)``.

The first identifier given (``cursor`` in this case), becomes the **name** of the
structure.

The second argument is a sequence of identifiers which represent the various
**fields** of the structure. In this case, this structure ``cursor`` has two
fields named ``str`` and ``pos``.

Such a definition introduces a plethora of new words into the context
for our use.

1. We can now use ``(cursor "hello" 3)`` to represent that position
   we used in the example above. This makes a "cursor struct".

2. We can use ``(cursor? thing)`` to determine whether the argument stands
   for a ``cursor`` type value or not. So ``(cursor? (cursor <str> <pos>))``
   will always evaluate to ``#t`` for valid value of the string and position.

3. If we have a cursor like ``(define c (cursor "hello" 3))``, then we can get
   at the string and the position using ``(cursor-str c)`` and ``(cursor-pos
   c)`` respectively.

New word: ``if``
----------------

Racket has a word ``if`` with 3 arguments which lets us choose an argument
based on a condition. A generic ``if`` expression looks like this --

.. code:: racket

      (if <condition> <then-expr> <else-expr>)

If the ``<condition>`` expression (such as ``(< 2 3)``) evaluates to false (i.e. ``#f``),
then it is as though the whole expression is the same as ``<else-expr>``. Otherwise
it is the same as ``<then-expr>``. That is, the following rules apply -

.. code:: racket

   (if #f <then-expr> <else-expr>) = <else-expr>
   (if _anything_else_ <then-expr> <else-expr>) = <then-expr>

Here are some examples.

.. code:: racket

   > (if (< 2 3) "meow" "woof")
   "meow"
   > (if (< (+ (* 3 3) (* 4 4)) (* 5 5))
         "wrong triangle"
         "right triangle")
   "right triangle"

To evaluate a compound expression like ``(< (+ (* 3 3) (* 4 4)) (* 5 5))``, we
can do it step by step, starting with the innermost expressions, like this -

.. code:: racket

   (< (+ (* 3 3) (* 4 4)) (* 5 5))
   (< (+ 9 (* 4 4)) (* 5 5))
   (< (+ 9 16) (* 5 5))
   (< 25 (* 5 5))
   (< 25 25)
   #f

So the whole ``(if...)`` expression means (in our context) the same as ``(if #f
"wrong triangle" "right triangle")``, which we can see according to our rules
that it must be the same as ``"right triangle"``.

Validity
--------

Should we consider ``(cursor "hello" 500)`` to be a valid cursor structure?
Should ``(cursor 'cat 'meow)`` be a valid cursor structure? 

To ensure that when we make a cursor, we actually have a cursor, we need to place
some constraints on the field values it can have. Towards that, we can write
a ``make-cursor`` procedure like this.

.. code:: racket

   (define (make-cursor str pos)
      (if (and (string? str)
               (integer? pos)
               (>= pos 0)
               (<= pos (string-length str)))
         (cursor str pos)
         (error "Need a string and a position within the boundaries of the string to make a cursor")))

We're using the ``(error <any-descriptive-value>)`` here to signal an error
condition -- i.e. ``make-cursor`` will not succeed, and will fail with the
given error message if we didn't meet the conditions required to make a valid
cursor.

Now let's pick that definition apart and figure out how to "read" it.

- First off, ``(define (make-cursor str pos) ...)`` tells us that the
  ``make-cursor`` is a procedure that takes two arguments. Within the context
  of the procedure's definition, we can refer to these arguments using the
  words ``str`` and ``pos`` respectively.

- Since the whole expression in the body is an ``(if..)``, we can see that
  ``(make-cursor str pos)`` will either become ``(cursor str pos)`` or
  ``(error "Need a string...")``. Thus we understand that ``make-cursor``
  will either succeed with ``(cursor str pos)`` or raise an error if some
  conditions are not met. This fits our expectation of making only valid
  cursors.

- ``(string? str)`` will be ``#t`` if the given ``str`` is a string value and ``#f``
  otherwise. Similarly ``(integer? pos)`` will check whether the given ``pos`` is
  an integer. Remember that procedure words that produce either ``#t`` or ``#f`` 
  usually have names ending in ``?`` as though asking the questions "Is ``str`` a string?"
  and "Is ``pos`` an integer?".

- The ``(and cond1 cond2 cond3 ...)`` can take one or more condition
  expressions. It will check each condition in that order one by one until one
  of them is ``#f``. The ``(and...)`` is considered to succeed if none of the
  conditions fail. So we see that by placing ``(string? str)`` and ``(integer?
  pos)`` up front, by the time we get around to checking ``(>= pos 0)``, we can
  be guaranteed that ``pos`` will be an integer in the context of the
  expression ``(>= pos 0)``. Similarly, we know ``str`` will definitely be a
  string when ``and`` gets around to evaluating ``(string-length str)``.
  :hl:`This ordering is important` because ``(>= pos 0)`` will be an error if
  ``pos`` is not a number and ``(string-length str)`` will be an error if
  ``str`` is not a string.`

- So the combined ``(and ...)`` expression is saying "``str`` is a string and ``pos`` is an
  integer and ``pos`` is >= 0 and ``pos`` is <= the length of ``str``". As we read that,
  we can realize that the moment any one of the sub-conditions becomes false, there is no
  point even looking at any sub-conditions after that. 

  .. tip:: **A closer reading**: While we're checking whether ``pos`` is ``<=``
     the number of characters in the strings ``str``, what we're **really**
     saying is that ``pos`` must be at or before the last possible cursor
     position .. and the last possible cursor position happens to be the same
     as the number of characters in the string. Thus we see that :hl:`we need
     to interpret what is stated and being computed, in the context of what
     we're trying to accomplish.` If as a writer of programs you reduce the
     disconnect between what is stated and how it is to be interpreted, then we
     make the job easier for the reader, which could be you in the future. The
     **means** we have to reduce this disconnect is by defining new words for
     the concept and using that definition. For example,

  .. code:: racket

      (define (last-cursor-position str) (string-length str))
      ; or equivalently ...
      (define last-cursor-position string-length)


Putting all of that together, we can "read" the procedure definition as --

   Given a string ``str`` and integer position ``pos``, such that ``pos`` is non-negative
   and is <= the last cursor position of ``str``, ``make-cursor`` will make a valid
   cursor using ``(cursor str pos)``. Otherwise it will raise an error.

On error messages
-----------------

In our ``make-cursor`` definition, when any one of the four conditions in the
``(and...)`` turns out to be false, we'll get the error message 

   "Need a string and a position within the boundaries of the string to make a
   cursor".

This is not too bad and with a little bit of work, the user of our ``make-cursor``
can figure out which of the four conditions restated in the error message as plain text
failed and can act accordingly.

Can we do better though by also informing the user about **which** of the four
conditions failed? Yes we can, by splitting out each condition like shown below --

.. code:: racket

   (define (make-cursor str pos)
      (when (not (string? str))
         (error "First argument must be a string"))
      (when (not (integer? pos))
         (error "Second argument must be an integer"))
      (when (< pos 0)
         (error "Second argument must be a non-negative integer"))
      (when (> pos (last-cursor-position str))
         (error "Second argument must be at or before the last cursor position"))
      (cursor str pos))

The ``(when <condition> <body>)`` is like an ``(if ..)`` without an "else" part.
When we see a sequence of such expressions in the body of a definition
without any wrapping "operator word", it just means that they will all be
evaluated one by one until the last expression is reached. The value of the
whole sequence is the same as the value of the final expression in the sequence.

The ``begin`` word can be used to make this sequencing explicit like this --

.. code:: racket

   (define (make-cursor str pos)
      (begin
         (when (not (string? str))
            (error "First argument must be a string"))
         (when (not (integer? pos))
            (error "Second argument must be an integer"))
         (when (< pos 0)
            (error "Second argument must be a non-negative integer"))
         (when (> pos (last-cursor-position str))
            (error "Second argument must be at or before the last cursor position"))
         (cursor str pos)))

Since ``(cursor str pos)`` is the last expression in ``(begin ...)``, the whole
``(begin ...)`` expression will take on the value of ``(cursor str pos)`` after
evaluating all the preceding expressions one by one. In our case, the preceding
expressions may fail with an ``(error ...)``. When that happens, no further
evaluations take place and the program is "aborted" and the program is said to
"error out".

With this approach, the error message given is very specific and the user of
our ``make-cursor`` needs to do less work to identify what was wrong about how
they were using it.

.. tip:: A program (or definition) is written once, but used by many people,
   many times over. So it makes sense to reduce the cumulative pain of all
   those cases through appropriate error reporting. Also, remember that this
   "other people" might turn out to be future you who's forgotten what you'd
   written out in the past.

Thus we might expect that our procedure definitions will take on a common form --

.. code:: racket

   (define (<procedure-name> <arg1> <arg2> ...)
      <check that arguments are values of the expected types>
      <check validity of the argument values if any>
      ...
      <body of the procedure that assumes valid arguments>
      )

For someone intending to just **use** the procedure, they may not want to read
all of the body to understand what it does. In fact, we might argue that if the
procedure has a clear enough purpose, then they shouldn't have to worry about
**how** it does it, when all they care about is **what** it computes.

It is clear that we can further help the reader/user by directly telling them
the **purpose** of the procedure. In code, we do this using a comment that
immediately precedes the procedure definition.

.. code:: racket

   ; `make-cursor` Creates a `cursor` structure given a valid string and a
   ; cursor position number within the string. Valid cursor positions range
   ; from 0 to the number of characters in the string (inclusive).
   ;
   ; E.g. `(make-cursor "hello world" 6)` creates a cursor that represents
   ; the position just before the 'w' character.
   ;
   ; E.g. `(make-cursor "hello world" 42)` is an invalid cursor specification
   ; since 42 is more than the number of characters in the given string. Therefore
   ; this invocation produces an error message.
   (define (make-cursor str pos)
      ...)

.. admonition:: **Task**

   Write the documentation for the ``make-cursor`` procedure in the style
   of Racket. Plain text will do. Don't worry about the HTML styling and
   highlighting that Racket documentation uses. Ensure as many facets of the
   documentation you've used are covered, except those which you do not 
   understand yet. Provide a list of aspects you've covered.

Interrogating ``make-cursor``
-----------------------------

In the previous section we looked at how we can read and interpret the definition
of ``make-cursor``. In this section, we'll look at how to gain the same understanding
through **interrogating** the definition.

To start, the definition of the ``(struct ..)`` and the ``(define (make-cursor ..) ..)``
should both be in the definitions window. Once in, load the definitions into the interaction
window by hitting "Run". Your definitions window should look like this --

.. code:: racket

   #lang racket

   (struct cursor (str pos))

   (define last-cursor-position string-length)

   (define (make-cursor str pos)
      (if (and (string? str)
               (integer? pos)
               (>= pos 0)
               (<= pos (last-cursor-position str)))
         (cursor str pos)
         (error "make-cursor expects a string and a valid cursor position index.")))

First, we can see that the body of ``make-cursor`` introduces two identifiers for its
arguments -- ``str`` and ``pos``. So we can define values for these in the interaction window
to work with expressions used by the body.

.. code:: racket

   > (define str "hello word")
   > (define pos 42) ; Invalid position index

We can now copy-paste any sub-expression in the body of ``make-cursor`` into the
interaction window to see what it does.

.. code:: racket

   ; Does make-cursor work on these values?
   > (make-cursor str pos)
   ❌ make-cursor expects a string and a valid cursor position index.
   ; Is str a string?
   > (string? str)
   #t
   ; Is pos an integer?
   > (integer? pos)
   #t
   ; Is pos non-negative?
   > (>= pos 0)
   #t
   ; Is it within the bounds of the string?
   > (last-cursor-position str)
   10
   > (<= pos 10)
   #f
   ; We see that (<= pos 10) is false and therefore make-cursor fails too.
   > (and (string? str)
          (integer? pos)
          (>= pos 0)
          (<= pos (last-cursor-position str)))
   #f
   ; Now give a valid position. 
   > (define pos 6) ; The cursor position just before 'w'
   > (<= pos (last-cursor-position str))
   #t
   ; Now that both str and pos are valid, what does make-cursor do?
   > (make-cursor str pos)
   #<cursor>
   ; This indicates that a valid cursor structure value has been created.

With a process like that where each interrogation step is driven by a question
we have about the code we're interrogating, we can come to an understanding
about the purpose of a procedure. 

This process of arriving at an understanding of a procedure can be made harder
or easier depending on the availability of the comment describing the
procedure.

.. tip:: Only relying on the comment to tell us what a procedure does can be a
   problem because we do encounter procedures without such comments in a lot of
   code and we need a way to make sense of what we're seeing in those cases.
   Furthermore, someone could've edited the code to do something slightly
   different than what the comment says, having forgotten to update the comment
   to reflect that -- a human error. This is often referred to as **documentation
   drift**.

``make-cursor`` in "typed racket"
---------------------------------

We can help ourselves and programmers who want to use our code by first
checking whether both our programs are correct before it even gets to run. This
is because in many circumstance such as with servers, finding out about an
error when the server is already up and running can prove expensive,
troublesome or a combination. 

Type systems which read some extra annotation you provide as part of your program
and automatically check whether callers of procedures make consistent use of
procedures are therefore very useful both to human readers and to ensure
some basic correctness.

We could've written the ``cursor`` struct using "typed racket" like this --

.. code:: racket

    #lang typed/racket

    (struct cursor
        ([str : String]
         [pos : Nonnegative-Integer]))

    (: last-cursor-position (-> String Nonnegative-Integer))
    (define last-cursor-position string-length)

    (: make-cursor (-> String Nonnegative-Integer cursor))
    (define (make-cursor str pos)
        (when (> pos (last-cursor-position str))
            (error "Position out of bounds"))
        (cursor str pos))

Now when we evaluate, say, ``(make-cursor "hello" -4)``, or ``(make-cursor 2
3)``, Racket will tell us that we've supply invalid arguments.

Typed Racket is a much larger language than Racket that we won't be getting
into for the purpose of this course, though the above illustrative example
is given to give you a flavour of how having a type system is useful.


