# Technical Implementation

Whenever one wants to envisage something like a _data model "standard"_, one must decide one must decide upon 
a _level of abstraction_, which is used to specify it's contents. 
A standard generally seeks to keep the room for different interpretations (and thus misunderstandings) as small as 
possible.
Therefore, standards have to apply _formality_.
The strongest degree of formality is _software program code_ as it does not give any room for (mis-)interpretation 
and also becomes with the advantage of being executable.
The disadvantage is that one has to decide on a specific piece of technology, programming language etc.
Such a choice then narrows the usage possibilities of the standard, e.g. some may not be able to integrate 
that technology into their infrastructure, there may be skepticism towards the chosen technology, or there may 
be some licensing barriers. 
The UNPAIDME initiative strives to achieve a compromise between specificity and usefulness on the one hand but also
universality on the other hand.

We have chosen to define a formal data model in terms of _table definitions_ written in SQL DDL statements.
The tables are defined as a sequence of _migrations_, a common pattern for applying database modifications, which 
can be found in the `schema/migrations/` folder inside the repository:
The folder contains SQL files (`*.sql`) containing DDL (`CREATE TABLE`) and DML (`INSERT INTO` for configuration data)
instructions. 
The file name pattern `NNNN_{description}.[up|down].sql` encodes the order of execution (the `NNNN` prefix enabling
lexicographical order) and whether the file shall be run during set-up or tear-down (the latter should never done in 
production database).

```
../schema/migrations
├── 0100_config.down.sql                
├── 0100_config.up.sql                  (see chapter 2.1: Configuration Schema)
├── 0110_config_content.up.sql          (pre-made example configuration data)
├── 0111_config_events.up.sql           (pre-made event names, see chapter 3.1)
├── 01{...}.up.sql                      (put your configuration customizations here)
├── 0200_master.down.sql
├── 0200_master.up.sql                  (see chapter 2.2: Masterdata Schema)
├── 0210_master_content.up.sql
├── 02{...}.up.sql
├── 0300_trans.up.sql
├── 0310_trans_fkeys.up.sql
├── 0350_trans_timescale.sql
├── 0400_hist.up.sql
├── 0500_reports.up.sql
└── schema.up.sh

```

## PostgreSQL and other DBMS

As SQL dialects considered, we have opted for [PostgreSQL](https://www.postgresql.org/), a popular multi-model open-source database management system (DBMS).
One may immediately apply the schema definition to a PostgreSQL deployment (in the cloud or on-premise)  and has a running analytical pathology information system.
If one prefers another database management system, it should be sufficiently straightforward to "rewrite" the 
table definitions for that particular DBMS: The DDL statements follow standard ANSI SQL, the major difference 
will be in the data types.

Possibly, the SQL schema definitions in this repository can (more or less) easily be converted to 
a different database system dialect (such as T-SQL for Microsoft SQL server, Oracle SQL and others).
As the definition in this repository are based on PostgreSQL, it may be worthwhile to quickly summarize 
data types that will be used:

- `int4` signed integer values that can be represented with four bytes (32 bits). It corresponds to the `integer` 
type in most programming languages, and will be used for ids (of entities where there are expected to be fewer of) and most numeric values.
- `int8`: signed integer values that can be represented with eight bytes (64 bits). It corresponds to the `long integer` type of most programming languages and it will be predominantly used for id's.
- `text`: PostgreSQL has a data type supporting UTF-8 strings of arbitrary length (The usage of the `varchar` type, which is capped by a max length, is discouraged in PostgreSQL since it is less efficient).
- `float8`: IEEE754 floating point values represented with 64 bits.
- `timestamptz`: Milliseconds since the UNIX epoch equipped with a time zone indicator.

## TimescaleDB

The definitions come bundled with some Timescale-specific extensions, which allow for better performance when
there is "a lot of event data".

TimescaleDB is a PostgreSQL extension that adds _time series functionality_ to PostgreSQL.
The extension itself is open-source software released under the [Apache License](https://docs.tigerdata.com/about/latest/timescaledb-editions/).
There is also a commercial product TigerData built on top of it.

In Bergen, we made good experience with the extension, which helped to substantially speed up queries on the event tables.


## Customization

This repository is open-source, hence, you simply clone the git repository and make your changes to it.
The easiest way to customize the database structure is by adding custom migrations into the migration sequence found in `schema/migrations/`
The `9001_custom_migration_example.up.sql` provides an example how to write custom migrations.


## Applying the schema 

There are pre-made shell scripts that apply all the set-up/tear-down migrations sequentially:

Otherwise, you can always apply a migration manually (assuming `psql` from `libpq` is installed):

```bash
psql -q -f NNNN_migration_name.up.sql # -q is for non-verbose output
```




