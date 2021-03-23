---
title: "Poudriere Overlay Ports"
type: "post"
date: 2021-03-22T21:43:59-05:00
subtitle: "Last-Mile Package Deployment"
image: ""
tags: ["freebsd","infrastructure","question"]
authors: [williambaxter]
draft: true
---

At Vertalo we use [FreeBSD Ports](https://www.freebsd.org/ports/) and
[pkg](https://www.freebsd.org/cgi/man.cgi?query=pkg&sektion=&n=1) for the
"last-mile deployment" of software to our servers. "What?" some ask, "Why
don't you use the vastly superior package manager for my favorite language
XYZ?"

Sadly the trend now runs toward implementing package management separately in
each language. Out of fashion are make files and other simple dependency
management tools. In fashion are package managers fully integrated with the
programming languages, each with its own quirks, bugs, learning curve,
shortcomings, and strengths. It's one example of programmers insisting on
reinventing bugs from the past.

This conflation of package management with programming plays nicely with the
assumption that you want to program only in your favorite language.  Step out
of that monolingual setting and it causes many headaches.

If you work in a mixed-language environment as we do you need tooling that
stands apart from any particular language and handles the system-specific
side of deployment: package dependency management, installation, removal,
network deployment. We address these with Ports and pkg.

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


What ports have you created?

Have you deployed a poudriere server? With overlays?

How did you use a private package server to administer multiple hosts in
a mixed-software environment?

