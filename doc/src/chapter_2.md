# Database Implementation

The data model is implemented in the form of a database schema.
The schema is provided as `CREATE TABLE`-statements using the PostgreSQL dialect.

## Structure

The database structure is divided into three main schemas:

- `config`
- `master`
- `trans`

The `config` schema contains metadata, which "almost never" changes.
Usually, the contents of this schema are modified upon the initial installation and not any more afterwards.
The `master` schema contains any other kind of metadata, which may change in between.
This can for instance be the catalog of classified specimen types etc.
The `trans` schema contains all the _transactional_ data.
Moreover, there is a historical variant of the transactional schema `hist`
and users of UNPAIDME may create arbitrary (materialized) views in the `reports` schema depending on their use cases.





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
