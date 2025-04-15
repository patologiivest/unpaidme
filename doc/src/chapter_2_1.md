# Configuration Schema

The purpose of this schema is to store information that should be _customizable_ but is expected to change very **seldom**.
Most of the table in this schema represent _enumeration types_, i.e. mathematically a pre-defined set of _valid_ values and in most programming languages represented by a descriptive name and implemented by some numeric constant.
Therefore most of the tables in this schema have the exact same structure, comprising two columns:
- one numerical (e.g. `int4`) `id` column,
- one textual `name` column, and
- respective primary and unique key constraints.

We are providing sensible default values for each table/enum but feel free to configure your own concepts
such that they capture your laboratory in the most accurate way possible.
The following tables may require your attention:
- [`case_priority`](#case-priority)
- [`lab_locations`](#lab-locations)
- [`requisition_type`](#requisition-type)

Under certain circumstances, also
- [`actor_roles`](#actor-roles)
- [`block_types`](#block-types),
- [`slide_types`](#slide-types), as well as 
- [`event_names`](#event-names)

might need to be adjusted to your laboratory workflow.

The tables `patho_division`, `token_types`, and `event_types` should almost never be touched as these contain 
concepts that are assumed universal and equal among different laboratories!

## Actor Roles

Typical roles of actors in the labortory, a typical set-up might be:

```rust
enum ActorRole {
    PATHOLOGIST = 0,
    RESIDENT = 1,
    LAB_TECHNICIAN = 2,
    SECRETARIAN = 3
}
```

```sql
CREATE TABLE config.actor_roles (
    id int4 NOT NULL,
    "name" text NOT NULL,
    CONSTRAINT actor_roles_pkey PRIMARY KEY (id),
    CONSTRAINT actor_roles_uniq UNIQUE ("name")
);
```

## Block Types 

Used to distinguish between the differnt _types_ of blocks, e.g. normal size, large blocks, EPON blocks etc.
One may alternatively, distinguish between different colors of blocks, which may be used to denote
priorities or similar in the lab visually.

```rust
enum BlockType {
    NORMAL = 0,
    LARGE = 1,
    EPON = 2,
    EXTERNAL = 3,
    CELL = 4,
}
```

```sql
CREATE TABLEconfig.block_types (
    id int4 NOT NULL,
    "name" text NOT NULL,
    CONSTRAINT block_types_pkey PRIMARY KEY (id),
    CONSTRAINT block_types_uniq UNIQUE ("name")
);
```

## Case Priority

The different priority levels of a case that may affect the way how it is processed further down the line.

> **Attention:** The priority levels may differ between labs and this might be one of the few places in 
> the `config` schema where you acutally may provide custom values.

```rust
enum CasePriority {
    REGULAR = 1,
    PRIORITIZED = 2, 
    // ...adjust to your lab's workflow
}
```
```sql
CREATE TABLEconfig.case_priority (
    id int4 NOT NULL,
    "name" text NOT NULL,
    CONSTRAINT case_priority_pkey PRIMARY KEY (id),
    CONSTRAINT case_priority_uniq UNIQUE ("name")
);
```

## Event Types 

Different event types are important for process mining, where on must distinguish events (instant)
and activities (and whether they are starting, stopping etc.).

```rust
enum EventType {
    EVENT = 0,
    ACTIVITY_START = 1,
    ACTIVITY_FINISH = 2,
    ACTIVITY_PAUSE = 3,
    ACTIVITY_RESUME = 4,
    ACTIVITY_FAILED = 5,
}
```

```sql
CREATE TABLEconfig.event_types (
	id int4 NOT NULL,
	"name" text NOT NULL,
	CONSTRAINT event_types_pkey PRIMARY KEY (id)
);
```

## Event Names

The names of the various activities and events within the pathology workflow.
In this repository, we provide a pre-designed list of activities/events that we found 
working our use case. However, feel free to adjust these activites to your workflow and lab.

Each event "_name_" has a numeric `id` and a textual description (`name`), just as the other enum-type tables 
in this schema. Additionally, there is a column `default_event_type` referencing the `EventType` table, 
which indicates whether the event name describes a proper event (value = `0`) or an actvity (value = `1`). 

The complete list of the event names is found in [Section 3.1](./chapter_3_1.md)

```sql
CREATE TABLE config.event_names (
    id int4 NOT NULL,
    "name" text NOT NULL,
    default_event_type int4 NULL,
    CONSTRAINT event_names_name_key UNIQUE (name),
    CONSTRAINT event_names_pkey PRIMARY KEY (id),
    CONSTRAINT event_names_default_event_type_fkey FOREIGN KEY (default_event_type) REFERENCES config.event_types(id)

);

```

## Lab Locations

If you have multiple physical lab locations where the _same_ type of activities happen, or you want to
logically separate your histology and cytology laboratory, the `LabLocations` table may be used 
to distinguish between them. Thus, the content of this table is mostly up to you. 
Also, the use of this table is entirely optional.

> **Attention:** The laboratory locations are entirely up to your set-up and therefore 
> you have to adjust the contents of this table yourself (or simply ignore it).

```sql
CREATE TABLE config.lab_locations (
    id int4 NOT NULL,
    "name" text NOT NULL,
    CONSTRAINT lab_locations_pkey PRIMARY KEY (id),
    CONSTRAINT lab_locations_uniq UNIQUE (name)
);
```


## Patho Division

This enum type is used to distinguish between the different sub-disciplines in Pathology.
Generally, every case must be classified into exactly one such _division_.


```rust
enum PathoDivision {
    AUTOPSY = 0,
    HISTOLOGY = 1,
    CYTOLOGY = 2,
    MOLECULAR = 3,
    FORENSIC = 4,
}
```

```sql
CREATE TABLE config.patho_division (
    id int4 NOT NULL,
    "name" text NOT NULL,
    CONSTRAINT patho_division_pkey PRIMARY KEY (id),
    CONSTRAINT patho_division_uniq UNIQUE (name)
);
```

## Requisition Type

This enum type can be used to distinguish between different types of requistitions,
i.e. to distinguish between "in-house" (from inside the same hospital), GP, or 
external requisitions.

> **Attention:** The requisition types may differ between labs and this might be one of the few places in 
> the `config` schema where you acutally may provide custom values.

```rust 
enum RequisitionType {
    INTERNAL = 0,
    EXTERNAL = 1,
    // adjust to your preferences
}
```

```sql
CREATE TABLE config.requisition_type (
      id int4 NOT NULL,
      "name" text NOT NULL,
      CONSTRAINT requisition_type_pkey PRIMARY KEY (id),
      CONSTRAINT requisition_type_uniq UNIQUE ("name")
);
```

## Slide Type

This enum is used to distinguish between different slide types, e.g. normal an big slides[^bigslide].

[^bigslide]: The latter generally stem from cutting a big block.


```rust
enum SlideType {
    NORMAL = 0,
    BIG = 1,
}
```

```sql
CREATE TABLE config.slide_types (
    id int4 NOT NULL,
    "name" text NOT NULL,
    CONSTRAINT slide_types_pkey PRIMARY KEY (id),
    CONSTRAINT slide_types_uniq UNIQUE ("name")
);
```

## Token Type

Finally, the token type table is used to distinguish between the different types of "_tokens_" flowing
through the pathology laboratory. These tokens directly correspond to the main entities of the [domain model](./chapter_1_1.md) and hence the contents of this table should not be changed.


```rust
enum TokenType {
    CASE = 0,
    CONTAINER = 1,
    BLOCK = 2,
    SLIDE = 3,
    ANALYSIS = 4,
    REPORT = 5,
}
```

```sql
CREATE TABLE config.token_types (
    id int4 NOT NULL,
    "name" text NOT NULL,
    CONSTRAINT token_types_pkey PRIMARY KEY (id),
    CONSTRAINT token_types_uniq UNIQUE ("name")
);
```



