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

   ; We keep the result and the unmatched string together
   ; as a single value by defining a "structure".
   (struct pattern-match (result remainder))

   (define (character-in allowed-chars)
        (define (pattern text)
            (if (> (string-length text) 0)
                (let ([first-char (string-ref text 0)]
                      [remainder (substring text 1)])
                    (pattern-match first-char remainder))
                #f))
        pattern)

``sequence``
------------

We can now define ``sequence`` like this --

.. code:: racket

   ; One possible definition of `sequence`
   (define (sequence pat1 pat2)
     (define (pattern text)
       ; Try the first pattern on the given text.
       (let ([p1 (parse pat1 text)])
         (if p1
            ; If the first pattern succeeded, try the second
            ; pattern on the remainder.
            (let ([p2 (parse pat2 (pattern-match-remainder p1))])
              (if p2
                 ; Collect both the results as a cons pair.
                 ; We can collect them in any other way we choose too.
                 ; Q: Can you think of advantages to using `cons` here?
                 (pattern-match (cons (pattern-match-result p1)
                                      (pattern-match-result p2))
                                (pattern-match-remainder p2))
                 #f))
            #f)))
     pattern)

Now, when we do ``(parse (sequence (character-in "a-z") (character-in "0-9")) "a1b2c3")``,
we can expect to get ``(pattern-match (cons #\a #\1) "b2c3")`` as the result.

``alternatives``
----------------

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
    number of arguments. We'll use a different word ``sequence*`` for this, since
    it actually has a different meaning for the two-argument case than ``sequence``.

    .. code:: racket

        ; sequence* will match and provide a list of patterns.
        ; Notice that we're defining it in terms of `sequence`
        ; without explicitly constructing a ``pattern`` procedure.
        (define (sequence* . patterns)
            (if (empty? patterns)
                empty-pattern
                (sequence (first patterns)
                          (apply sequence* (rest patterns)))))

        ; Will match the first alternative that succeeds.
        (define (alternatives . patterns)
            (define (pattern text)
                (if (empty? patterns)
                    ; None succeeded
                    #f
                    ; `or` here will try the remaining alternatives
                    ; only if the first pattern failed.
                    (or (parse (first pattern) text)
                        (parse (apply alternatives (rest patterns)) text))))
            pattern)
                            

Many-ness
---------

With the definition of ``alternatives``, our definition of ``zero-or-more``
and ``one-or-more`` gains validity and completeness.

.. code:: racket

   (define (one-or-more pat)
      (sequence par (zero-or-more pat)))

   (define (zero-or-more pat)
      (alternatives empty-pattern (one-or-more pat)))

.. admonition:: **Think before proceeding**
   
   Given how we've defined ``alternatives``, is our definition of
   ``zero-or-more`` acceptable? There is a subtle "bias" in how
   we've dealt with ``alternatives`` that affects this.

   Spoilers below.

What exactly is ``empty-pattern``. Since there is always a region of any string
that can be considered to be "empty of any characters", the ``empty-pattern``
should succeed to match at any cursor position within a string.

This is a problem for ``zero-or-more`` though. Because ``empty-pattern``
will always succeed, ``(zero-or-more pat)`` is effectively the same as
``empty-pattern``!! We need to give the second option priority before
falling back on the empty pattern. So we ought to have defined it
as --

.. code:: racket

   (define (zero-or-more pat)
      (alternatives (one-or-more pat) empty-pattern))

   (define (empty-pattern text)
      (pattern-match empty text))

    (define (failed-pattern text) #f)

Meaning through reinterpretation
--------------------------------

So now we can see that parsing a ``(zero-or-more (character-in "a-z"))`` can
yield a list of alphabetical characters. However, we often don't want lists of
characters and we'd rather just like a string. To do this, we can transform the
parse result using a given procedure. Maybe we can write ``(reinterpret
list->string (zero-or-more (character-in "a-z")))`` and expect it to work as a
pattern that produces a matched string? Note how the procedure word
``list->string`` is mnemonic of converting a list to a string, but since a
string consists of a sequence of characters, the list also must be a list of
characters. And yes, you might've guessed that there is a corresponding
``string->list`` word as well. In this context, you can also read
``list->string`` as "list as string" instead of "list to string". The former
aligns better with the notion of "reinterpretation" whereas the latter has a
more "operational" quality to it.

.. code:: racket

    (define (reinterpret interpretation pat)
        (define (pattern text)
            (let ([p1 (parse pat text)])
                (if p1
                    (pattern-match (interpretation (pattern-match-result p1))
                                   (pattern-match-remainder p1))
                    #f)))
        pattern)

The way we're expecting meaning to be constructed out of the word
``interpretation`` informs what kinds of meanings (i.e. "values") we can supply
to the first argument of ``reinterpret``. In this case, ``interpretation``
has one argument and its result should serve as a "pattern match value".
``list->string`` fits this form and is therefore a suitable "change form" word
to use. In this context, we're using ``list->string`` to help "interpret" a
list of characters as a string.

.. hint:: How can we read and understand ``(interpretation
   (pattern-match-result p1))``? Firstly, we're temporarily giving the matching
   of ``pat`` against ``text`` a local name ``p1``. As long as such a name is
   local within a few lines, giving such an otherwise cryptic name is often not
   a problem. Beyond such local text though, we'd need a better name. So each
   occurrence of ``p1`` within the ``(let...)`` form now refers to the same
   pattern match. By wrapping ``(interpretation ..)`` around the
   ``(pattern-match-result p1)``, we're indicating that the given
   interpretation now governs whatever ``(pattern-match-result p1)`` means --
   it may be a character in some cases, a string in other cases, or a number or
   a list of strings, etc. Whatever it is, ``interpretation`` is expected to be
   appropriate to that context for that expression to be meaningful.

We did something else significant here. Instead of making a special word that
treats a "list of characters" pattern as a string, we made a general word that
can change the interpretation of any pattern result using a word given as an
argument. [#hof1]_ 

With this collection of words, we can now express the textual form of a simple
string like this --

.. code:: racket

    (define simple-string 
        (reinterpret without-quotes
                     (sequence* (character-in "\"")
                                (reinterpret list->string
                                             (zero-or-more (character-not-in "\"")))
                                (character-in "\""))))

    ; In our context where a sequence we have produces a list
    ; of three items with the middle (second) one being the string
    ; that's of interest to us, `without-quotes` just means `second`.
    (define without-quotes second)
    
We can also express a simple decimal fractional number like ``-3.1415`` --

.. code:: racket

    (define decimal-number
        (sequence* (optional (character-in "-+"))
                   (one-or-more digit)
                   (optional (sequence (character-in ".")
                                       (one-or-more digit)))))

    (define digit (character-in "0123456789"))

    (define (optional pat)
        (alternatives pat empty-pattern))


Now you can start to see how these definitions relate to the Backus-Naur grammar
we introduced when we started talking about parsing. When we read the definition
of the ``decimal-number`` we just stay within the language of the domain of
patterns we're interested in describing with no indication of how all this
translates to the **process** of matching patterns in strings. 

.. admonition:: **Think**

   Think about it for a few minutes before proceeding. We're entering an
   interesting territory here. When we introduce such a definition for a new
   word where the input type is the same as the output type -- both "pattern"
   in our case -- we'll have to consider how these definitions work with each
   other and ensure that they're all consistent. Words like ``sequence``,
   ``alternatives``, ``one-or-more`` and ``reinterpret`` take patterns and
   construct new patterns with them, unlike the basic patterns like
   ``character-in``.

Pattern exercises
-----------------

Define a pattern for each of the following using the words above.

1. **Word**: Define a pattern to match the first word of a sentence.
   Remember that we expect it to be capitalized.

2. **Sentence**: Define a pattern to match the first sentence in a given
   string.

3. **HTML tag**: A HTML tag looks like ``<tag>..some text...</tag>``. 
   Define a pattern to match the tag at the start of a given string,
   like ``"<strong>you're it!</strong>"``.

4. **Morse code**: You're given a string in Morse code like this --
   ``".... . .-.. .-.. --- .-- --- .-. .-.. -.."``. Define a pattern
   to extract the sequence of single-space separate Morse characters.
   Can you define it so that when you use such a Morse string with
   ``parse`` with your pattern, you get the decoded letters?
   (See this code table - https://morsecode.world/international/morse2.html)
   
   .. hint:: You might find the defining a new pattern word ``literal``
       that's used like ``(literal "xyz")`` to match the literal string
       can make your Morse pattern simpler to define.

       .. collapse:: Expand to see a definition of ``literal``.

            .. code:: racket

                (define (literal str)
                    (define (pattern text)
                        (if (string-prefix? text str)
                            (pattern-match str (substring text (string-length str)))
                            #f))
                    pattern)

5. **Arithmetic**: For simple arithmetical expressions involving only "+" and
   "*" (times). The rules are in BNF form below - 

   .. code:: 

      Expression -> NaturalNumber
      Expression -> "(" Expression Operator Expression ")"
      Operator -> character-in("+*")
      NaturalNumber -> one-or-more(Digit)
      Digit -> character-in("0123456789")

   Start off by writing some examples of valid and invalid expressions.

   .. tip:: This may not be an easy one given what we've looked at so far.
      But persist and see how far you can get.


Languages within languages
--------------------------

If you zoom out a bit, it can look like we're building a small language to
express patterns we want to decipher from text. We're introducing new words
like ``character-in``, ``sequence``, ``alternatives``, ``one-or-more``,
``transform``, etc. that let us talk about specific patterns and how to combine
patterns to make new patterns. This is very much like how language consists of
both a vocabulary (words with meanings) and grammar (how to give meaning to
combinations of words). So here we're laying out a "grammar" for expressing
patterns in strings by introducing a vocabulary and defining the words in such
a way that they can be combined according to the grammar that makes sense to
us.

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

The underlying notion here is what's called a "formal system" -- which consists
of "axioms" that are valid expressions as given, and "theorems" which can be
used to derive other valid expressions given valid expressions. While this
notion is general and there is no guarantee that all formal systems have some
relevant applications, when the rules of a formal system do relate to rules in
the world in some "domain", then the formal system serves as a useful proxy to
"reason" about the domain. Much of the task of working with specific domains
through computing comes down to the creative process of constructing formal
systems whose components and rules map well to the domain.

Algebra
-------

When we define such a suite of words that produce and consume values of a
certain kind, we have expectations of some patterns of consistency amongst
them so we can **reason** about the language without getting into the
operational details. In the case of string patterns, we want to be able
to look at the definition of, say, ``decimal-number`` and immediately
know how to use it without having to think about the exact computations
that happen when we parse a string with it.

Here are some such expectations -

1. ``(alternatives pat1 pat2 ... patN)`` should be replaceable with ``patK``
   in a particular situation if ``patK`` were the first pattern to successfully
   match against the given text. In fact, in any pattern expression containing
   the ``alternatives`` form, the form should be replaceable with any one of
   the patterns and still preserve the integrity of the total expression.

2. ``(sequence pat1 (sequence pat2 empty-pattern))`` is the same as
   ``(sequence* pat1 pat2)``. This is similar to ``(cons a (cons b empty))``
   being the same as ``(list a b)``.

3. ``(sequence pat empty-pattern)`` is expected to be equivalent to
   ``(reinterpret list pat)``.

4. ``(alternatives pat empty-pattern)`` is always expected to succeed since
   ``empty-pattern`` will always succeed.

.. admonition:: **Task**

   Think through and convince yourself that these hold. Can you think of
   any other such equivalences?

We're determining conditions under which one expression can be **substituted**
for another. This substitution should remind you of high school algebra
classes where you manipulated abstract expressions by replacing one
expression with another equivalent expression. For example, when expanding
:math:`(a + b)^2 - 4ab`, you first write it as :math:`a^2 + b^2 + 2ab - 4ab`,
in which you rewrite :math:`2ab - 4ab` as :math:`-2ab` to get 
:math:`a^2 + b^2 - 2ab` which you might further rewrite as :math:`(a - b)^2`.

Operators which obey such a collection of equivalences under various circumstances
are said to have an "algebra". [#algebra]_ Identifying such equivalences gives
us powerful high level thinking tools when working in special domains like
in this case.

.. [#viewsrc] The specific command to use to view the page source
   will depend on the operating system and browser.

.. [#hof1] Such a procedure that can use another given procedure to determine
   meaning in some usage context is usually referred to as a "higher order
   procedure" or "higher order function". There is nothing really special about
   this though since we saw right from the beginning that when a word stands
   for a procedure, it is also an ordinary value like anything else because it
   still fits within our metaphor of the word referring to a concept in our
   mind.

.. [#algebra] Mathematically, there is a more precise definition. For now though,
   it is sufficient for you to make a connection between these expectations in
   the case of string parsing with what you're familiar with from high school
   mathematics.
