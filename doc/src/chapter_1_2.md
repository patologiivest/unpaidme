# Technical Implementation

Whenever one wants to envisage something like a _datamodel "standard"_, one must decide one must decide upon 
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
As the SQL dialect we have opted for [PostgreSQL](https://www.postgresql.org/), a popular multi-model
open-source databse management system (DBMS).
Hence, one may immediately apply the schema definition to a PostgreSQL deployment (in the cloud or on-premise) 
and has a running analytical pathology information system.
If one prefers another database management system, it should be sufficiently straightforward to "rewrite" the 
table definitions for that particular DBMS: The DDL statements follow standard ANSI SQL, the major difference 
will be in the data types.


The definitions come bundled with some Timescale-specific extensions, which allow for better performance when
there is a lot of event data.
Also, there is REST-API application written in Rust using the Tokio/Tower/Axum stack for demonstrating purposes. 
Feel free to use these components as you like or ignore them alltogeher.


## Additional Technologies 

### REST API

### Timescale

TimescaleDB is a PostgresSQL extension that adds timeseries functionality to PostgreSQL.
The extension itself is open-source software relases under the [Apache License](https://docs.tigerdata.com/about/latest/timescaledb-editions/).
However, there is also a commercial product TigerData built on top of it.

In Bergen, we made good experience with the extension, which helped to substantially speed up queries on the event tables.


## Customization

This repository is open-source, hence you can simply clone this git repository and make your changes to it.
The easiest way to customize the database structure is by adding your own migrations into the sequence.


