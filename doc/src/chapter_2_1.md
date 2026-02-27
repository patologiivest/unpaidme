# Configuration Schema

The purpose of this schema is to store information that is considered configuration/metadata.
It is intended to be _customizable_ but is expected to change very **seldom** (almost never) after set-up.
Most of the table in this schema represent _enumeration types_, i.e.  a pre-defined set of _valid_ values.
Most programming languages implement it as a mapping between a descriptive name and an internal numeric representation.

Therefore, most of the tables in this schema have the exact same structure, comprising two columns:
- a numerical (e.g. `int4`) `id` column, and
- a textual `name` column,

together with respective primary and unique key constraints.

We are providing sensible default values for each table/enum, but feel free to configure your own concepts
such that they capture the nature of _your_ laboratory.

In particular, the following tables _may_ require your attention:
- [`case_priority`](#case-priority)
- [`lab_locations`](#lab-locations)
- [`requisition_type`](#requisition-type)
- [`workflow_profiles`](#workflow-profiles)

Under certain circumstances, also
- [`actor_roles`](#actor-roles),
- [`block_types`](#block-types),
- [`slide_types`](#slide-types),
- [`event_names`](#event-names), as well as
- [`workstation_types`](#workstation-types) 

might need to be adjusted to your laboratory workflow.

The tables `patho_division`, `token_types`, and `event_types` should generally not be touched as these contain 
generic concepts that are assumed universal and equal among different laboratories!

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
We provide a pre-designed list of activities/events that we found to sufficient to model our laboratory workflow.
However, feel free to adjust these activites to your workflow and lab.

The events are defined in [0111_config_events.up.sql](../../schema/migrations/0111_config_events.up.sql)
and described in greater detail in [Section 3.1](./chapter_3_1.md).

In addition to the default `id` and `name` columns, there is a column `default_event_type` referencing the `EventType` table, 
which indicates whether the event name describes a proper event (value = `0`) or an actvity (value = `1`). 


```sql
{{#include ../../schema/migrations/0100_config.up.sql:33:42}}

```

## Lab Locations

If you have multiple physical lab locations where the _same_ type of activities happen, or you want to
logically separate your histology and cytology laboratory, the `LabLocations` table may be used 
to distinguish between them. Thus, the content of this table is mostly up to you. 
Also, the use of this table is entirely optional.

> **Attention:** The laboratory locations will depend on your personal use case and therefore 
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
i.e. to distinguish between "in-house" (from inside the same hospital), general practicioners (GPs), or 
external requisitions (e.g. private laboratories).

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

> **Attention:** The `workflow_profiles` may be different among laboratories and there need some adjustments. 

`workflow_profiles` allow an additional dimension to distinguish between different types of cases apart 
from the natural disctinction of pathology divisions.
For instance, you may want to distinguish between several types of _histology_ cases that require a completely different workflow.
There could be `regular` cases that undergo the normal stages of the histology process,
a `frozen_section` on the other-hand would be short-tracked directly to _sectioning_ via cyrotome with an immediate
preliminary microscopic analysis flowing into the regular process (with a lower priority then), and finally
a `consultation` may come from another laboratory which already produced slides such that the case can go directly
to microscopic analysis.
Since these three types of cases behave rather differently, it is reasonable to distinguish between them when creating reports.

Workflow profiless are meant to be used othogonal (depending on your reporting needs[^reporting_needs]), i.e.
you may define multiple classes of profiles.
One use case may to definedifferent "organ groups", i.e. specialization domains of pathologists (gynecology, dermatology,
neurology, etc.).

[^reporting_needs]: This will be discussed in a later chapter.

```rust
enum WorkflowProfiles {
    REGULAR = 0,
    FROZEN_SECTION = 1,
    CONSULTATION = 3,
    // add more profiles when needed
}
```

```sql
{{#include ../../schema/migrations/0100_config.up.sql:81:86}}
```

## Workstation Types

Finally, one may distinguish between different types of _workstations_:
Some activities in the process may require a specific workstation. 
Thus, workstations represent a _resource_ and there might be conflict around 
resources, which is an important aspect to take into account in a simulation model.

```rust
enum WorkstationType {
    DESKTOP_COMPUTER = 0,
    REGISTRATION_DESK = 1,
    GROSSING_STATION = 2,
    PROCESSING_MACHINE = 3,
    CYTOLOGY_PROCESSOR = 4,
    EMBEDDING_STATION = 5,
    MICROTOME = 6,
    STAINING_MACHINE = 7, 
    IHC_STAINING_MACHINE = 8,
    SCANNER = 9,
    CRYOTOME = 10,
    PCR_MACHINE = 11,
    AUTOMATIC_EMBEDDING_MACHINE = 12,
    SECTIONING_ROBOT = 13,
    // ...
}
```

```sql
{{#include ../../schema/migrations/0100_config.up.sql:89:95}}
```
