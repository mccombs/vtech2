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

THIS IS STILL A DRAFT DO NOT PUBLISH

First, I need clarify what I mean by type configuration, sadly I'm not talking about implementing a custom data types in C (props to those who's mind jumped there). What I mean by type is quite literally the column in your tables named "type", the simplest example of this being something like:

```sql
CREATE TABLE example.accounts(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    type TEXT NOT NULL
);
```

Now, the question, how do you constraint the column to a predefined set of values? Let's say for examples sake we have admin, user, and superuser.

I'm not sure how most people would implement this. I am fairly certain that most people don't consider how that one column is implemented to be a major design decision, I'm a programmer, so I'll just show you why it matters in code.

#### CHECK constraint

```sql
CREATE TABLE example.accounts(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    type TEXT NOT CHECK (type IN ('admin', 'user', 'superuser'))
);
```
[Postgresql docs](https://www.postgresql.org/docs/12/ddl-constraints.html)


This is very bad, do not do this, here's some reasons why:
* Updating this list requires a constraint change
* Trying to reuse this type is impossible
* Trying to list possible values is impossible


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

Introducing an enum type is a pretty good way to solve this, but only in some situations. Basically, if you're sure the enum type will never change then go with enums. In most other cases there are better ways.

The shortcomings of this approach are:
* Updating enums kind of sucks
* Enums can only contain a single value
* Enums values must be known before adding

I realize that the last two of these points is rather odd, seeing as how these are reasons to use an enum, however accepting enums as an answer to the problem assumes full usage knowledge of the column, as well as the limitations of enums.

Let me broaden the scope of this example beyond fields named "type" to explain. The issue we are solving here is not unique to account types, lets add country to the account using the same method.

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
The limitations of enums is now clear, this is what I mean by "full usage knowledge of the column".
The country is obviously too rich a dataset to use enums, I hope most people wouldn't implement it in this way.
This is why I don't use enums, there are times when I could, but I never assume that I fully understand the usage of a column.

Complete sideline, there is a way to make this work, however its an odd one. Ill just throw it below.

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

CREATE TABLE example.countries_table(
    id example.countries PRIMARY KEY,
    country_code TEXT,
    currency TEXT --lets no go down the rabbit hole of implementing a type here
);

CREATE VIEW example.accounts_with_country AS
    SELECT
        account.name,
        country.country_code
    FROM
        example.accounts AS account INNER JOIN
        example.countries_table AS country ON account.country = country.id;
-- wait, why aren't I just using FK references at this point?
```

#### table types
Wait, why aren't I just using FK references at this point?
Before the example, there are many many ways to implement this. They break down pretty simply into "Enum would probably work" and "Enum would not work".

##### Enum would probably work
```sql
CREATE TABLE example.account_types (
    type TEXT PRIMARY KEY
);
INSERT INTO example.account_types(type) VALUES ('user'), ('admin'), ('superuser');

CREATE TABLE example.accounts(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    type TEXT REFERENCES vertalo.account_types(type) NOT NULL
)
```
It's true that this solution has the same basic problems of enums, they each have a much cleaner solution.
Insert into a table vs altering a type, adding a column to example.account_types vs ...all the work to convert off enums

##### Enum would not work
Once the account_types table is no longer one column, it runs afoul of a design principal that I follow. Tables should have the column `id UUID PRIMARY KEY gen_random_uuid()`.
Now we are in the "its just another table" territory, however you'd be forgetting why you wanted to use enums so bady.
Because you want to be able to write queries like
```sql
UPDATE exmaple.accounts SET name = 'bob' WHERE country = 'United states';
-- INSTEAD OF HAVING TO WRITE:
UPDATE exmaple.accounts SET name = 'bob' WHERE country = (SELECT id FROM example.countries_table WHERE country_name = 'United states');
```
And I'll admit, this is a very annoying thing to deal with, especially because you can't just code in the id value because it is a UUID. (Think local dev vs production, they have different values)

This method sucks is because it makes development more annoying. Hard coding values is sometimes correct, say you have a function that has a big if block to do some logic based off country, hard coding there is great.

So, how do we remove fix this?

IMMUTABLE PARALLEL SAFE functions!

The idea is pretty simple, in code you want to refer to the country by its name, but structurally that doesn't work, so just create an IMMUTABLE PARALLEL SAFE function that will give you the value.

```sql
CREATE TABLE example.accounts(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    country UUID REFERENCES example.countries_table(id) NOT NULL
)

CREATE TABLE example.countries_table(
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    country_name TEXT UNIQUE,
    country_code TEXT,
    currency TEXT --lets no go down the rabbit hole of implementing a type here
);

CREATE TABLE example.types(
    id CITEXT NOT NULL,
    value CITEXT NOT NULL
);
CREATE OR REPLACE FUNCTION example.setup_config_function() RETURNS TRIGGER AS $func$
BEGIN
    EXECUTE FORMAT('CREATE OR REPLACE FUNCTION example.%s() RETURNS CITEXT AS $$ SELECT %L::CITEXT; $$ LANGUAGE SQL IMMUTABLE PARALLEL SAFE', NEW.id, NEW.value);
    RETURN NEW;
END;
$func$ LANGUAGE PLPGSQL;

CREATE TRIGGER example_trigger
    AFTER INSERT OR UPDATE ON example.types
    FOR EACH ROW
    EXECUTE PROCEDURE example.setup_config_function();

CREATE OR REPLACE FUNCTION example.generic_type_function(human_id_column TEXT) RETURNS TRIGGER AS $func$
BEGIN
    EXECUTE FORMAT('INSERT INTO example.types(id, value) VALUES (%L, NEW.%s)', NEW.id, human_id_column);

    RETURN NEW;
END;
$func$ LANGUAGE PLPGSQL;

CREATE TRIGGER countr_example_trigger
    AFTER INSERT OR UPDATE ON example.countries_table
    FOR EACH ROW
    EXECUTE PROCEDURE example.generic_type_function('country_name');

```

With this setup, you'll automatically get a function that will return the value you want. The method is also immutable so the results will cache, so the internal query will only ever run once.
