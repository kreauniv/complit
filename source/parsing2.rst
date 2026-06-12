More parsing
============

The term "parsing" refers to the act of detecting patterns present in given
text and translating the detected patterns into corresponding data structures.

This very page you're looking at is itself text with special patterns that say
how it is intended to be displayed. You can see this text by right-clicking and
choosing "Show page source". [#viewsrc]_

We wrote a procedure to extract a list of words given a string earlier
(:doc:`parsing`). How can we better express the *idea* behind it directly
rather than explicitly articulate *how* to do it. This brings us to a very
interesting and intellectually rewarding part of computer science and language
-- where we can invent a precise language to capture the core idea, and then
write a general program (an "interpreter") to directly work with that language
instead to solve a broad/general class of tasks. We'll see a little of that in
this section.

We might write our idea of finding words like this -

1. A "word" is a sequence of one or more "alphabetic" characters.
2. A "non-word" is a sequence of zero or more "non-alphabetic" characters.
3. A word occurrence is an optional non-word followed by a word.
4. The string is to be thought of as zero or more word occurrences.

What we're trying to do here is to give precise meaning to aspects of the problem
we're articulating. In this case, we're defining what a "word" is, what a "non-word"
is and in what order they may occur within the string. Given this information,
it seems a little easier to work towards writing a successful procedure for the
task. However, we can do a bit more and try to formalize these ideas --

.. code::

   Word -> oneormore(alphabetic)
   NonWord -> zeroormore(non-alphabetic)
   WordOccurrence -> NonWord Word
   String -> many(WordOccurrence)
   alphabetic -> 'a'|'b'|'c'|...|'z'|'A'|'B'|'C'|...|'Z'
   non-alphabetic -> not(alphabetic)

In the above, we're making explicit how we expect the string to be seen.
We've made use of the commonality we've seen in (1) and (2) in our textual
description to write a definition for ``Word`` and ``NonWord``.

.. note:: This way of writing the patterns to be expected in a kind of text is
   called "Backus-Naur form" after two computer scientists who used this form
   to describe programming language syntax. The Sanskrit grammarian Pānini
   also used similar constructs to articulate phonological and grammatical
   constructs in the language.

We might then imagine being able to write something like this --

.. code-block:: racket

   (define alphabetic (character-in "a-zA-Z"))
   (define non-alphabetic (character-not-in "a-zA-Z"))
   (define word (one-or-more alphabetic))
   (define non-word (zero-or-more non-alphabetic))
   (define word-occurrence (sequence (zero-or-more non-word) word))
   (define string-pattern (zero-or-more word-occurrence))
   (define (list-of-words text) (parse string-pattern text))

.. [#viewsrc] The specific command to use to view the page source
   will depend on the operating system and browser.

Notice that we're just inventing words and using the parenthesis grouping to
communicate **small ideas** that are expected to be **combine** to create
**larger ideas**. Contrary to a view of software as "instructions for
machines", much of the human work behind them is about building up such larger
ideas through combinations of smaller ideas.

While we invented new words here, some of them are more precise than others.
For example, we understand that ``(character-in "a-zA-Z")`` is a "string
pattern" that is intended to be used in ``(parse <string-pattern> text)``.
Furthermore, it is clear that it will match one character that fits the given
set of characters. We've used an abbreviated form ``"a-z"`` to denote
``"abcdefghijklmnopqrstuvwxyz"`` and similarly for upper case letters. However,
words like ``zero-or-more`` and ``one-or-more`` themselves seem to depend on
patterns to define new patterns. We can still continue this word defining game
of ours to clarify what they mean.

.. code-block:: racket

   (define (one-or-more pattern) 
        (sequence pattern (zero-or-more pattern)))

   (define (zero-or-more pattern)
        (alternatives empty-pattern (one-or-more pattern)))

While we're introducing a new word ``alternatives`` here, our words
have nearly all gained some good definitions and we're only left 
with ``sequence`` and ``alternatives``.

``character-in``
----------------

Now let's look deeper into what the word ``character-in`` can mean
in the context of ``(character-in "abcd..z")``.

With all such expressions, we expect this expression to produce a value of some
kind. We need to figure out what kind of value it is.

One thing we do know is that this value should be usable in the "pattern"
position of the parse operation ``(parse PATTERN TEXT)``. So the question at
hand is "what is ``(parse (character-in "a-z") "some text")`` expected to
produce?".

Let's look at two cases and see what we expect -

1. ``(parse (character-in "a-z") "some text")``
2. ``(parse (character-in "a-z") "123 some text")``

If we assume that the first one produces the single character ``#\s``
(the first character of the string ``"some text"``), then in the second case,
we should expect some kind of indication of failure to find a character in the
given range. This could be ``#f`` for example. So we can perhaps have a tentative
definition for ``character-in`` like this -

.. code-block:: racket
   :linenos:
   :name: parsev1
   :caption: ``character-in`` and ``parse``

   (define (character-in allowed-chars)
      (define (pattern text)
         (if (> (string-length text) 0)
            (let ([first-char (string-ref text 0)])
               (if (string-contains? allowed-chars first-char)
                  first-char
                  #f))
            #f))
      pattern)
   
   (define (parse pattern text)
      (pattern text))

So when we parse for a single character, we get a character if it is in the
specified range, and ``#f`` if not. Now supposing we want to interpret
``(sequence (character-in "a-z") (character-in "0-9"))``, what should the
result of ``(parse <pattern> "something")`` give?  Somehow, the second
``(character-in "0-9")`` needs to know to check the character that has been
collected by the first ``(character-in "a-z")`` when matching against something
like ``"a5"``. Somehow, when ``sequence`` looks for the first pattern, it must
also receive information about what the *remaining* text is after the pattern
matched, along with whatever it is the pattern did match. 

.. code:: racket

   (struct pattern-match (result remainder))

   (define (character-in allowed-chars)
        (define (pattern text)
            (if (> (string-length text) 0)
                (let ([first-char (string-ref text 0)]
                      [remainder (substring text 1)])
                    (pattern-match first-char remainder))
                #f))
        pattern)

This will permit us to define ``sequence`` like this --

.. code:: racket

   ; One possible definition of `sequence`
   (define (sequence pat1 pat2)
     (define (pattern text)
       ; Try the first pattern on the given text.
       (let ([r1 (parse pat1 text)])
         (if r1
            ; If the first pattern succeeded, try the second
            ; pattern on the remainder.
            (let ([r2 (parse pat2 (pattern-match-remainder r1))])
              (if r2
                 ; Collect both the results as a cons pair.
                 ; We can collect them in any other way we choose too.
                 (pattern-match (cons (pattern-match-result r1)
                                      (pattern-match-result r2))
                                (pattern-match-remainder r2))
                 #f))
            #f)))
     pattern)

Now, when we do ``(parse (sequence (character-in "a-z") (character-in "0-9")) "a1b2c3")``,
we can expect to get ``(pattern-match (cons #\a #\1) "b2c3")`` as the result.

Now let's see if we can use the same approach to define ``alternatives``.

.. code-block:: racket

   (define (alternatives pat1 pat2)
     (define (pattern text)
        ; `or` in this case means "the first parse that succeeds on text".
        (or (parse pat1 text) (parse pat2 text)))
     pattern)
            
.. admonition:: **A side trip**

    It would be nice to be able to write ``(sequence pat1 pat2 pat3 .. patN)``
    and ``(alternatives pat1 pat2 .. patN)`` using how many ever patterns we
    want to sequence or choose between. Racket lets you bind an word introducing
    the "list of arguments" instead of each individual argument, like this --

    .. code:: racket

        (define (our-procedure . args)
            ; args here is the list of arguments given to `our-procedure`
            )

    Using this, we can generalize ``sequence`` and ``alternatives`` to an arbitrary
    number of arguments like this --

    .. code:: racket

        ; Sequence will match and provide a list of patterns.
        ; It constructs the list by making pairs using `cons`.
        (define (sequence . patterns)
            (define (pattern text)
                (if (empty? patterns)
                    ; We mean an empty list in this case.
                    ; Note that a sequence with no patterns will always
                    ; successfully be an empty match.
                    (pattern-match empty text)
                    (let ([r1 (parse (first patterns) text)])
                        (if r1
                            (let ([rs (parse (sequence (rest patterns))
                                             (pattern-match-remainder r1))])
                                (if rs
                                    (pattern-match (cons (pattern-match-result r1)
                                                         (pattern-match-result rs))
                                                   (pattern-match-remainder rs))
                                    #f))
                            #f))))
            pattern)

        ; Will match the first alternative that succeeds.
        (define (alternatives . patterns)
            (define (pattern text)
                (if (empty? patterns)
                    #f ; None succeeded
                    (or (parse (first pattern) text)
                        (parse (alternatives (rest patterns)) text))))
            pattern)
                            
                
So now we can see that parsing a ``(zero-or-more (character-in "a-z"))`` can
yield a list of alphabetical characters. However, we often don't want lists of
characters and we'd rather just like a string. To do this, we can transform the
parse result using a given procedure. Maybe we can write ``(transform
list->string (zero-or-more (character-in "a-z")))`` and expect it to work as a
pattern that produces a matched string? Note how the procedure word
``list->string`` is mnemonic of converting a list to a string, but since a
string consists of a sequence of characters, the list also must be a list of
characters. And yes, you might've guessed that there is a corresponding
``string->list`` word as well.

.. code:: racket

    (define (transform change-form pat)
        (define (pattern text)
            (let ([res (parse pat text)])
                (if res
                    (pattern-match (change-form (pattern-match-result res))
                                   (pattern-match-remainder res))
                    #f)))
        pattern)

The way we're expecting meaning to be constructed out of the word ``change-form``
informs what kinds of meanings we can supply to the first argument of ``transform``.
In this case, ``change-form`` has one argument and its result should serve as a
"pattern match value". ``list->string`` fits this form and is therefore a suitable
"change form" word to use.

We did something significant here. Instead of making a special word that treats
a "list of characters" pattern as a string, we made a general word that can
change the interpretation of any pattern result using a word given as an
argument. [#hof1]_

.. admonition:: **Think**

   Think about it for a few minutes before proceeding. We're entering an
   interesting territory here. When we introduce such a definition for a new
   word where the input type is the same as the output type -- both "pattern"
   in our case -- we'll have to consider how these definitions work with each
   other and ensure that they're all consistent. Words like ``sequence``,
   ``alternatives``, ``one-or-more`` and ``transform`` unlike the basic
   patterns like ``character-in``.


Languages within languages
--------------------------

If you zoom out a little bit, it can look like we're building a small language
to express patterns we want to decipher from text. We're introducing new words
like ``character-in``, ``sequence``, ``alternatives``, ``one-or-more``,
``transform``, etc. that let us talk about specific patterns and how to combine
patterns to make new patterns. This is very much like how language consists of
both a vocabulary (words with meanings) and grammar (how to give meaning to
combinations of words). So here we're laying out a "grammar" for expressing
patterns in strings by introducing a vocabulary and defining the words in such
a way that they can be combined according to the grammar that makes sense to us.

We also sketched out the grammar first before defining the words in Racket.
This is a powerful way to think about a domain. So powerful that much of the
computing infrastructure you may have heard about -- working with tables in
databases (SQL), structuring documents (HTML), styling documents (CSS) -- have
all been built this way in terms of a vocabulary that can be combined in
specific ways to derive meaning. Computer people also like to use the term
"domain specific language" to talk about these languages within languages
that cater to a "domain" (which in our case is patterns in text).

Indeed, with modern computing infrastructure, it is pretty much **Languages all
the way through**. This is also why large language models that's trained on all
public source code available can be very useful in computing.

.. [#hof1] Such a procedure that can use another given procedure to determine
   meaning in some usage context is usually referred to as a "higher order
   procedure" or "higher order function". There is nothing really special about
   this though since we saw right from the beginning that when a word stands
   for a procedure, it is also an ordinary value like anything else because it
   still fits within our metaphor of the word referring to a concept in our
   mind.

