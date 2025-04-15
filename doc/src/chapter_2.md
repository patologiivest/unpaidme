# Database Implementation

The data model is implemented in the form of a database schema.
The schema is provided as `CREATE TABLE`-statements using the PostgreSQL dialect.


## Structure

The database structure is divided into three schemas:

- `config`
- `master`
- `trans`

The `config` schema contains metadata, which "almost never" changes.
Usually, the contents of this schema are modified upon the initial installation and not any more afterwards.
The `master` schema contains any other kind of metadata, which may change in between.
This can for instance be the catalog of classified specimen types etc.
Finally, the `trans` schema contains all the _transactional_ data.


## SQL Datatypes 

The main difference among database systems is their support and naming of column data types.
Possibly, the SQL schema definitions in this repository can (more or less) easily be converted to 
a different databse system dialect (such as T-SQL for Microsoft SQL server, Oracle SQL and others).
As the definition in this repository are based on PostgreSQL, it may be worthwile to quickly summarize 
data types that will be used:

- `int4` signed integer values that can be represented with four bytes (32 bits). It corresponds to the `integer` 
type in most programming languages, and will be used for ids (of entities where there are expected to be fewer of) and most numeric values.
- `int8`: signed integer values that can be represented with eight bytes (64 bits). It corresponds to the `long integer` type of most programming languages and it will be predominantly used for id's.
- `text`: PostgreSQL has a data type supporting UTF-8 strings of arbitrary length (The usage of the `varchar` type, which is capped by a max length, is discouraged in PostgreSQL since it is less efficient).
- `float8`: IEEE754 floating point values represented with 64 bits.
- `timestamptz`: Milliseconds since the UNIX epoch equipped with a time zone indicator.


## Design Decisions

- **Numeric IDs rather than UUID**: We decided to solely use 64bit signed integers to implement identifiers for all 
domain model entities. An alternative would be to use UUIDs, which most certainly implement throughly universally 
unique identifiers. However, we opted for `Int64` due to the following reasons:
    1. Most programming languages support this data type out of the box (i.e.
       it is part of the set of base types), `uuid` often requires a
    third-party library
    2. it is computationally more efficient, e.g. when joining data frames based on the values in a `Int64`-column.
    3. it is _easier on the eyes_, when starring at large tables containing a
       lot of entries and identifiers, looking at the hexadecimal
    representation of 128-bitstrings can steal your focus and also is confusing
    when presenting raw data to non-programmers
- **Timestamps always with time zone**: Even if all your lab locations are always within the same time zone and your 
database servers are correctly configured with correct local time zone, it is usally a good idea to add the time zone
information to all timestamp fields, and even better keep everyting in UTC/GMT. This has the tremendous advantage of not having to deal with summer/winter-time and also (especially in cloud-computing set-ups), you can never be sure what the local timezone of your database system is.
- **Reflection of metadata**: A substantial share of the tables in this proposed schemas can be considered _metadata_.
In many laboratory information systems, this data might be hard-wired into the program code and not necissarily explicitly represented in the database. Nevertheless, we explicitly opt for representing this information to allow for 
inspection, reflection, and possibly even self-configuration.
