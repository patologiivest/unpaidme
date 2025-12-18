# Masterdata Schema

The purpose of this schema is host tables, which contain data that can be considered configuration-/metadata,
which can be subject to changes. In database admin vernacular this is often referred to as _master-data_.
An example is a table containing all `requisitioners`, who are sending their specimens to your lab.

## Accounting Profiles 

Many laboratories need to perform analysis w.r.t. to accounting, e.g. for getting reimbursements etc.
To this end, there is the enum-table `accounting_profiles`, which contains different accounting categories.
A common use case is that different specimen types fall into a specific reimbursement category. 
In such case, the `level` column may be used to impose an ordinal ordering upon a subset of the accounting categories.
ANother use case is to distinguish between requisitioners, who are refunded by a public healthcase system and those 
who are privately funded.


```sql
{{#include ../../schema/migrations/0200_master.up.sql:4:10}}

```

## Actors and Roles

When analyzing a process, the _human "resources"_ generally play an important role.
We are calling, everyone that is involved in (manually) executing an activity or triggering an event, an _actor_[^actor].
Thus, there is a table of all `actors` and table capturing what `roles` these actors had at different points in time.

[^actor]: The may be also non-human actors.


![ERD diagram showing three tables](./images/png/2_2_role_assigs.png)

```sql
{{#include ../../schema/migrations/0200_master.up.sql:13:35}}
```


## Requisitioners and Organizations

Requisitioners are those sending in specimen to the laboratory. 
Often, there are multiple requisitioners that are working at the same organization and the organization may be comprised of different units. 
This is captured by the `requisitioners` and `organizations` tables.

![ERD diagram showing two tables](./images/png/2_2_req_orgas.png)

```sql
{{#include ../../schema/migrations/0200_master.up.sql:39:62}}
```


## Workstations 

Events may be associated with a _workstation_, i.e. where they have taken place.
This could be a grossing bench, a sectioning station or simply a dekstop computer.
The workstation can be linked to a lab location.

![ERD diagram showing two tables](./images/png/2_2_workstations.png)

```sql
{{#include ../../schema/migrations/0200_master.up.sql:66:77}}
```

## Codes, Specimen Types and Analysis Catalogue 

_Coding_ is a central activity in medical disciplines.
It resembles _modelling_ within computer science / software engineering.
The idea is to create common semantic understanding of similar concepts.
There are classification schemes that describes different types of diseases (e.g. [ICD-11](https://icd.who.int/en/)),
biological measurements (e.g. [LOINC](https://loinc.org/)), or ontologies that try to capture the majority of all clinical knowledge (e.g. [SNOMED-CT](https://browser.ihtsdotools.org/)). 
With coding schemes, semantic interopability becomes tangible as one 
now can make sure that everyone interprets the same information item in the same way.

However, the main issue with the existing coding schemes is that 
1. there are many of them, 
2. they may be way to comprehensive (too cumbersome) to work with,
3. they may lake necessary concepts, and/or
4. they tend to change regularly.

In UNPAIDME, we are trying to have a pragmatic approach towards these coding systems:
Concretely, we remain mostly agnostic w.r.t. the ontological dimension but we keep the idea 
of **unique identification**. To account for multiple coding systems, we allow to express 
_semantic mappings_ between concepts. The intepretation of these mappings (i.e. "parent/child", "equivalence", 
"replacement") is up to the user.


There is a central `code` table, which contains _codes_ in a coding _scheme_. 
The combination of a code and a scheme must be globally unique but the same code may appear in 
multiple schemes. If two codes shall represent "the same" ontological concept, one may define 
an entry in `code_mapping` and set the `mapping_type` accordingly (e.g. "synonym", "identity", etc.).
Codes have a technical _validity_, may be hierarchical organized, and can be related by mappings.
Each code and mapping also has a technical _validity_ (`valid_from`/`valid_until`) to cacount for changes in coding systems.
Code may express a hierarchy (taxonomy) by using the `parent_code`.


The codes are further used to define a catalogue of 
- known specimen types (identified by a pair of codes identifying the anatomical location and the clinical procedure to extract it),
- known staining methods (used on a slide),
- known fixation methods (used within a specimen container),
- known analysis methods (i.e. which are not considered stains -> not related to a tissue slide).

![ERD diagram showing tables and relationships around codes](./images/png/2_2_coding_types.png)

```sql
{{#include ../../schema/migrations/0200_master.up.sql:81:175}}
```

### Implementation Guidelines 

One may ask, whether it is necessary to find a suitable ontology to host one's specimen types, staining methods, and 
analysis types before he or she may be able to use this database schema? 
The answer is of course: No! Even though, it is encouraged to have reliable coding systems, a pragmatic approach 
is to define a list/catalogue of specimen types, stainining methods, etc., which is used in the concrete laboratory.
This catalogue then receives a non-global name, e.g. "`STAINING_METHODS`".
To illustrate this, we have included an example catalogue of common staining methods and also the official catalogue 
of specimen types for which there exist a refund category in the national reimbursement scheme.

### Specimen Type Profiles


```sql
{{#include ../../schema/migrations/0200_master.up.sql:178:199}}
```
