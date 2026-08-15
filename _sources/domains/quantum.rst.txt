Optional: Modelling quantum computations
========================================

.. note:: This section is only for those who might be interested
   in quantum computation. Others feel free to ignore, though it
   is simple enough to follow if you are somewhat conversant with
   basic mathematics.

One of the ways in which fluent literacy with programming helps
is to help you understand a domain through constructing programs
for it. Here we'll briefly touch on understanding quantum-classical
computation by building a simulator for it. We won't go all the way
to explaining how the mathematics works, but the purpose is to just
give a gist of how one might go about it.

Properties of quantum systems
-----------------------------

When writing programs for a quantum computer, we'll need our
programs to be realistic in the sense that it shouldn't be possible
to violate some core principles of quantum systems.

1. A quantum state, usually written :math:`\ket{\psi}` is not directly
   observable.

2. Given a quantum state, we can apply **unitary operators** on it, which stand
   for physical processes that manipulate the state. This results in the system
   changing its state. We write this as :math:`\ket{\psi'} = \hat{H}\ket{\psi}`
   where :math:`\hat{H}` is some unitary operator. Such operators can mix
   the various states into superpositions without destroying information.

3. When we "measure" a quantum state in some "basis", it collapses to 
   one of the "eigenstates" -- i.e. measuring will project the state
   such that measuring the state again will yield the same state.
   So in this condition, we can know which of the basis states manifested.
   For example, if a quantum system is described by 4 mixed states numbered
   :math:`\alpha_1\ket{1} + \alpha_2\ket{2} + \alpha_3\ket{3} + \alpha_4\ket{4}`, measuring it will
   result in one of the four :math:`\ket{k}` states with a probability of
   :math:`|\alpha_k|^2`. [#norm]_

4. We cannot "copy" a quantum state to another quantum system (called the
   `No-Cloning theorem`_).

5. We cannot "erase" a quantum state (the `No hiding theorem`_). Quantum
   information is always preserved. Even the act of measurement is about
   letting a quantum system interact with its environment and have the
   information in it leak away into the environment.

.. _No hiding theorem: https://en.wikipedia.org/wiki/No-hiding_theorem
.. _No-Cloning theorem: https://en.wikipedia.org/wiki/No-cloning_theorem

The "circuit" formulation of a quantum computer consists of a "register"
of N "qubits" that can be manipulated together using some provided "operators".
These are also called `Quantum logic gates`_.

.. _Quantum logic gates: https://en.wikipedia.org/wiki/Quantum_logic_gate

So the question for us is, given we can compute anything we can compute,
how can we construct a "quantum program" in which the forbidden things
are not possible?

One approach
------------

Since applying an operator to a quantum system changes its state, we can
think of this step as a "mutation" on a state that is not visible to the
"classical" part of our program. When we do need information out of the
quantum register, we need to "measure" it, at which point we get a single
integer identifying which of the various states it "collapsed" into.
Subsequent measurements should give us the same number, and this number
must be random based on the probabilities of the various states possible.

We know that a procedure constructed in a particular context can refer to 
values in that context even when those values are no longer visible by 
other means anywhere else. For example --

.. code:: racket

   > (define (wrap secret password)
       (lambda (given-password)
          (if (equal? password given-password)
              secret
              (error "Wrong password"))))
   > (define packet (wrap "hello" "2874r2"))
   > (packet "afjn") 
   error: Wrong password
   > (packet "2874r2")
   "hello"

We see that the "secret" has been remembered by the procedure because it can
"see" it though we can no longer see the secret after constructing the ``packet``.

We can use this perhaps to hide the full quantum state from our quantum-classical
"program". First off, we can model our program itself as an ordinary procedure,
which has access to quantum operators and measurement that obey the principles
laid out above.

.. code:: racket

    ; A quantum program might look like this
    (lambda (H cnot swap cswap toffoli X Y Z measure)
        ...)

The "operators" can be simply modelled as procedures themselves, but ones which
don't produce any value and only manipulate the invisible quantum state. The only
procedure that produces a "read out" of the quantum register is ``measure`` which
gives us an integer state identifier.

We know how the operators ``H``, ``cnot``, ``measure``, etc. work and how to
implement them on a classical computer, so a  quantum circuit simulator can be
written as shown below. [#measure]_

.. code:: racket

   (define (run-circuit num-qubits initial-state program)
      ... initialize the state of the quantum register as a
          vector of complex values to the given state ...
      (define (H i)
         .. manipulate the state by applying H to the i-th qubit ..
         )
      (define (cnot c i)
         ..manipulate the state by controlling the i-th qubit
           using the c-th qubit as the control ..
         )
      (define (Rx i angle)
         ..quantum state "rotation" ..
         )
      ...
      (define (measure which-qubits)
        .. collapse the state to one of the states
           randomly according to the probabilities
           given by the current amplitudes ..
           )
      ; Note that the "state" will be secret to all the
      ; operators and not be visible to `program`.
      (program H cnot Rx ... measure))

.. note:: In case you've been learning a little about quantum
   computing and wish to see an actual implementation you can play with,
   see `quantum.rkt`_ . You'll need to get this file, place it alongside
   your own .rkt file containing your definitions, and do
   ``(require "./quantum.rkt")`` to bring the ``run-circuit``
   definition into scope for your use. You may also wish to try
   your hand at implementing the other operators described
   in `Quantum logic gate`_ to test your own understanding.

.. _Quantum logic gate: https://en.wikipedia.org/wiki/Quantum_logic_gate
.. _quantum.rkt: https://github.com/kreauniv/complit/blob/main/source/src/quantum.rkt

Note that while ``run-circuit`` has full visibility to the quantum state,
the supplied ``program`` procedure will not. It can only manipulate the
state using the given operators (which produce no result values),
or make a measurement to get a value, but which will collapse the state.
It is therefore impossible (by construction) to provide a program that
uses these gates in a manner that is inconsistent with the rules of
quantum mechanics. Now you're free to explore the world of quantum
computing given such a simulator. What's more, if you imagine a new
kind of gate, you can always implement it (correctly obeying the
rules, of course) in your simulator and write your programs with it.

An interesting consequence of modelling the computation like this is
that we can also now be sure that **any** classical computation can be
mixed in with quantum computation and therefore we have access to a
simulation of a "universal" quantum-classical computer, as long as 
we have all the gates we'll ever need. For example, our ``program``
can make a measurement and take decisions about which further
quantum steps to run based on the results of the measurement.

Lessons
-------

1. Writing a program to model a domain is a good way to understand
   it at a level of detail that might have otherwise escaped us.
   If you want to understand what happens behind the scenes of a
   "production" simulator, write the definitions in ``run-circuit``
   yourself!

2. The fact that a procedure definition can "wrap" (a.k.a. "close over")
   information in its definition context and use it subsequently without
   revealing it in the usage context is called "encapsulation" (one form of it)
   and is a powerful technique to manage programs of all kinds.

3. Separating domain representations from the usage is a great way to
   explore possibilities. In this case of quantum computation, the 
   implementation of state manipulation in ``run-circuit`` can be changed
   to whatever we want without changing any of the "programs" we write
   using these circuit operators, as long as the way the operators are
   used (i.e. their "interface") is not changed.

.. [#norm] These "alphas" (called "amplitudes") can be complex numbers,
   but they must obey :math:`|\alpha_1|^2 + |\alpha_2|^2 + |\alpha_3|^2 + |\alpha_4|^2 = 1`. 

.. [#measure] In general, measurement will be done using an "observable" whose
   operator will collapse the state to one of its "eigenstates". Here we're
   measuring all the qubits directly to avoid further complications in the
   discussion that are not relevant to the point being made here.
