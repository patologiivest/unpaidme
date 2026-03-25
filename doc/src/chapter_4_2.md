# Case and Artifact Status 

The UNPAIDME records "everything that happens" in the `trans.events` table.
This table records state changes on the most granular level and will naturally grow very big over time.
Thus, it is advisable to use something like TimescaleDB or similar (at least apply partitioning) 
in order to be able to query this table efficiently.
Still, querying the events table directly is bit tedious.
Common use cases, generally, involve the need to get a quick overview about 

- _What are the open cases?_
- _What cases have been waiting for the longest time? For how long?_
- _How many blocks are waiting to be sectionig_?
- _How many IHC slides have been ordered_?
- ...


In order to answer such questions quickly, a view showing the current state of every `case` and "artifact"
(`slide`, `block`, `analysis`) is needed.
Lucklily, this view can easily be computed from the `trans.events` table via aggregation.
We chose to implement them as `materialized views` to query to them frequently and efficiently. 
You may decide to set up a recurrent refresh using `pg_cron` or an external `cron` service.


## Cases 

```sql
{{#include ../../schema/migrations/0510_reports_lifecycle.up.sql:cases}}
```

## Artifacts
