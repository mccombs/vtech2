---
title: "What Do You Mean Atomically"
type: "post"
date: 2021-03-24T07:09:25-05:00
subtitle: "Know Your Filesystem"
image: ""
tags: ["question","unix"]
authors: ["williambaxter"]
draft: true
---

Once I worked on a project whose origin predated the widespread use of DNS.
They used `/etc/hosts` files to map host names to IP addresses. This system
had grown to thousands of hosts, and the `/etc/hosts` file was about 1M in
size. After any update, which was handled by a sysadmin, they pushed this file
to all production hosts. I once made a request for a change.

"Wow! You those files atomically when you push, right?"

"What do you mean, atomically?" asked the sysadmin.

True story!


They wrote the file to an NFS-mounted partition and then copied the file into
place on each production host. I was stunned. How did they get away with that
sloppy approach? This sysadmin had privilege on the production hosts, yet had
no idea how their file systems worked.

I never got an answer to the last question, but have always made sure that
everyone I work with understands what atomic operations are, and how to use
them in a unix file system.

### What is an atomic operation?

An atomic operation is indivisible, in that any outside observer can see
either the before state, or the after state, but nothing in between. In other
words, it is an all-or-nothing operation.

### Atomic operations in the file system

Consider the file-system operations you use from the command line. Which ones
are atomic? Of course the answer depends on the file system you use. But unix
file systems are broadly similar in this regard.

If you create a new file with `touch`, is that atomic? If not, what would
a partially-created file look like? What about deleting a file with `rm`? What
about `cp`? Have you ever copied a very large file in background and watched
the destination grow in size on disk? What does that tell you about the
atomicity of file copies? What about opening or closing a file? Renaming
a file? If you are working on
[NFS](https://en.wikipedia.org/wiki/Network_File_System) how does that change
the answers?

### Applying the knowledge

Understanding these basic file-system semantics lets you use the file system
as an ad-hoc database. You can build processing queues in a directory. You can
provide data to programs without risking an incomplete delivery. You can
update your `/etc/hosts` file knowing that no reader will encounter a partial
host list.

Using atomic file-system operations you can avoid a whole class of errors due
to incomplete inputs or intermediate results in a data processing sequence.
Your systems will be more robust and predictable. These are simple and
powerful tools available on any unix host, and well worth knowing.


### Questions

What operations are atomic in the traditional unix file system?

How does the behavior of `mv` vary if there are multiple directories involved?
What about multiple file systems?

Can you write a directory-based job queue using atomic updates?

