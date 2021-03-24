---
title: "Too Many Managers"
type: "post"
date: 2021-03-23T13:59:24-05:00
subtitle: ""
image: ""
tags: []
authors: []
draft: true
# This is still crap. Don't publish!
---

What's the best package manager? The answer among modern programmers seems to
be "The one written in and for my language of choice."

For Python, it's `pip`. For OCaml it's `opam`. For node it's `npm`. For Rust
it's `cargo`. For Haskell it's `cabal`. For Go it's `Modules`. For Python,
it's `conda`. For Node it's `yarn`... Uh oh!

Sadly the trend now runs toward conflating project-build managers and package
managers, and implementing package management separately in each language. Out
of fashion are make files, text-based manifests, and other simple dependency
management tools. In fashion are package managers fully integrated with
a programming language, each with its own quirks, bugs, learning curve,
shortcomings, and strengths. It's an example of programmers insisting on
reinventing bugs from the past.

This conflation of package management with programming plays nicely with the
assumptions that you want to program only in your favorite language, and that
your production deployment environment resembles your development environment.
Step out of that monolingual setting, or add constraints like servers with
limited network access, and you get many headaches. Every significant project
I have seen is a mixed-language project. Most that I have seen have server
environment constraints very different from development environment
constraints.

In a mixed-language environment you need tooling that stands apart from any
particular language and handles the system-specific side of package
management: package dependency management, installation, removal, network
deployment. The crop of language-specific package managers interfere with this
useful separation of concerns.

One reaction to this unfortunate state of affairs is to level up to
a [Universal Package Manager](https://github.com/replit/upm). Will this help?
Maybe. The README says

>UPM does not implement package management itself. Instead, it runs a package manager for you... UPM eliminates the need to remember a huge collection of language-specific package manager quirks and weirdness, and adds a few nifty extra features like dependency guessing and machine-parseable specfile and lockfile listing.

This is both admirable and dubious. Unified interface helps a lot, but removal
of complexity is better. If something does go wrong with package management,
you face the same difficulty as before. A cleaner separation between build and
deploy is more important.


At Vertalo we use [FreeBSD Ports](https://www.freebsd.org/ports/) and
[`pkg`](https://www.freebsd.org/cgi/man.cgi?query=pkg&sektion=&n=1) to manage
packages. Ports is our old-fashioned version of UPM on the build side, as it
can invoke any external project-build manager. And `pkg` is 
Ports is old and quirky, yet
flexible and stable. It wraps whatever project-build manager you use for any
component of your project.

Ports is well [documented](https://www.freebsd.org/ports/references/). It has
quirks, yet is extremely flexible for use with small and large projects and in
mixed-language settings. The
[poudriere](https://www.freebsd.org/cgi/ports.cgi?query=poudriere&stype=all)
port lets you build software in bulk and stage it as packages for use on all
of your servers.

Not long ago, poudriere got support for [overlay
ports](https://github.com/freebsd/poudriere/pull/713). Overlays extend the
ports tree with your private ports by layering on top of an existing ports
tree, thereby avoiding the need to maintain a fork of the full ports tree.
That makes a world of difference for port maintenance.

We build ports for our AWS servers with poudriere with overlays. Our overlay
ports include:

- [moarvm](https://www.moarvm.org/)
- [nqp](https://github.com/Raku/nqp)
- [djbdns](https://cr.yp.to/djbdns.html)
- [ligo](https://ligolang.org/)
- [rakudo](https://rakudo.org/)
- [tezos](https://gitlab.com/tezos/tezos)
- [openresty](https://openresty.org/en/)

plus a slew of smaller ports specific to our environment, and more major
additions on the way.

With this approach we spend more time porting new programs to FreeBSD and less
time on packaging. We still incorporate programs designed for and built with
language-specific package managers, but using Ports ties them together with
relative ease. And once built, pkg lets us deploy them swiftly and easily
across as many servers with full scripting.


What is the best package manager?

Have you deployed a poudriere server? With overlays?

Are you a port maintainer?

How did you configure a package server to administer a multi-host deployment
environment?

