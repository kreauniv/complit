Recap
=====


**Programs**
    
    Unlike ordinary prose and poetry with human languages, all programs
    are akin to dictionaries that define new words that mean something
    in the context of what the program intends to achieve.

**Words and identifiers**

    Just as a word like "horse" invokes an abstract idea of a horse in your
    mind, an "identifier" is a word in a program that is associated with a
    "value" in the computer. This is true for **all** kinds of values. In fact,
    programs can **only** work with values and introducing vocabulary to
    construct and reference values of various kinds is how we express 
    the intent of a desired "computation".

**S-expressions**

    Just as we can combine the words "horse", "carriage" and "drawn" in a
    phrase like "horse drawn carriage" to invoke a specific meaning in our
    minds, we can express compound concepts in Racket using a form like
    ``(drawn horse carriage)``. The parentheses serve to group the words to
    identify a unit of a compound concept. It also identifies the first word as
    governing the interpretation of such an "expression". This first word is
    also referred to as an "operator". The words that follow the operator word
    represent various aspects that govern what meaning is constructed. For
    instance ``(drawn steam-engine train-car)`` can express another such
    compound concept of a similar kind.

    The meaning of operator words are in general somewhat narrow compared to
    the variety of uses of, say, "drawn" in human languages such as in "horse
    drawn carriage", "pencil drawn animation" and "blood drawn from a vein".

**Composition**

    Expressions that capture such compound concepts can themselves be used
    as values that are part of other compound concepts. In essence, a program
    is one such giant expression that contains a number of definition
    expressions. This property of "composition" is central to all of programming.

**Definition**

    ``(define word meaning)`` introduces a new definition in a particular
    context. When used directly within Racket's "definitions window", the
    word's meaning applies in the context of the entire window. If such a
    ``(define ..)`` is used within another definition, then the definition of
    that word is considered "local" to the surrounding definition and may refer
    to any words introduced by the surrounding definition. A compound idea can
    be defined using ``(define (compound arg1 arg2 ..) <DEFINITION>)``. The
    ``arg1``, ``arg2`` are called "arguments". In the context of the
    ``<DEFINITION>`` (called the "body of the definition"), ``arg1`` and others
    take on the meaning given to them at point at which the ``compound``
    concept is referenced.

**Local words with ``let``**

    The ``(let ([word1 meaning1] [word2 meaning2] ...) <BODY>)`` form
    can be used to introduce words ``word1``, ``word2`` etc. with special
    meaning local to the ``<BODY>`` expression.

**Special forms used often**

    ``(if <condition> <then-expr> <else-expr>)`` expresses a concept that's
    dependent on the ``<condition>``. 

    ``(and cond1 cond2 ..)`` stands for the condition which holds when all
    of the listed conditions hold.

    ``(or cond1 cond2 ...)`` stands for the condition which holds when any
    one of the listed conditions hold.

    ``(not condition)`` stands for the condition that holds when the given
    condition does not hold.

**Self reference**

    Racket permits the definition of a compound concept to reference the
    concept itself. This is called "named recursion". Useful recursive
    definitions only use the concept being defined in a provably "smaller"
    context so eventually the original compound concept can be interpreted
    in full. If this isn't done, then the definition is considered to be
    "circular" and thus invalid. The corresponding computation may never
    terminate.


