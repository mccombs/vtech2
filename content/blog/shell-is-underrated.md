---
title: "Shell Is Underrated"
type: "post"
date: 2021-05-04T20:49:38-05:00
subtitle: "Essential unix skill"
image: ""
tags: ["question","unix"]
authors: ["williambaxter"]
draft: false
---

How much time do you spend at the command line? Most programmers say they are
very comfortable there. Most also say they are good shell programmers.  Shell
programming is quirky, and not particularly elegant. Yet it is both
universally available under unix and extremely powerful.  Programming in shell
is an easy way to cobble together simple experimental programs, especially if
you master the art of [unix filters](/blog/unix-filters/).  Sadly, very few
people are competent shell programmers.

Here are a few questions to test your shell knowledge:

- What does `$*` mean in shell?
- What does `$@` mean in shell?

If you know the answer to either of those questions without looking it up,
congratulations! You're more advanced in shell than most people I talk to.

- What is the difference between `$*` and `$@`?
- When do you use one and when do you use the other?

If you have good answers to these questions, you're in an elite group these
days. Everyone who spends time at the command line interacts with shell, but
most are too ignorant of its features to take advantage of it.

Shell is well suited to the [unix
philosophy](https://en.wikipedia.org/wiki/Unix_philosophy), in which you write
a suite of programs and assemble a constellation of those programs to solve
a problem. The same tools in a different constellation can solve a different
problem. *The tools do not need to embody the solution!*

This is an amazingly flexible form of reuse.  No commonly available
programming language is better for constructing data processing pipelines than
shell.

### Which shell?

The attentive reader will note that I have not defined "shell". Indeed the
shell you interact with on the command line may differ from the one that runs
your programs.  If you are writing a throw-away program, choose whatever shell
you like. If you are programming anything that you intend to move from one
system to another, there is only one choice: [Bourne
shell](https://en.wikipedia.org/wiki/Bourne_shell).

The Bourne shell is present (approximately, for those who already know) on
every unix base system. You want your programs to be portable, right? Use
Bourne shell.

### Questions

Here are some additional questions to test your shell savvy:

- Why is it bad form to use `#!/bin/bash` as your [shebang
  line](https://en.wikipedia.org/wiki/Shebang_(Unix))?
- What is the right shebang line for a bash script?
- Explain the following code.
```
    shout() { echo "$0: $*" >&2; }
    barf() { shout "fatal: $*"; exit 111; }
    safe() { "$@" || barf "cannot $*"; }
```
- How would you use it?
- What is the common alternative in shell context?
- Discuss the trade-offs between this code and that alternative?

If you understand these three shell functions fully, you already know more
about shell than 80% of programmers. If you are interested in systems
administration, rapid command-line prototyping, flexible data processing, and
portable command-line utilities, you are well advised to become an expert in
shell. It's an essential skill for the unix programmer.
