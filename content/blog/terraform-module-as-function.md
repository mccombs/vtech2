---
title: "Terraform Modules as Functions"
type: "post"
date: 2021-03-03T19:40:21-06:00
subtitle: "Using no-resource modules to build config maps"
image: ""
tags: ["infrastructure","question"]
authors: ["williambaxter"]
draft: false
---

How do you create user-defined functions in
[Terraform](https://www.terraform.io/)?

The definition of
a [module](https://www.terraform.io/docs/language/modules/develop/index.html)
in terraform resembles that of a function with side effects implemented
through resources. We use zero-resource modules as Terraform functions. Below
is a simple example use of `for_each_slice` taking input from
`var.config.hosts`. For each element in the input map it slices out the
corresponding value the named keys, throwing an error for missing keys or keys
that fail a requirement, such as being a non-empty string.


```tf
module for_each_slice {
  source = "../for_each_slice"

  keys = [
    "ami",
    "associate_public_ip_address",
    "cpu_credits",
    "ebs_optimized",
    "fqdn_private",
    "fqdn_public",
    "host_tags",
    "host_type",
    "instance_type",
    "subnet_name",
    "volume_size",
    "volume_type",
    "volume_iops",
  ]

  nonempty_string = [
    "host_name",
  ]

  data = var.config.hosts
}
```

The definition of `for_each_slice` looks like this:


``` tf
locals {
  data = var.data
  keys = var.keys

  data_keys = keys(local.data)
  data_entry_keys = { for k,v in local.data: k => keys(v) }

  nonempty_string = var.nonempty_string
  want_keys = concat(local.keys,local.nonempty_string)
  optional  = var.optional
  
  validate = [
    for k in local.data_keys: [
      for want in local.want_keys:
        contains(local.data_entry_keys[k],want) ? true : tobool("missing key: ${k}.${want}")
    ]
  ]
  validate_nonempty = [
    for k in local.data_keys: [
      for want in local.nonempty_string:
        "" != local.data[k][want] ? true : tobool("empty string for key: ${k}.${want}")
    ]
  ]

  result = {
    for k,v in local.data:
      k => merge(
        { for want in local.want_keys : want => v[want] },
        { for want in local.optional : want => v[want] if contains(local.data_entry_keys,want) },
      )
  }
}
```

Combined with the built-in `merge()` function, `for_each_slice` lets us build
maps of parameters containing validated keys, throwing errors in case of
violation. We use this approach to feed complex configurations to modules that
create resources, without the awkward use of individual module parameters. The
separation of configuration construction and resource creation promotes reuse
of both function modules and resource-creating modules across our cloud
infrastructure.

### Questions

How do you use Terraform modules?

What usage have you invented that we should adopt?






