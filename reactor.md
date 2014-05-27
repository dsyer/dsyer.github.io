# Notes on Reactive Programming

Reactive Programming is sexy (again) and a lot of people are making a
lot of noise about it at the moment, not all of which is very easy to
understand for an outsider and lowly enterprise Java developer like
me. These notes are what I came up with to help me clarify my
understanding of what the noise is about. I have tried to keep them as
concrete as possible, and promise not to mention "denotational
semantics" because I don't have a higher degree in Computer Science
(and if I did it's hard to see how it would help). If you are looking
for a more academic approach and loads of code samples in Haskell, the
internet is full of them, but you probably don't want to be here.

Reactive Programming is often conflated with concurrent programming
and high performance to such an extent that it's hard to separate those
concepts, when actually they are in principle completely
different. This inevitably leads to confusion.  Reactive Programming
is also often referred to as or conflated with Functional Reactive
Programming, or FRP (and we use the two interchangeably here).

Some people think FRP is nothing new, and it's what they do all day
anyway (mostly they use JavaScript). Others seem to think that it's a
gift to developers from Microsoft (who made a big splash about it when
they released some C# extensions a while ago). In the Enterprise Java
space there has been something of a buzz about FRP recently (e.g. see
the [Reactive Streams initiative](http://www.reactive-streams.org/)),
and as with anything shiny and new, there are a lot of easy mistakes
to make out there, about when and where it can and should be used.

## What Is It?

Reactive Programming is a style of micro-architecture involving
intelligent routing and consumption of events, all combining to change
behaviour. That's a bit abstract, and so are many of the other
definitions you will come across online. We attempt build up some more
concrete notions of what it means to be reactive, or why it might be
important in what follows.

The origins of Reactive Programming can probably be traced to the
1970s or even earlier, so there's nothing new about the idea, but
they are really resonating with something in the modern
enterprise. This resonance has arrived (not accidentally) at the same
time as the rise of microservices, and the ubiquity of multi-core
processors. Some of the reasons for that will hopefully become clear.

Here are some useful potted definitions from other sources:

> The basic idea behind reactive programming is that there are certain
> datatypes that represent a value "over time". Computations that
> involve these changing-over-time values will themselves have values
> that change over time.

and...

> An easy way of reaching a first intuition about what it's like is to
> imagine your program is a spreadsheet and all of your variables are
> cells. If any of the cells in a spreadsheet change, any cells that
> refer to that cell change as well. It's just the same with FRP. Now
> imagine that some of the cells change on their own (or rather, are
> taken from the outside world): in a GUI situation, the position of
> the mouse would be a good example.

(from
[Terminology Question on Stackoverflow](http://stackoverflow.com/questions/1028250/what-is-functional-reactive-programming))

FRP has a strong affinity with high-performance, concurrency,
asynchronous operations and non-blocking IO. However, in principle FRP
has nothing to do with any of them. It is certainly the case that such
concerns can be naturally handled, often transparently to the caller,
when using an FRP model. But the actual benefit, in terms of handling
those concerns effectively or efficiently is entirely up to the
implementation in question (and therefore should be subject to a high
degree of scrutiny). It is also possible to implement a perfectly sane
and useul FRP framework in a completely synchronous, single-threaded
way (and it's not at all unusual to do so).

## Reactive Use Cases

The hardest question to get an answer to as a newbie seems to be "what
is it good for?" Here are some examples from an enterprise setting
that illustrate general patterns of use:

**External Service Calls** Many backend services these days are
REST-ful (i.e. they operate over HTTP) so the underlying transport
is fundamentally blocking and synchronous. Not obvious territory for
FRP maybe, but actually it's quite fertile ground because the
implementation of such services often involves calling other services,
and then yet more services depending on the results from the first
calls. With so much IO going on if you were to wait for one call to
complete before sending the next request, your poor client would give
up in frustration before you managed to assemble a reply. Having said
that, it sometimes seems like some commercial sites on the internet
operate on exactly that principle, but that's no reason to think it's
a good idea. So external service calls, especially complex
orchestrations of dependencies between calls, are a good thing to
optimize. FRP offers the promise of "composability" of the logic
driving those operations, so that it is easier to write for the
developer of the calling service.

**Highly Concurrent Message Consumers** Message processing, in
particular when it is highly concurrent, is a common enterprise use
case. Reactive frameworks like to measure micro benchmarks, and brag
about how many messages per second you can process in the JVM. The
results are truly staggering (tens of millions of messages per second
are easy to achieve), but possibly somewhat artificial - you wouldn't
be so impressed if they said they were benchmarking a simple "for"
loop. However, we should not be too quick to write off such work, and
it's easy to see that when performance matters, all contributions
should be gratefully accepted. Reactive patterns fit naturally with
message processing (since an event translates nicely into a message),
so if there is a way to process more messages faster we should pay
attention.

**Spreadsheets** Perhaps not really an enterprise use case, but one
that everyone in the enterprise can easily relate to, and it nicely
captures the philosophy of,and difficulty of implementing FRP. If cell
B depends on cell A, and cell C depends on both cells A and B, then
how do you propagate changes in A, ensuring that C is updated before
any change events are sent to B? If you have a truly active framework
to build on, then the answer is "you don't care, you just declare the
dependencies," and that is really the power of a spreadsheet in a
nutshell. It also highlights the difference between FRP and simple
event-driven programming - it puts the "intelligent" in "intelligent
routing".

**Abstraction Over (A)synchronous Processing** This is more of an
abstract use case, so straying into the territory we should perhaps be
avoiding. There is also some (a lot) of overlap between this and the
more concrete use cases already mentioned, but hopefully it is still
worth some discussion. The basic claim is a familiar (and justifiable)
one, that as long as developers are willing to accept an extra layer
of abstraction, they can forget about whether the code they are
calling is synchronous or asynchronous. Since it costs precious brain
cells to deal with asynchronous programming, there could be some
useful ideas there. Reactive Programming is not the only approach to
this issue, but some of the implementaters of FRP have thought hard
enough about this problem that their tools are useful.

This Netflix blog has some really useful concrete examples of real-life use cases:
[Netflix Tech Blog: Functional Reactive in the Netflix API with RxJava](http://techblog.netflix.com/2013/02/rxjava-netflix-api.html "The Netflix Tech Blog: Functional Reactive in the Netflix API with RxJava")

## Comparisons

If you haven't been living in a cave since 1970 you will have come
across some other concepts that are relevant to Reactive Programming
and the kinds of problems people try and solve with it. Here are a few
of them with my personal take on their relevance:

**Ruby Event-Machine** The [Event Machine][em] is an abstraction over
concurrent programming (usually involving non-blocking IO). Rubyists
struggled for a long time to turn a language that was designed for
single-threaded scripting into something that you could use to write a
server application that a) worked, b) performed well, and c) stayed
alive under load. Ruby has had threads for quite some time, but they
aren't used much and have a bad reputation because they don't always
perform very well. The alternative, which is ubiquitous now that it
has been promoted (in Ruby 1.9) to the core of the language, is
[Fibers][fiber] (sic). The Fiber programming model is sort of a
flavour of coroutines (see below), where a single native thread is
used to process large numbers of concurrent requests (usually
involving IO). The programming model itself is a bit abstract and hard
to reason about, so most people use a wrapper, and the Event Machine
is the most common. Event Machine doesn't necessarily use Fibers (it
abstracts those concerns), but it is easy to find examples of code
using Event Machine with Fibers in Ruby web apps
(e.g. [see this article by Ilya Grigorik][ilya], or the
[fibered example from em-http-request][emhttp]).  People do this a lot
to get the benefit of scalability that comes from using Event Machine
in an I/O intensive application, without the ugly programming model
that you get with lots of nested callbacks.

[em]: https://github.com/eventmachine/eventmachine
[fiber]: http://www.ruby-doc.org/core-1.9.3/Fiber.html
[ilya]: http://www.igvita.com/2009/05/13/fibers-cooperative-scheduling-in-ruby
[emhttp]: https://github.com/igrigorik/em-http-request/blob/master/examples/fibered-http.rb

**Actor Model** Similar to Object Oriented Programming, the Actor
Model is a deep thread of Computer Science going back to the
1970s. Actors provide an abstraction over computation (as opposed to
data and behaviour) that allows for concurrency as a natural
consequence, so in practical terms they can form the basis of a
concurrent system. Actors send each other messages, so they are
reactive in some sense, and there is a lot of overlap between systems
that style themselves as Actors or Reactive. Often the distinction is
at the level of their implementation (e.g. `Actors` in
[Akka](http://doc.akka.io/docs/akka/current/java.html) can be
distributed across processes, and that is a distinguishing feature of
that framework).

**Deferred results (Futures)** Java 1.5 introduced a rich new set of
libraries including Doug Lea's "java.util.concurrent", and part of
that is the concept of a deferred result, encapsulated in a
`Future`. It's a good example of a simple abstraction over an
asynchronous pattern, without forcing the implementation to be
asynchronous, or use any particular model of asynchronous
processing. As the [Netflix Blog]() shows nicely, `Futures` are great
when all you need is concurrent processing of a set of similar tasks,
but as soon as any of them want to depend on each other or execute
conditionally you get into a form of "nested callback hell". Reactive
Programming provides an antidote to that.

**Map-reduce and fork-join** Abstractions over parallel processing are
useful and there are many examples to choose from. Map-reduce and
fork-join that have evolved recently in the Java world, driven by
massively parallel distributed processing
([MapReduce](http://research.google.com/archive/mapreduce-osdi04.pdf)
and [Hadoop](http://wiki.apache.org/hadoop/MapReduce)) and by the JDK
itself in version 1.7
([Fork-Join](http://gee.cs.oswego.edu/dl/papers/fj.pdf)). These are
useful abstractions but (like deferred results) they are shallow
compared to FRP, which can be used as an abstraction over simple
parallel processing, but which reaches beyond that into composability
and declarative communication.

**Coroutines** A
["coroutine"](https://en.wikipedia.org/wiki/Coroutines "Coroutine -
Wikipedia") is a generalization of a "subroutine" - it has an entry
point, and exit point(s) like a subroutine, but when it exits it
passes control to another coroutine (not necessarily to its caller),
and whatever state it accumulated is kept and remembered for the next
time it is called. Coroutines can be used as a building block for
higher level features like Actors and Streams. One of the goals of
Reactive Programming is to provide the same kind of abstraction over
communicating parallel processing agents, so coroutines (if they are
available) are a useful building block. There are various flavours of
coroutines, some of which are more restrictive than the general case,
but more flxible than vanilla subroutines. Fibers (see the discussion
on Event Machine) are one flavour, and Generators (familiar in Scala
and Python) are another.

## Reactive Programming in Java

Java is not a "reactive language" in the sense that it doesn't support
coroutines natively. There are other languages on the JVM (Scala and
Clojure) that support reactive models more natively, but Java itself
does not. Java, however, is a powerhouse of enterprise development,
and there has been a lot of activity recently in providing FRP layers
on top of the JDK. We only take a very brief look at two of them (both
of which are part of the Reactive Streams initiative and will
therefore be providing a core of shared interoperable code patterns in
the near future).

### Netflix RxJava

Netflix were using reactive patterns internally for some time and then
they released the tools they were using under an open source license
as
[[Netflix/RxJava](https://github.com/Netflix/RxJava/wikihttp://techblog.netflix.com/2013/02/rxjava-netflix-api.html
"Home · Netflix/RxJava Wiki · GitHub"). They do a lot of programming
in Groovy on top of RxJava, but it is open to Java usage and quite
well suited to Java 8 through the use of Lambdas.

### Project Reactor

Project Reactor is an alternative framework for Java and Groovy users
from the [Pivotal](http://www.gopivotal.com/oss) open source team (the
one that builds Spring, and the team that I work on):
[Usage Guide · Reactor](https://github.com/reactor/reactor/wiki/Usage-Guide
"Usage Guide · reactor/reactor Wiki · GitHub"). There is lots of good API
documentation and descriptions of the abstractions, but lacking any
examples of actual reasons to use it. A couple of sample apps might
give you an idea:
[calling an external service](http://spring.io/guides/gs/messaging-reactor/)
and
[background processing of image thumbnails](http://spring.io/guides/gs/reactor-thumbnailer/).

## Other Resources

[Parallel universe blog on Reactive](http://blog.paralleluniverse.co/2014/02/20/reactive/)

[Of Fibers and Continuations | JavaWorld](http://www.javaworld.com/article/2071370/core-java/of-fibers-and-continuations.html "Of Fibers and Continuations | JavaWorld")

Readable (but unfortunately database-biased) article:
[How is Reactive Programming Different?](http://news.dice.com/2014/01/13/how-is-reactive-different-from-procedural-programming/)

Propaganda: 
[The Reactive Manifesto](http://www.reactivemanifesto.org/)

[Continuation - Wikipedia](https://en.wikipedia.org/wiki/Continuation(which you can think of as state) "Continuation - Wikipedia")

A multilingual framework (including Java):
[Sodium - GitHub](https://github.com/kentuckyfriedtakahe/sodium
"kentuckyfriedtakahe/sodium - GitHub")

[Fork-join docs at Oracle](http://docs.oracle.com/javase/tutorial/essential/concurrency/forkjoin.html)


