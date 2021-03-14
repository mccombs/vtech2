---
title: "From Zero to Tom Lane"
type: "post"
date: 2021-03-14T14:30:03-05:00
subtitle: "Safety in constraints"
image: ""
tags: ["postgresql","database","question"]
authors: ["williambaxter"]
draft: true
---

The PostgreSQL documentation has this to say in the context of
[constraints](https://www.postgresql.org/docs/13/ddl-constraints.html#id-1.5.4.6.6):

> The NOT NULL constraint has an inverse: the NULL constraint. This does not mean that the column must be null, which would surely be useless. Instead, this simply selects the default behavior that the column might be null. The NULL constraint is not present in the SQL standard and should not be used in portable applications.

Of course the description of the `NULL` constraint is correct, however requiring
that a column must be null does in fact have utility! Here's an example.

Consider a very simple table with a column constrained to null.
```postgresql
CREATE TABLE public.mytable (
  important_data TEXT,
  trigger_args JSONB CHECK (trigger_args IS NULL)
);
```

This insert will fail the check:
```postgresql
INSERT INTO public.mytable VALUES ('not so important','{}'::JSONB);
```

Now add a `BEFORE INSERT` trigger:
```postgresql
CREATE FUNCTION public.mytable_before_insert_trigger() RETURNS TRIGGER AS $$
BEGIN
 -- Do something interesting with trigger_args here.
  NEW.trigger_args = NULL;
  RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER mytable_before_insert_trigger
  BEFORE INSERT ON public.mytable
  FOR EACH ROW
  EXECUTE FUNCTION public.mytable_before_insert_trigger();
```

This insert will succeed:
```postgresql
INSERT INTO public.mytable VALUES ('more important','{}'::JSONB);
```

What's going on here? We use `trigger_args` to pass arguments into the trigger
function. It could leave them in place. For some use cases that's the right
approach, and you don't need the `CHECK` clause. If those arguments are for
table writers and not for table readers, then the `CHECK` clause ensures that
the trigger has cleared them before the insert commits. A trigger that fails
to clear the arguments will also fail to insert the row. So you can safely
pass in arguments knowing they will not appear in the table.

PostgreSQL is an amazing tool, and we make heavy use of it, including
row-level security, and of course this constraint trick. Tell us about your
experience with PostgreSQL.

On a scale from Zero to [Tom
Lane](https://en.wikipedia.org/wiki/Tom_Lane_(computer_scientist)), how well do you know PostgreSQL?

How do you use row-level security?

What systems have you deployed using
[PostGraphile](https://www.graphile.org/)
or
[PostgREST](https://postgrest.org/)?









