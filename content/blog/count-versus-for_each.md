---
title: "Terraform count vs. for_each"
type: "post"
date: 2021-04-10T18:21:30-05:00
subtitle: "Don't count on it"
image: ""
tags: ["infrastructure","question"]
authors: ["williambaxter"]
draft: false
---

Terraform has two mechanisms for provisioning multiple resources (and modules
since version 0.13): `count` and `for_each`. The `count` feature predates
`for_each`. Now that `for_each` is available, there is no reason to use
`count`.

The Terraform
[documentation](https://www.terraform.io/docs/language/meta-arguments/count.html)
says "If your instances are almost identical, count is appropriate. If some of
their arguments need distinct values that can't be directly derived from an
integer, it's safer to use for_each."

This is bad advice. The behavior of `terraform apply` with `for_each` is
entirely different, and better, than the behavior of `count`.

When a resource uses `count`, Terraform creates a list of resources. Suppose
you have `count = 4` for some resource, and you need to destroy the resource
at index 2.  What does the plan look like?

The resources are a list. This means the resources are ordered. Removing one
from the middle of the order causes all resources later in the order to shift
to new positions.  In our scenario, the apply plan will destroy resources at
indexes 2 and 3, and then recreate the resource formerly at index 3 at its new
index of 2. You will not want to encounter this issue more than once!

Fortunately `for_each` does not have this problem. There is no order to
resources under `for_each`, and creating or destroying individual resources
leaves the others in place.

It is trivial to convert a list to a map in Terraform:
```
{for k,v in toset(mylist): k => v}
```
So one can easily provide inputs appropriate to `for_each` instead of `count`.
Unfortunately, converting to `for_each` is not quite so simple. To preserve
existing resource you must remove them from the state and then add them again
under the new `for_each` style reference. Fortunately, you need do this only
once, rather than every time you want to destroy a middle-of-the-list
resource.

Back to the advice from the Terraform
[documentation](https://www.terraform.io/docs/language/meta-arguments/count.html), when should you use `count` rather than `for_each`? The answer is "never".

### Questions

Have you adopted Terraform 0.13 use of `for_each` for modules?

How do you use dependency inversion in your Terraform modules?

Have you used Terragrunt for any projects?
