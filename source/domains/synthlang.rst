Modelling sound synthesis
=========================

.. admonition:: **Note**

   This is based on https://kreauniv.github.io/comp308/synthlang.html
   from the COMP308 course.

The original PLAI course used arithmetic to introduce some ideas. In this
variant, we use a simple model of sound synthesis processes to construct a
vocabulary we can use to render synthetic sounds to a sound file. The
motivation to introduce these small "domains" is that they help anchor the
discussions on programming languages, and when they are not too familiar, help
students ask key questions.

.. note:: We're not going to be building a full fledged synth toolkit. What
   we're interested in is making (hopefully) some simple sounds and
   compositions. The ideas here form the basis for `Synth.jl`_, though that is
   written in Julia.

.. _Synth.jl: https://github.com/srikumarks/Synth.jl

Growing a language for sounds
-----------------------------

We're about to launch off a precipice in our efforts to figure out a language
for generating sounds. When we set out on such a task in any domain, there are
a few things we need to do to build up our understanding of the domain first.
What are you going to build a language for if you don't understand it in the
first place? We'll need to --

1. Get a sense of the ":index:`vocabulary`" we want for working with sound generation.

2. Get a sense of how we wish to be able to generate sounds, transform them
   or combine more than one to form a new sounds.

3. Figure out the essence of sound composition -- i.e. a minimal ":index:`core
   language`" in which we we can express the ideas we're interested in. Translate
   more specific ideas into this core language.

Note that we do not need to get all of this right at the first shot. We can
take some reasonable steps and improve what we have at hand when we recognize
the opportunity. To do that effectively, we'll need to keep our eye on the
mentioned "minimal core" as we go along.

.. index:: Guy Steele, Growing a language talk

.. admonition:: **Credits**

    This section is named in honour of an amazing talk of the same title by Guy
    Steele, the co-creator of Scheme - `Growing a language, by Guy Steele
    <gal_>`_ (youtube link) given in 1998. It is a fantastic talk and a great
    performance & delivery, that I much recommend students watch and
    contemplate on. The beginning of the talk may unfortunately put off some as
    it appears sexist, but Guy is aware of it and explains himself a little
    into the talk. So do press on.

.. _gal: https://www.youtube.com/watch?v=_ahvzDzKdB0

A plausible vocabulary
----------------------

We hear a sound when a pattern of vibration hits our ear drums, causing them to
vibrate according to the incoming air pressure patterns. When these vibrations
are represented in a computer, we need to convert them into numbers and so we
"sample" them at a sufficiently high frequency (called the "sample rate") and
measure the pressure values at these instants. This process is called "analog
to digital conversion" ("ADC" for short). We can then reproduce these sounds by
converting this sequence of numbers into air pressure influences emitted
through a speaker. This process is called "digital to analog conversion" ("DAC"
for short).

The auditorily simplest sound is a tone with a specific "pitch" and "volume".
Such a tone is a periodic (in time) waveform with a specific *period*
corresponding to its pitch and a specific *amplitude* corresponding to its
volume. The two pairs of concepts are related but not the same. While "pitch"
is a perceptual aspect comparable to "colour" in the visual field, "period" or
equivalently "frequency" is a definable objective property of the waveform
itself. Similarly, while "volume" is a perceptual aspect, "amplitude" is a
definable objective property of the waveform.

.. math::

    \begin{array}{rcl}
    \text{pitch} & \approx \propto & 12 \log_2(\text{frequency}) \text{  } (\text{in semitones}) \\
    \text{volume} & \approx \propto & 20 \log_{10}(|\text{amplitude}|) \text{  } (\text{in dB})
    \end{array}

A tone that lasts for ever at the same amplitude and frequency doesn't make
for much music, does it? At the very least, we want tones to decay over time
to mimic, say, a vibrating string. And we want a pattern of frequencies in
time to make a melody. 

The shape of the periodic waveform that makes a tone defines its "timbre"
(pronounced "tahmbur") or "colour". The most colourless of these tones is
perhaps the "sinewave" - which is easily modelled by the mathematical expression
:math:`\sin(2\pi ft)` where :math:`f` is its frequency and :math:`t` is the
time. This tone has amplitude :math:`1.0` and to get a different amplitude,
we just have to multiply it by the scale factor we need, such as :math:`0.5`.

It so happens that we can build up more complex tones if we only had sinewaves
available at our disposal, by mixing sine waves of different frequencies with
different amplitudes.

The above description gives us a starting point for building up our vocabulary.
To build up our language, we are free to think at as high a level as we want to.
Our only intent here is to capture the idea of how we wish to construct a sound,
without concern for how we're actually going to turn the construction into actual
sound. S-expressions are great for this purpose, so let's dive in.

A sinewave oscillator that is vibrating at a particular frequency can be written
as --

.. code:: racket

   (oscil <freq>)

If we want to scale this oscillation to a different
amplitude, we can write it as -- 

.. code:: racket

    (mod <amp> (oscil <freq>))

This is already interesting in many ways.

1. By writing :rkt:`(mod <amp> (oscil <freq>))` we're saying "make a new tone with
   a different volume by scaling this oscillation. This means the following expression
   should be interpretable too - :rkt:`(mod <amp1> (mod <amp2> (oscil <freq>)))`.
   There is already a "sound transformation as expression composition" emerging here.

2. We have another choice at hand - where if we're always going to think of an oscillator
   as having an amplitude and a frequency, we could've written :rkt:`(oscil <amp> <freq>)`
   and the leave the details for later. 

.. admonition:: **Think**

   Is any one approach better than the other in some objective sense for our
   domain? Note that neither of the approaches is "wrong".

We've left out what the :rkt:`<amp>` and :rkt:`<freq>` are supposed to be. Obviously we
want to be able use fixed numbers for these like :rkt:`(mod 0.5 (oscil 440.0))` which
is a tone oscillating at :math:`440\text{Hz}` with an amplitude of :math:`0.5` ... and
we should have that make sense in our language. But what would something like this mean?

.. code:: racket

    (mod (oscil 2.0) (oscil 440.0))

The only reading is that we're varying the ampltiude of the 440Hz oscillation
at a low frequency of 2Hz. When we render this as a sound snippet, we would perhaps
expect the volume to go up and down audibly. 

.. admonition:: **Question**

   How many times should you expect the **volume** to go up and down every
   second in this case?

This is called "amplitude modulation" in synthesis parlance. To "modulate" means
to "vary" and in this context we're varying the "amplitude". So could we also perhaps have
the frequency of the oscillator here be modulated? -

.. code:: racket

    (oscil (mod 440.0 (oscil 2.0)))

Let's think about what the above expression could mean. We can pick it apart bit by bit.

1. :rkt:`(oscil 2.0)` is something we know - a sine wave oscillation between :math:`-1.0`
   and :math:`1.0` that oscillates twice every second.

2. So :rkt:`(mod 440.0 (oscil 2.0))` is a sinewave oscillation that varies between 
   :math:`-440.0` and :math:`440.0` twice every second.

3. If step 2 is supposed to be in the frequency position of the outermost
   :rkt:`(oscil ...)`, that would stand for the concept "an osciallator whose
   frequency varies from :math:`-440.0` to :math:`440.0` Hz twice every second.
   Negative frequencies are indistinguishable to the ear from positive
   frequencies since they're both "oscillations". So this will sound like the
   frequency is oscillating between :math:`0.0` Hz to :math:`440.0` Hz four
   times a second. 

In audio synthesis parlance, we call this "frequency modulation".

We're building up a language for expressing simple sounds. So now we may want to
ask what if I want to express the idea of the frequency oscillating between, say, 300Hz
and 400Hz twice a second instead of from 0 to 440Hz. How might we want to write that?

.. admonition:: **Think**

   Try to come up with a few ways of expressing that idea on your own first,
   using s-expressions. It is just a way to write it down. We don't yet need
   to consider how we're evaluating it.

Here is a candidate.

.. code:: racket

    (oscil (+ 350.0 (mod 50.0 (oscil 2.0))))

While that looks reasonable, we're playing too loose with our notation here.

.. admonition:: **Think**

    What exactly is too loose about that notation? Think about it first for 5
    minutes before proceeding because spoilers are ahead.

It is like we want to think about adding a number ("350.0") with an expression
that we think of as sound (:rkt"(mod 50.0 (oscil 2.0))") or at least as an
"oscillation". The simpler thing to do here instead of rethinking the notion
of addition is to look closely at what we meant when we used the number 
:math:`440.0` as a frequency or the number :math:`0.5` as the amplitude.
In particular, we considered using an :rkt:`(oscil 2.0)` in place of the
amplitude number :math:`0.5`!

While we wrote a number, we chose to model these two aspects as plain numbers,
but what we meant was that these numbers stand for values that don't change over
time. If we make that notion explicit, we may write it as :rkt:`(konst 440.0)`
and :rkt:`(konst 0.5)`.

Now since :rkt:`(konst 300.0)` and :rkt:`(oscil 2.0)` are the same *kinds* of 
things, we can define the operation of "mixing" two such waveforms by introducing
another word :rkt:`mix`.

.. code:: racket

    (oscil (mix (konst 350.0) (mod (konst 50.0) (oscil 2.0))))

In our case, we might just want to define :rkt:`mix` using mathematical
addition sample by sample, i.e. :rkt:`(mix (konst a) (konst b)) = (konst (+ a
b))`. Similarly we have :rkt:`(mod (konst 0.0) <expr>) = (konst 0.0)`.
We should also be expecting the following to hold --

.. code:: racket

    (mix <s1> <s2>) = (mix <s2> <s1>)
    (mix <s1> (konst 0.0)) = <s1>
    (mod <s1> (konst 0.0)) = (mod (konst 0.0) <s1>) = (konst 0.0)
    (mod (konst 1.0) <s1>) = <s1>
    (mix <s1> (mix <s2> <s3>)) = (mix (mix <s1> <s2>) <s3>)
    (mod <s1> (mod <s2> <s3>)) = (mod (mod <s1> <s2>) <s3>)
    (mod <s1> (mix <s2> <s3>)) = (mix (mod <s1> <s2>)
                                      (mod <s1> <s3>))

If we further wish to generalize :rkt:`(mod (mix (konst a) (konst b)) <s1>) =
(mix (mod (konst a) <s1>) (mod (konst b) <s1>))`, we might want to add the
following symmetry as well, though it is not an inevitable conclusion. --

.. code:: racket

    (mod <s1> <s2>) = (mod <s2> <s1>)

So we understand what our "mix" and "mod" expressions now mean and we're
starting to describe properties of these operations. Given how closely we
thought of "mix" as being addition and "mod" as being multiplication, we should
very much expect to model these using those mathematical operations.

.. admonition:: **Stuff, structure and properties**

    When we're working out a particular domain, it is useful to look at three
    aspects - a) what is the "stuff" we're working with .. the nouns, b) how
    are we making this stuff using other stuff .. i.e. what is the structure
    we're adding to these nouns? and c) what properties do these combination
    and transformation operations have.

While we can describe some sounds that last forever using the above constructs,
we also want to be able to describe time limited and time shifted sounds.

1. If we want to talk about sound :rkt:`<a>` **starting** 4.0 seconds from t=0, we
   can write :rkt:`(after 4.0 <a>)` where :rkt:`<a>` is any expression that
   stands for a sound. This adds another "structure", whose "property" is
   :rkt:`(after d1 (after d2 <s1>)) = (after (+ d1 d2) <s1>)`. Since we can't
   move sounds into the past, we treat all the :rkt:`d1` and :rkt:`d2` that are
   less than 0.0 as equivalent to 0.0. So we should more precisely express that
   property as - :rkt:`(after d1 (after d2 <s1>)) = (after (+ (max 0.0 d1) (max
   0.0 d2)) <s1>)`.

2. We also want to be able to stop or "cut" a sound after some seconds. We can write
   this idea as :rkt:`(cut dur <snd>)`. The meaning here is that until :rkt:`dur`
   elapses, this expression is indistinguishable from :rkt:`<snd>`. After :rkt:`dur`
   elapses, this expression is equivalent to :rkt:`(konst 0.0)`. Such a "cut"
   has the property :rkt:`(cut d1 (cut d2 <snd>)) = (cut (min d1 d2) <snd>)`
   assuming both durations to be positive.

Wait a minute. We want to make music, i.e. we want to be able to **sequence** or
"stitch" sounds one after another to make patterns. We can introduce another
operator to stitch two sounds together at a certain time.

.. code:: racket

    (stitch <s1> dur <s2>)

The meaning being before :rkt:`dur` has elapsed, the resultant sound is equivalent to
:rkt:`<s1>` and :rkt:`<s2>` begins and :rkt:`<s1>` ends exactly after :rkt:`dur`
has elapsed. Just by how we're talking about it, it should be apparent that we can
express this idea using things we've already described.

.. code:: racket

    (stitch <s1> dur <s2>) = (mix (cut dur <s1>) (after dur <s2>))

.. admonition:: **Syntactic sugar**

    We just defined a "new" concept in terms of structure we've already
    articulated. At such a point, we should pause and think whether we want
    this new word to be genuinely a new word in our language or something we
    introduce as "syntactic sugar" in it - something that we'll mechanically
    expand out into its definitionally equivalent form before constructing the
    specified sound using only the primitive structures. On the other hand, we
    can still choose to make this a primitive for other auxiliary reasons such
    as performance -- for example if we're able to implement the "stitch"
    operator more efficiently if we do it directly rather than through the
    primitive operators in our language.

    If we perform the expansion, then we gain the ability to examine the
    correctness properties of our audio renderer without having to worry about
    another operator that needs to be examined/tested with every other
    operator. The savings from this during language design are significant
    enough that it is an important consideration before you choose your stand.

.. admonition:: **Think**

    What is the difference between the above definition of :rkt:`stitch`
    and the alternative below? (Refer to definitions of ``cut`` and ``after``
    given earlier.) --

    .. code:: racket

        (stitch <s1> dur <s2>) 
            = (mix (mod (cut dur (konst 1.0)) <s1>)
                   (mod (after dur (konst 1.0)) <s2>))

Apart from oscillations, it is useful to be able to modulate sounds using linear
"envelopes". So we'll add one final operator for that.

.. code:: racket

    (line a dur b)

This represents a "sound" (not really a sound, but just a time varying value)
that starts at the value :rkt:`a` and over the course of :rkt:`dur` seconds
linearly rises (or falls) to :rkt:`b` and after :rkt:`dur` seconds stays fixed
at value :rkt:`b`.

A model for the sound expressions
---------------------------------

In our case, we can model each sound as a "generator" which, when asked,
produces a sample and another generator for the rest of the sound.
Note the recursive way we've described it. We can directly model this
structural recursion using functions.

A "gen" is a function from Real to a "step", which is a structure that holds
the next generated value, and the "gen" to use to produce further sample
values. This parallels how `cons` makes an extended list given a value and
another list. The argument to a "gen" is a real number `dt` - the time interval
between two consecutive samples.

.. code:: racket

    (struct step (val gen))

    ; As a warm up, we define the simplest of them.
    (define (konst v)
      (lambda (dt)
        (step v (konst v))))

The above definition of :rkt:`konst` already demonstrates the "temporal
recursion" in the definition. The definition of `konst` essentially says --

    The next value to be produced is the constant `v`. All values following
    that are to be produced by `(konst v)`.

By induction, we know that all the same values generated by `konst` will be the
same value - therefore a constant in time. For the other operators, we're going
to have to do something similar.

`(oscil freq phase)`
~~~~~~~~~~~~~~~~~~~~

We can use a sinusoid to define the idea of an oscillator. For an oscillator
with constant frequency :math:`f`, oscillator, we might just be able to write
it as :math:`\sin(2\pi ft + \phi)`. However, such an oscillator is not very
musically interesting and to get more interesting sounds and melodies, we'll
want to be able to change ("modulate") the frequency of the oscillator over time.
Therefore the "phase" we use to compute the sinewave at an instant must change
according to the *instantaneous* value of the frequency at each time step.

.. code:: racket

  ; The notation `[phase 0.0]` means the `phase` argument is optional
  ; and when not given will take the default value of 0.0.
  (define (oscil freq [phase 0.0])
     (lambda (dt)
       (let ([f (freq dt)])
         (step (sin (* 2 pi phase))
               (oscil (step-gen f) (+ phase (* (step-val f) dt)))))))
  
`(mod a b)`
~~~~~~~~~~~

The word "modulate" is overloaded in the audio synthesis world. In the simplest
case, it just means "one signal multiplied by another". The multiplication varies
one signal in some understandable way. The more generalized sense in which "modulate"
gets used is to indicate "change". For example "frequency modulation" means 
"frequency that changes over time" and the operation used might be addition
or multiplication.

.. code:: racket

  (define (mod a b)
    (lambda (dt)
      (let ([av (a dt)] [bv (b dt)])
        (step (* (step-val av) (step-val bv))
              (mod (step-gen av) (step-gen bv))))))
  
`(stitch a dur b)`
~~~~~~~~~~~~~~~~~~

Being able to sequence two sounds a given time apart is a useful "primitive" to
have at hand. What we understand of this `stitch` word is that `(stitch a 0 b)
= b` and otherwise it behaves like `a`, reducing the `dur` one step at a time.

.. code:: racket

   (define (stitch a dur b)
      (lambda (dt)
          (if (<= dur 0.0)
              b
              (let ([s (a dt)])
                 (step (step-val s)
                       (stitch (step-gen s) (- dur dt) b))))))

`(mix a sa b sb)`
~~~~~~~~~~~~~~~~~

Mixing two sounds is a basic operation. Depending on the mixed sounds, our ear
can often tease apart what is mixed. This is how we can hear a band or an orchestra
playing "at the same time", since the sound pressure waves produced by all the instruments
of the band or orchestra all add up when they reach our ears.

.. code:: racket

  (define (mix a sa b sb)
    (lambda (dt)
      (let ([av (sa dt)] [bv (sb dt)])
        (step (+ (* a (step-val av)) (* b (step-val bv)))
              (mix (step-gen av) (step-gen bv))))))
  
  
`(after dur s)`
~~~~~~~~~~~~~~~

A "melody" consist of playing "notes" at specific times. This means that a gen
that produces a note will need to be delayed until it is time to play it. 
We'll use the word "after" to suggest that the sound represented by a given
generator `s` should be played "after" the given duration.

.. code:: racket

  (define (after dur s) (stitch (konst 0.0) dur s))

Note that `(after 0.0 s) = s` but until then, it is basically silence.

`(cut dur s)`
~~~~~~~~~~~~~
  
Combining sounds in an editor often involves editor-like cut-copy-paste 
operations. A "cut" is a moment when one sound ends and another begins.
Let's use `cut` to represent the ending of a sound - meaning after a
given duration, the gen will only produce silence. Observe how we
express the logic of "behave exactly like `s`, until the duration
runs out".

.. code:: racket

  (define (cut dur s) (stitch s dur (konst 0.0)))
  
`(line a dur b)`
~~~~~~~~~~~~~~~~

Synth sounds are often shaped by "envelopes" and the "linear ramp"
is a fundamental shape that can be combined to make envelopes of
various kinds. A very common such envelope shape is called "ADSR",
short for "attack decay sustain release" - the four segments of the
envelope.

Here, we take the line to be from a value `a` to a value `b` over
a given duration, but stays constant at `b` after the duration elapses.

.. code:: racket

  (define (line a dur b)
    (if (<= dur 0)
        (konst b)
        (lambda (dt)
          (let ([a2 (+ a (* dt (/ (- b a) dur)))])
            (step a (line a2 (- dur dt) b))))))

Rendering sounds
~~~~~~~~~~~~~~~~

Given this representation, we can "render" a sound to a file using a procedure of
the following shape (i.e. pseudo-code) -

.. code:: racket
   
    (define (render-to-file filename sndgen dur sample-rate)
      (call-with-output-file filename #:exists 'replace
        (lambda (f) 
          <write-file-header>
          (define (loop dt t gen)
            (when (<= t dur)
              (let ([v (g dt)])
                (write-sample-to-file f (as-float32 (step-val v)))
                (loop dt (+ t dt) (step-gen v)))))
          (loop (/ 1.0 sample-rate) 0.0 sndgen))))

.. admonition:: See `asynth.rkt <asynthrkt_>`_

    You can simply load the linked :rkt:`asynth.rkt` file to define the
    interpreter we're working through here as it provides all the necessary
    code and more sound operators if you want to play around. Since the
    symbols it provides have the same name as the structs we've defined here,
    you'll want to import it with a prefix like -

    .. code:: racket

        (require (prefix-in a: "./asynth.rkt"))

    The function ``konst`` in the file will now be available as ``a:konst``.

.. _asynthrkt: https://github.io/kreauniv/complit/blob/main/source/src/asynth.rkt

Concluding remarks
------------------

We explored the domain of synthetic sounds by defining a vocabulary and
modelling that vocabulary of "generators" as functions that produce one sample
value at one time step. The pattern we saw here -- where a "generator" produces
a value and leaves the future values to be produced by another dynamically
determined generator -- is applicable in various other scenarios where "state"
needs to change in a particular order. So, alongside learning a bit of sound
synthesis, we've also learnt a pattern you might recognize when you run into it
next time.
 





