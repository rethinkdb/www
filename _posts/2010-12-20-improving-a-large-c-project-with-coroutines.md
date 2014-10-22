---
layout: post
title: Improving a large C++ project with coroutines
tags:
- announcements
--- 

At the core of RethinkDB is a highly parallel B-tree implementation. Due to
our performance requirements, it is too expensive to create a native thread
for each request. Instead, we create one thread per CPU on the server (logical
CPU in the case of hyperthreading) and use cooperative concurrency within a
thread.

A single thread will have multiple logically concurrent units of control,
taking turns when a unit needs to block. Blocking needs to take place
ultimately for either I/O--waiting for information from the network or disk,
or waiting to be notified that sending information there has completed--or for
coordination with other threads. On top of this, we implemented higher-level
abstractions which also block.

# The previous approach

Blocking is implemented using callbacks. A blocking operation is expected to
return immediately, and it will call a callback when it's done. In Javascript,
callbacks are generally done by passing a function argument. C++ doesn't have
lexically scoped closures or automatic memory management, so we instead pass a
pointer to an object. This object has a virtual method on it for the callback.
Different virtual methods are used for different situations demanding a
callback, allowing the same object to be passed as the callback to several
different blocking functions. Reusing an object among callbacks allows state
to be shared easily among multiple blocking operations.

This all sounds like a very sensible model, but there are several reasons why
it becomes annoying to program in:

  * A single logical procedure must be implemented as a class, with state in instance variables rather than locals because it involves blocking
  * The flow of control is broken up over several different virtual method bodies
  * A single virtual method might be invoked as the callback for multiple situations, requiring complex logic to maintain the state of the object and dispatch to the appropriate implementation

Each of these problems creates more boilerplate code and more chances to
introduce bugs.

# The coroutines interface

For the past couple weeks, I've been working on a solution: use coroutines to
implement blocking rather than callbacks, so a single function can have
blocking locations and still look like a straight line of code. It turns out
to be fairly straightforward to do this in C or C++. I used the open-source
library
[libcoroutine](http://www.dekorte.com/projects/opensource/libcoroutine/) for
this task. Libcoroutine is a thin, cross-platform wrapper around native APIs
for coroutines like [fibers](http://msdn.microsoft.com/en-us/library/ms682661) on Windows and
[ucontext.h](http://en.wikipedia.org/wiki/Setcontext) on POSIX systems,
falling back to a setjmp/longjmp-based implementation on other platforms.
Libcoroutine provides functions for launching new coroutines, switching among
coroutines and initializing the coroutine system.

On top of this, I built a small library in C++ to make them easier to use,
integrating coroutines with our existing system for scheduling the issuing of
callbacks. The API for coroutines is very simple, summarized by this fragment
of a header file:
    
    struct coro_t {
        static void wait();
        static coro_t *self();
        void notify();
        static void move_to_thread(int thread);
    
        template
        static void spawn(callable_t fun);
    
        template
        struct cond_var_t {
            cond_var_t();
            var_t join();
            void fill(var_t value);
        };
    
        template
        static cond_var_t *task(callable_t fun);
    
        struct multi_wait_t {
            multi_wait_t(unsigned int notifications);
            void notify();
        };
    };

For convenience, I included versions of `coro_t::task` and `coro_t::spawn`
which take up to five parameters, using
`[boost::bind](http://www.boost.org/doc/libs/1_45_0/libs/bind/bind.html)`. The
above is all the functionality we need for concurrency in RethinkDB. The first
five commands are really all that's needed, and tasks and condition variables
are implemented in terms of these.

The `coro_t::self` function returns the currently executing coroutine. This
coroutine has a single public method, notify, which schedules the coroutine to
be resumed if it is blocked. (It is an error to notify a coroutine which is
not blocked.) A coroutine can cause itself to block by calling the function
`coro_t::wait`. Hopefully, the coroutine will have passed itself to another
location so that it can be notified. `coro_t::spawn` causes a new coroutine to
be launched, given an object with `operator()` defined. It doesn't bother
returning the coroutine that it spawned, because that would be redundant with
self.

It turns out to be natural to have a a coroutine's flow of execution be the
only thing that can get a reference to itself. The general pattern is that a
coroutine gets itself, sends a pointer of itself to another coroutine, and
then waits until that coroutine notifies it. For example, say we have a legacy
procedure `void write_async(file_t*, data_t*, write_callback_t*)` which reads
a file and calls the virtual method `void
write_callback_t::on_write_complete()`. In terms of the above primitives, a
coroutine-blocking version of `write_async` is constructed as follows:

    struct co_write_callback_t : public write_callback_t {
        coro_t *waiter;
        co_write_callback_t() : waiter(coro_t::self()) { }
        void on_write_complete() { waiter->notify() }
    };
    void write(file_t *file, data_t *data) {
        co_write_callback_t cb;
        write_async(file, data, &cb);
        coro_t::wait();
    }

# Coroutines and multithreading

`coro_t::move_to_thread` is a special function which causes a coroutine to be
blocked, transported to another thread and resumed there. RethinkDB is usually
configured to use one thread per CPU. We attempt to minimize sharing between
threads, but sometimes communication is necessary. It is often natural to
express this communication as a single line of control, executing on one
thread for some time and later on another thread. For example, requests are
dispatched on all threads, and the B-tree is divided into slices that are
owned by each thread. If a request handled by a particular thread needs to
look at a B-tree portion maintained by a different thread, then
`coro_t::move_to_cpu` can be used to transfer control from one thread to the
other and back. In the old system, a callback would be registered which would
be called on the other thread, and all state would have be stored in an object
shared between the threads, with ownership passed from one to the other. With
coroutines, the stack forms the shared object, and programming is much more
natural.

For code that moves between threads in a stack-based manner, the
[RAII](http://en.wikipedia.org/wiki/RAII) idiom can make it easier to use
`move_to_thread`. The coroutine library provides a special class whose
constructor moves to a thread given as a parameter, and whose destructor moves
back to the thread observed to be in use when the object was created. If this
object is stack-allocated, it will have the effect of switching threads for a
particular block scope.

(I'm not sure whether `move_to_thread` is guaranteed to work in POSIX in
general with `ucontext.h` or Linux in particular, but it seems to function
correctly as I'm using it. Windows fibers explicitly support being passed
among threads. On some platforms, libcoroutine does not behave properly when
passing coroutines between threads--coroutine pausing and resuming may take
some thread-local state with it, corrupting the thread where the coroutine is
resumed.)

# Higher-level abstractions on coroutines

A few utilities are built on top of these primitives. A condition variable, of
type `coro_t::cond_var_t<var_t>` is a variable that is initially unfilled, but
can be filled with a particular value. Calling join on a condition variable
causes the current coroutine to block until the condition variable is filled,
returning that value. `task` is a convenient way to spawn a coroutine to fill
a condition variable, given a function returning the value for the condition
variable. If RethinkDB receives a large request for several B-tree lookups,
each of these can be issued concurrently as separate tasks. The condition
variables returned are joined in sequence, as the values are returned to the
client.

The class `coro_t::multi_wait_t` is used for a situation where a coroutine
needs to wait until it is notified a number of times. This is used in the
implementation of reporting performance statistics. When gathering statistics,
a request is given to each thread to put their portion of the information in a
known location. When each thread completes, it reports its completion by
notifying a `multi_wait_t` object about its completion. The main coroutine
waits until the `multi_wait_t` causes it to resume execution. It can then gather
the results from all threads and report the aggregated statistics.

# Memory management and ownership

You might be wondering: this is C++, where is all the manual memory
management? You never have to call `delete` on coroutines or condition
variables. Memory is handled completely by the coroutine library, and it was
simple to implement. When the function object that `spawn` calls returns, the
coroutine object corresponding to it is immediately deallocated. It makes no
sense to notify a coroutine which has returned, and there is no useful state
within a coroutine. Similarly, condition variables deallocate themselves after
they are joined.

To program in this model, it's useful to have an idea of ownership. Each
coroutine has exactly one owner, a unique piece of code that's supposed to
notify it when it's in a particular waiting state. A condition variable's
owner is the only thing allowed to join it. It could be useful to have a type
system that enforces these invariants (uniqueness/linear typing anyone?), but
no such system exists in C++, so the constraints go unchecked except at
runtime if asserts are turned on.

# Thinking ahead

This change isn't completed yet. There's a lot of code that can be simplified
using coroutines, and it'll take a long time to change everything and be sure
that no bugs were introduced. There will also be some work to ensure that
coroutines don't cause performance regressions. My first attempt hurt
throughput significantly, but I believe that I can get the slowdown down to a
few percent with some work. While that isn't perfect, the software engineering
benefits of coroutines are just too good to ignore. Shorter, simpler code
using coroutines will enable us to implement better algorithms and achieve
higher performance while maintaining correctness.
