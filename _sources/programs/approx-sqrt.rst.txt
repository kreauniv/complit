Approximate square-root
=======================

Calculating the square-root of a number is easy in most programming languages,
because most of them provide some word like ``sqrt`` that will give you the
square root of a "floating point number". Racket has this too. However, it is
instructive to know how it is calculated.

A common method is based on Newton-Raphson iteration, and goes like this.

1. Let ``a`` be the number for which  you want to calculate the square root.

2. You start with an estimate. Any non-zero value will do. If you don't know
   what to start with, you can just pick ``1.0``.

3. If :math:`x_n` is your current estimate, you can improve this estimate
   using the following calculation - 

   .. math::

       \begin{array}{rcl}
       x_{n+1} & = & \frac{1}{2}\left(x_n + \frac{a}{x_n}\right)
       \end{array}

4. Keep doing this calculation until you have a close enough value.
   How do you decide if it is "close enough"? You can just check
   if :math:`|x_n^2 - a| < \epsilon` for some small enough :math:`\epsilon`
   like, say, :math:`10^{-10}`. If you don't need such high precision,
   you can use a larger value like, say, :math:`10^{-5}`.

Now, given this procedural knowledge, how can we use the IPD method
to write a program for this?

The top level
-------------

We might start out by expressing in words what we want - 

.. code:: racket

   (define (approximate-square-root a)
      (define precision 1e-10)
      (define estimate 1.0)
      (repeat-until improved-estimate sufficiently-precise a precision estimate))

Note how we captured the two key ideas we need to deal with using words for
them -- ``improved-estimate`` which is a calculation to get a better estimate
given an initial estimate, and ``sufficiently-precise`` which is a predicate
that can tell us when to stop. We also note that ``a``, ``precision`` and
``estimate`` need to be provided to these as information as otherwise the words
won't know what to calculate with.

``repeat-until``
----------------

We know the *shape* of ``repeat-until``, though we haven't yet decided
what the shape of its arguments must be.

.. code:: racket

   (define (repeat-until improved-estimate sufficiently-precise a precision estimate)
      ...)

If the end condition is met already, the given estimate becomes the result.
Otherwise we need to repeat with a better estimate. We can capture this
like - 

.. code:: racket

   (define (repeat-until improved-estimate sufficiently-precise a precision estimate)
      (if (sufficiently-precise a precision estimate)
          estimate
          (repeat-until improved-estimate sufficiently-precise a precision (improved-estimate a estimate))))

``sufficiently-precise``
------------------------

Now that we know how ``sufficiently-precise`` will be used, we can define
it quit easily --

.. code:: racket

   (define (sufficiently-precise a precision estimate)
      (< (abs (- (* estimate estimate) a)) precision))

``improved-estimate``
---------------------

This is now just the Newton-Raphson calculation step.
We know its shape from how we used ``next-step`` above.

.. code:: racket

   (define (improved-estimate a estimate)
      (* 0.5 (+ estimate (/ a estimate))))

Remarks
-------

That's basically it. Put the fragments together and test it on some examples
to convince yourself that it works as advertised.

Now try the following tasks.

.. admonition:: **Task 1**

   Generalize to k-th root of ``a`` where ``k`` is a positive integer.
   For this, the iteration is --

   .. math::

       \begin{array}{rcl}
       x_{n+1} & = & \frac{1}{k}\left((k-1)x_n + a/x_n^{k-1}\right)
       \end{array}

   You will also have to define a way to calculate :math:`x^k`.

.. admonition:: **Task 2**

   The general Newton-Raphson iteration to solve the equation
   :math:`f(x) = 0` goes like this --

   .. math::

       \begin{array}{rcl}
       x_{n+1} & = & x_n - \frac{f(x_n)}{f'(x_n)}
       \end{array}

   Use the same approach to write a solver given :math:`f` and :math:`f'` as
   arguments. Use this more general solver to express the solution
   to calculating an approximate square root.

.. admonition:: **Task 3**

   Given a function :math:`f(x)`, its approximate derivative at :math:`x`
   may be written as --

   .. math::

       \begin{array}{rcl}
          f'(x) & \approx & \frac{f(x+\epsilon/2) - f(x-\epsilon/2)}{\epsilon}
       \end{array}

   Write an abstraction which when given a function, gives you its 
   approximate derivative as a function. You could use this as a utility
   to solve the previous task by taking  only one function argument instead
   of two function arguments.


