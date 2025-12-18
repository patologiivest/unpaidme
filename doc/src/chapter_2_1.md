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
- [`workflow_profiles`](#workflow-profiles)

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
{{#include ../../schema/migrations/0100_config.up.sql:4:9}}
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
{{#include ../../schema/migrations/0100_config.up.sql:12:17}}
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
{{#include ../../schema/migrations/0100_config.up.sql:19:24}}
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
{{#include ../../schema/migrations/0100_config.up.sql:26:31}}
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
{{#include ../../schema/migrations/0100_config.up.sql:33:42}}

```

## Lab Locations

If you have multiple physical lab locations where the _same_ type of activities happen, or you want to
logically separate your histology and cytology laboratory, the `LabLocations` table may be used 
to distinguish between them. Thus, the content of this table is mostly up to you. 
Also, the use of this table is entirely optional.

> **Attention:** The laboratory locations are entirely up to your set-up and therefore 
> you have to adjust the contents of this table yourself (or simply ignore it).

```sql
{{#include ../../schema/migrations/0100_config.up.sql:45:50}}
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
{{#include ../../schema/migrations/0100_config.up.sql:52:57}}
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
{{#include ../../schema/migrations/0100_config.up.sql:59:64}}
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
{{#include ../../schema/migrations/0100_config.up.sql:66:71}}
```

## Token Type

The token type table is used to distinguish between the different types of "_tokens_" flowing
through the pathology laboratory. These tokens directly correspond to the main entities of the [domain model](./chapter_1_1.md) and hence the contents of this table should not be changed.


```rust
enum TokenType {
    CASE = 0,
    CONTAINER = 1,
    BLOCK = 2,
    SLIDE = 3,
    ANALYSIS = 4,
    REPORT = 5,
    OTHER = 6,
}
```

```sql
{{#include ../../schema/migrations/0100_config.up.sql:74:79}}
```

## Workflow Profiles 

The `workflow_profiles` table can be used to configure different types of workflows for cases.
A common example is the distinction between cases, where grossing is either performed by lab technicians (more generic and standardized procedures) 
or residents (more complex and adhoc procedures).
Another example is to distinguish between different "organ groups", i.e. specialization domains of pathologists (gynecology, dermatology,
neurology, etc.).

```sql
{{#include ../../schema/migrations/0100_config.up.sql:81:86}}
```

