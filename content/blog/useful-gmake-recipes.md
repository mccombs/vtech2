---
title: "Useful gmake Recipes"
type: "post"
date: 2021-10-30T10:33:16-05:00
subtitle: "Reusable targets for gmake"
image: ""
tags: ["gnu","unix"]
authors: [williambaxter]
draft: false
---

The venerable `make` program comes in many flavors. It has numerous quirks.
And it offers only a very restricted interface. Yet it remains an important
tool for organizing project builds, deploys, and other operations.

If you use `make` in your projects, chances are that you use `gmake`. Here are
some useful tricks to use with `gmake`.



### Which `make`?

Do you work on a system where `make` is not `gmake`? If you inadvertently
invoke `make`, do you get a long list of syntax errors? Some versions of
`make` use a `.BEGIN` target that executes before anything else, and that
`gmake` sees as an ordinary target. So adding the following target at the end
of your Makefile alerts you to the use of the wrong version of `make`.

```makefile
    .BEGIN:
            @echo "This Makefile requires gmake"; exit 1
```

### Help by Default

The default target in `gmake` is the first target in the Makefile. A `help`
target is a good choice for that position. It is a safe, because it merely
informs without taking potentially dangerous actions. And it encourages the
good practice of documenting all targets in the Makefile.  The `define` and
`info` directives make it easy to write multiline help.

```makefile
    define help_text :=

      help:
        Print this message

        Some more generic help for using this Makefile.

      target:  
        Documentation for target.


    endef

    help:
            @$(info $(help_text))
```

### Confirmations

What if you call `gmake` from the command line, sometimes under unusual
conditions, and in those cases you want to confirm whether to proceed? Use one
of these targets as a prerequisite for any recipe that requires confirmation
before execution.

#### Simple Confirmation

Continue if the answer is 'yes' and stop otherwise.

```makefile
    confirm:
            @printf "Continue? [yes|No] " && \
            read answer && test 'yes' = "$$answer" && exit 0 || exit 1
```

#### Process ID Confirmation

Continue if the answer is 'yes' plus the process ID and stop otherwise.
Functionally the same as simple confirmation, it requires more engagement from
the caller.

```makefile
  confirm-pid:
          @r="$$$$" && \
          printf "Continue? [yes-$$r|No]: " && \
          read answer && test "yes-$$r" = "$$answer" && exit 0 || exit 1
```

#### Git Branch Confirm

Confirm that you are on the intended branch in `git`. Proceed if the current
branch matches the required branch name, otherwise confirm before proceeding.

```makefile
    confirm-git-branch-%:
            @test '$*' = "`git branch --show-current`" && exit 0 || { \
              printf "Current branch '`git branch --show-current`' is not '$*'. Continue? [yes|No] " && \
              read answer && test 'yes' = "$$answer" && exit 0 || exit 1; \
            }
```

### Required Environment Variables

This recipe fails if an environment variable is either unset or empty. Use it
as a prerequisite in a recipe that relies on an environment variable.

```makefile
    require-env.%:
            @test "X$($*)" != "X" && exit 0 || { \
              echo 'Environment variable not set: $*' && exit 1; \
            }
```

### Useful Options

By default, `gmake` announces evern change of directory. These outputs may
interfere with pipelines in recipes, or clutter the otherwise useful output of
your `gmake` run. To avoid this, use the following variable setting.

```makefile
    MAKEFLAGS += --no-print-directory
```

Does your project use the vast array of builtin rules and variables that
support them? It doesn't? Then turn them off.

```makefile
    MAKEFLAGS += -r -R
```

### Further Reading


John Graham-Cumming has written [numerous
articles](https://blog.jgc.org/2013/02/updated-list-of-my-gnu-make-articles.html)
detailing tricks and troubles with `gmake`. He also authored [The GNU Make
Book](https://nostarch.com/gnumake), and the [GNU Make Standard
Library](https://sourceforge.net/projects/gmsl/).


