# Historical Schema

The historical schema is a _versioned_ variant of the transactional schema.
It contains basically the same tables as the `trans` schema with the difference that 
each table has an additional

- `valid_from` (timstamp from which this record become valid)
- `valid_until` (timestamp until which this record was valid)
- `modified_by` (the numerical `actor_id` who modified this record).

The usage of the `hist` schema is completely optional.
It may be used to implement versioning and retain records of outdated information.
The idea is that the `trans` schema should always contain the record that is valid **right now**.
If a record gets deleted, it may be moved to the `hist.{table}` variant of the original table. 


## Worklists 

The biggest difference between the `trans` and the `hist` schema is that `hist` does not contain the `events` table 
(The latter is historical by nature). Instead, the `hist` schema contains a worklist table, which records 
what `actor` whas responsible for what case in what interval and role (pathologist/resident etc.).


```sql
{{#include ../../schema/migrations/0400_hist.up.sql:worklist}}
```



