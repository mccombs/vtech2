---
title: "Type configuration in Postgresql"
type: "post"
date: 2021-03-24T09:40:21-06:00
subtitle: ""
image: ""
tags: ["postgresql","database"]
authors: ["nolanaguirre"]
draft: true
---

First, I need clarify what I mean by type configuration, sadly I'm not talking about implementing a custom data types in C (props to those who's mind jumped there). What I mean by type is quite literally the column in your tables named "type", the simplest example of this being something like:

```sql
CREATE TABLE example.accounts(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    type TEXT NOT NULL
);
```

Now, the question, how do you constraint the column to a predefined set of values? Let's say we have admin, user, and superuser.

I don't think that most people don't consider how that one column is implemented to be a major design decision. When implementing this column there are are few things to consider, my considerations are listed below:

* How easy is the list to [UPDATE, READ, REUSE]?
    * Update and read are very important for data driven UI, think a dropdown option list.
* How easy is the extention of the type to contain more than one value?
    * Design requirements change and more data maybe be required.
* How easy is the list, or list value to reference in code?
    * This is very important the more business logic is in the database.
* How easy is it to update a value in the set?
    * Doesn't happen much, but very very important if you use these values in functions.

There is an assumption baked into these considerations that type fields have some business logic considerations.
If this type column doesn't have any meaning then why constrain it at all?


Hopefully now there is a bit of clarity as to why this is a major design decision.

Now to start going over some approaches to solving the issue, the short list is here:
* Check constraints
* Enum types
* FK references (TLDR; This one is the industry standard)
* My solution (Type management schema)

#### CHECK constraint

```sql
CREATE TABLE example.accounts(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    type TEXT NOT CHECK (type IN ('admin', 'user', 'superuser'))
);
```
[Postgresql docs](https://www.postgresql.org/docs/12/ddl-constraints.html)

This approach is so bad that I'll be pretending it doesn't exist for the rest of the article.

The shortcomings of this approach are:
* ALL OF THEM!

#### ENUM types

```sql
CREATE TYPE example.account_types AS ENUM(
    "user",
    "superuser",
    "admin"
);
CREATE TABLE example.accounts(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    type example.account_types NOT NULL
)
```
[Postgresql docs](https://www.postgresql.org/docs/12/datatype-enum.html)

Introducing an enum type is an okay way to solve this, but only in very specific situations. Basically, if you're sure the enum type will __never__ change then still probably choose the next option. Even when this holds true, I wouldn't use enums.

The shortcomings of this approach are:
* Updating enums kind of sucks
* Reading enum values requires querying pg_catalog
* Enums cannot be extended beyond one value
* Enums values must be known before adding

The pros of this approach are:
* Very easy to reference in code

If you're still not convinced then let's expand past the type field and naively implement countries with enums. Country isn't a great real world example as the data sets associated with countries is large, leading to a full table instead of an enum, but all the real examples that I've encountered are very application specific.

```sql
CREATE TYPE example.account_types AS ENUM(
    "user",
    "superuser",
    "admin"
);
CREATE TYPE example.countries AS ENUM(
    "United states",
    "Texas"
    ---etc, etc
);
CREATE TABLE example.accounts(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    type example.account_types NOT NULL,
    country example.countries NOT NULL
)
```
Cool, I have some country data in my account, but the requirements just changed and now I need country, country code, and default currency for the country.
When I just needed the country name it seemed like a great idea, but now that I need more data it is clear that enums won't work.

#### Foreign key references (FK references)
This is the industry standard for how to implement this type of constraint. I break this down into two versions "Enum would work" and "Enum would not work".

##### Enum would work
```sql
CREATE TABLE example.account_types (
    type TEXT PRIMARY KEY
);
INSERT INTO example.account_types(type) VALUES ('user'), ('admin'), ('superuser');

CREATE TABLE example.countries (
    name TEXT PRIMARY KEY
);
INSERT INTO example.countries(name) VALUES ('United states'), ('Texas');


CREATE TABLE example.accounts(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    type TEXT REFERENCES example.account_types(type) NOT NULL,
    country TEXT REFERENCES example.countries(name) NOT NULL
);
```
This approach to me is what should be used instead of enums (seen with type), however the cons of this approach are a bit harder to explain (seen with country).

When writing code like:

```sql
FUNCTION example.do_something_based_on_country(account example.accounts) RETURNS VOID AS $$
BEGIN;
    IF(account.country = 'United states') THEN
        -- do some stuff
    END IF;
END;
$$ LANGUAGE PLPGSQL;
```

You now have an issue with extending the table, it can be done but you have to rewrite functions and it's painful.
That's why I only use this approach when enums would work.

Side note: The reason extending the country table is so painful is because every table should have an id column that is a UUID (I exclude single column status tables from this).
I'm aware that this is a debated topic, but this is where I fall on the debate, extending the country table past name means adding the column `id UUID PRIMARY KEY gen_random_uuid()`.

The pros of this approach are:
* Very easy to reference in code
* Read is trivial
* Insert is trivial
* Updating values is easy enough

##### Enum would not work

Just treat the type like another table, have an id and FK reference to that.
The downside here is that you can no longer just check against a string, instead having to query for the id each time.

The downside is as follows:

```sql
FUNCTION example.do_something_based_on_country(account example.accounts) RETURNS VOID AS $$
BEGIN;
    IF(account.country = 'United states') THEN
        -- do some stuff
    END IF;
END;
$$ LANGUAGE PLPGSQL;
```

Becomes this:

```sql
FUNCTION example.do_something_based_on_country(account example.accounts) RETURNS VOID AS $$
BEGIN;
    IF(
        account.country =
        (SELECT id FROM example.countries WHERE name = 'United states')
    ) THEN
        -- do some stuff
    END IF;
END;
$$ LANGUAGE PLPGSQL;
```

This has a few issues:
* The table must start with an id, if you convert from a single column table then you still have to update all functions.
* Querying static values every time feels bad.
* I want to write `account.country = 'United states'`, not a query
* Try updating countries.name values
* __Performance here is not an issue, Postgresql (and most other RDBMS) cache small tables__

This is the way that you should constrain the values of the row,

#### My solution
Given that the industry standard is to use FK constraints, there isn't a reason to reinvent the wheel.
However, Vertalo makes heavy use of Postgresql, we currently have more functions performing logic than we do tables.
Because of this the industry standard leaves a lot to be desired, the main goal of my solution is to make these type values as easy to use as possible.

Basically I want to write code like this:
```sql
FUNCTION example.do_something_based_on_country(account example.accounts) RETURNS VOID AS $$
BEGIN;
    IF(account.country = configuration.countries__usa()) THEN
        -- do some stuff
    END IF;
END;
$$ LANGUAGE PLPGSQL;
```

The idea is pretty simple, in code you want to refer to the country by its name, but structurally that doesn't work, so just create a function that will give you the value and hard code that function in.

Below is an example of a schema build to create these functions:
```sql
-- DO NOT STACK-OVERFLOW-STYLE COPY-PASTA THIS CODE, IT IS EXAMPLE CODE!
CREATE EXTENSION IF NOT EXISTS CITEXT;
CREATE SCHEMA example;

CREATE TABLE example.countries(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    country_name TEXT UNIQUE,
    country_code TEXT UNIQUE,
    currency TEXT --lets no go down the rabbit hole of implementing a type here
);

CREATE SCHEMA configuration;

CREATE TABLE configuration.types(
    type CITEXT PRIMARY KEY
);
INSERT INTO configuration.types(type) VALUES
    ('CITEXT'),
    ('UUID'),
    ('INTEGER'),
    ('BOOLEAN'),
    ('TEXT'); --incomplete list

CREATE TABLE configuration.configuration_values(
    id CITEXT PRIMARY KEY NOT NULL CHECK (NOT id ~ '__factory'),
    value CITEXT NOT NULL,
    type CITEXT REFERENCES configuration.types(type) NOT NULL
);
CREATE OR REPLACE FUNCTION configuration.setup_config_function() RETURNS TRIGGER AS $func$
BEGIN
    EXECUTE FORMAT(
     'CREATE OR REPLACE FUNCTION configuration.%s() RETURNS %s AS $$ ' ||
         'SELECT %L::%s; ' ||
     '$$ LANGUAGE SQL IMMUTABLE PARALLEL SAFE',
        NEW.id, NEW.type, NEW.value, NEW.type);
    RETURN NEW;
END;
$func$ LANGUAGE PLPGSQL;

CREATE TRIGGER configuration_trigger
    AFTER INSERT OR UPDATE ON configuration.configuration_values
    FOR EACH ROW
    EXECUTE PROCEDURE configuration.setup_config_function();


CREATE OR REPLACE FUNCTION configuration.generic_type_function_factory(
    table_name TEXT,
    human_id TEXT
) RETURNS VOID AS $func1$
BEGIN
  EXECUTE FORMAT (
    'CREATE OR REPLACE FUNCTION configuration.__factory_%s() RETURNS TRIGGER AS $func$ ' ||
      'DECLARE ' ||
        'type TEXT; ' ||
      'BEGIN ' ||
        'SELECT data_type INTO type FROM information_schema.columns WHERE table_schema = ' ||
          'TG_TABLE_SCHEMA AND table_name = TG_TABLE_NAME AND column_name = %L; ' ||
        'EXECUTE FORMAT(''INSERT INTO configuration.configuration_values(id, value, type) ' ||
          'VALUES (%%L || ''''__'''' || %s, %%L, %%L) ON CONFLICT ON CONSTRAINT configuration_values_pkey DO UPDATE SET value = EXCLUDED.value'' ' ||
          ', TG_TABLE_NAME, NEW.id, type) USING NEW.%s;' ||
        'RETURN NEW; ' ||
      'END; ' ||
      '$func$ LANGUAGE PLPGSQL; ',
    REGEXP_REPLACE(table_name, '\.', '_' ,'g'), human_id, '$1', human_id);

  EXECUTE FORMAT (
    'CREATE TRIGGER %s ' ||
      'AFTER INSERT OR UPDATE ON %s ' ||
      'FOR EACH ROW' ||
      'EXECUTE PROCEDURE configuration.__factory_%s(); ',
    REGEXP_REPLACE(table_name, '\.', '_' ,'g'), table_name,
    REGEXP_REPLACE(table_name, '\.', '_' ,'g'));

END;
$func1$ LANGUAGE PLPGSQL;

SELECT configuration.generic_type_function_factory('example.countries', 'country_code');
INSERT INTO example.countries(country_name, country_code, currency)
    VALUES ('United states', 'USA', 'USD');
```

The base of this structure is the configuration.configuration_values table.
This table has a trigger on it that creates a function of name configuration.\<id> with return type \<type> that returns the \<value> passed in.
The function it creates is `IMMUTABLE PARALLEL SAFE` so performance should be pretty good, and it allows you to abstract the value of any configuration variable behind a function call.
The original use of this system was environment variables in the database.

The second part of the schema is configuration.generic_type_function_factory. This is a factory that creates functions that wrap the usage of configuration.configuration_values based on a table.
The function that the factory produces isn't fully build, for instance it doesn't handle deletes or updates very well, but it works for the insert only case well.


There are a few other pros that arise from this,
