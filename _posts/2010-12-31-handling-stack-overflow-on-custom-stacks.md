---
layout: post
title: Handling stack overflow on custom stacks
tags:
- announcements
--- 

On my computer, the callstack of a new process is around 10MB*. Modern
operating system automatically reserve some amount of virtual memory and
install protections on the page below the stack to create a segmentation fault
on stack overflow. This ensures that a stack overflow won't go corrupting
random parts of memory.

We want to have a lot of coroutines, so they should have smaller stacks, maybe
16 or 64KB. This makes stack overflow an even greater possibility, but at the
same time, coroutines implemented in user space don't get this checking for
free--we have to build it ourselves. In the process, we can even do better: we
can give some information about the coroutine which crashed. Here's the idea:

  * Memory-protect the page on the bottom of the stack (remember, x86
  	callstacks grow down) to disallow reads and writes.
  * Install a signal handler for SIGSEGV.
  * In the handler, examine which address caused the page fault: 
    * If the address is within the protected page of a coroutine, report a
      callstack overflow for the coroutine, with a stack backtrace and some
      information about the coroutine that crashed.
    * Otherwise, report a generic memory fault at the address, with a stack
      backtrace.

I'm treating stack overflow as a fatal error here, but a more nuanced approach
is possible: rather than killing the whole database, it could just kill that
coroutine and return to the scheduler. But this particular kind of error
tolerance would require broad modifications to RethinkDB which we're not ready
to do. I could also make stack overflow resize the stack to be larger, but
this is difficult in C++ because there might be pointers into the stack.

Nothing here is complicated to implement, but it involves the interaction of a
few different system calls, which I'll explain in this article.

# Manipulating memory protection

We want to allocate the stack and make the bottom page unreadable and
unwritable. The [`mprotect`](http://linux.die.net/man/2/mprotect) system call
manipulates memory protection, and
[`getpagesize`](http://linux.die.net/man/2/getpagesize) tells us how big a
page is (it might not be 4KB). [`valloc`](http://linux.die.net/man/3/valloc)
makes a page-aligned memory allocation.

    void *stack = valloc(stack_size);
    mprotect(stack, getpagesize(), PROT_NONE);

When deallocating the stack, be sure to reset the protection to what it was
before.

    mprotect(stack, getpagesize(), PROT_READ|PROT_WRITE);
    free(stack);

# Installing a signal handler

In order to catch the segfault, we have to install a signal handler. The
[`signal`](http://linux.die.net/man/2/signal) system call won't cut it--it
just doesn't give us enough information about what happened. Instead, we have
to use [`sigaction`](http://linux.die.net/man/3/sigaction), which takes a
whole struct of parameters, not just a function pointer, for how to handle the
signal. One struct member is `sa_flags`. We have to turn on the `SA_ONSTACK`
flag in order to use a user-provided stack (see below) and the `SA_SIGINFO`
flag, in order to call a function with more information. If `SA_SIGINFO` is
set, then we can set the `sa_sigaction` member to a function which takes a
`siginfo_t` struct as an argument. The `si_addr` member of that struct
contains the address of the location which caused the fault. All together, the
code for establishing the page handler is as follows:
    
    struct sigaction action;
    bzero(&action, sizeof(action));
    action.sa_flags = SA_SIGINFO|SA_STACK;
    action.sa_sigaction = &sigsegv_handler;
    sigaction(SIGSEGV, &action, NULL);

The signal handler itself will print out the CPU where the coroutine was
initialized, but it would be easy to extend to support printing other metadata
contained in the coroutine. `int coro_t::in_coro_from_cpu(int)` reports which
CPU a coroutine was initialized on, or -1 if the address was not from the
protected page of a coroutine stack. `crash` will cause the program to
terminate with the given error message, together with a stack trace.
    
    void sigsegv_handler(int signum, siginfo_t *info, void *data) {
        void *addr = info->si_addr;
        int info = coro_t::in_coro_from_cpu(addr);
        if (cpu == -1) {
            crash("Segmentation fault from reading the address %p.", addr);
        } else {
            crash("Callstack overflow from a coroutine initialized on CPU %d at address %p.", cpu, addr);
        }
    }

# Installing a special stack for the signal handler

By default, when a signal is delivered, its handler is called on the same
stack where the program was running. But if the signal is due to stack
overflow, then attempting to execute the handler will cause a second segfault.
Linux is smart enough not to send this segfault back to the same signal
handler, which would prevent an infinite cascade of segfaults. Instead, in
effect, the signal handler does not work.

To make it work, we have to provide an alternate stack to execute the signal
handler on. The system call to install this stack is called
[`sigaltstack`](http://linux.die.net/man/2/sigaltstack). As a parameter, it
takes a `stack_t`, which consists of a pointer to the base of the stack, the
size of the stack, and some flags that aren't relevant for our purposes.
    
    stack_t segv_stack;
    segv_stack.ss_sp = valloc(SEGV_STACK_SIZE);
    segv_stack.ss_flags = 0;
    segv_stack.ss_size = SEGV_STACK_SIZE;
    sigaltstack(&segv_stack, NULL);

`SEGV_STACK_SIZE` doesn't have to be so big, but it has to be big enough to
call `printf` from. The `MINSIGSTKSZ` constant indicates how big a stack has
to be to execute any signal handler at all. To be on the safe side, used that
constant plus 4096 for `SEGV_STACK_SIZE`. `sigaltstack` should be called
before the associated call to `sigaction` which is intended to register a
signal handler with that stack.

# Operating in a multithreaded environment

If a process calls `sigaction` and then spawns pthreads within it, then those
pthreads will inherit the signal handlers that were already installed.
Apparently, this is not the case for `sigaltstack`: If a signal handler is
installed with `sigaction` using a `sigaltstack`, and a thread spawned from
that process is killed with the right signal, then the installed stack will
not be found! The signal handler must instead be installed on each pthread
individually. I'm not sure whether this is a bug in Linux or just a quirk of
POSIX; in any case, I couldn't find it documented anywhere.

# Pulling it all together

A few simple system calls can allow stack overflows in user-space coroutines to
be handled nicely, providing detailed error messages without runtime overhead
in cases where the stack does not overflow. Indeed, the benchmarks which I
[previously reported]({% post_url 2010-12-23-making-coroutines-fast %}) are
unaffected by this change. Other programming language runtimes, like that of
[Io](https://github.com/stevedekorte/io/blob/master/libs/iovm/source/IoBlock.c#L253)
, checks the height of the callstack on _every_ function call in order to catch
overflow. This technique is more efficient.

Io supports callstacks that will resize on overflow, to a point. Such a
feature is more difficult to implement in C++ because there might be pointers
into the callstack, and weak typing makes it impossible to trace the stacks
and heap to update these even if we wanted to. However, virtual memory may be
usable to implement this resizing. First, it may just work to allocate very
large stacks and not touch them, hoping that the virtual memory system will
ensure that no physical memory or swap space is used for the stacks. But this
might put stress on the kernel's data structures, and it may not work well if
overcommitting is turned off, as it is in some server environments.
Alternatively, `mremap` may be used to expand the stack from the page fault
handler. But I'm not sure how I could reserve a chunk of virtual memory to
expand into, without depending on overcommitting in some cases. None of these
techniques would work out well on 32-bit systems because there isn't enough
address space. This is still something to look into in the future, though.

I implemented stack overflow checking after getting stuck on a particular bug
in the database, and when returning to that bug, I found that this was in fact
the cause! Stack overflow isn't an obscure, uncommon thing, especially when
stacks are small and there might be recursion. Working together with the
operating system allows us to broaden the applicability of these software
engineering benefits to performance-critical code.

* * *

* You can find the value on your computer by running the following program (without optimizations!) and examining the difference between the first and last number, when it terminates with a segfault.

```c
#include <stdio.h>
int main() {
        char stuff[2048];
        printf("I'm at %p\n", &stuff);
        main();
}
```
