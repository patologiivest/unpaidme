# UNiversal PAthology Interoperability Data Model for Events (UNPAIDME)

This repository seeks to provide the starting point in creating a common foundation
for a data model that represents events happening in a Pathology laboratory.

It contains the following

- _UML class diagrams_ depicting the domain model to grasp the high-level overview and to be included in technical documentation.
- _Database Schema Definitions_ written as SQL DDL statements to be used in the relational database of your choice, including
some sensibel defaults w.r.t. indices etc.


## Goals 

Eventually, the goal is to provide integrations into other Interoperability standards to smootly integrate this 
into any laboratory information system.

- Allowing the Read and Write the respective subset of [FHIR](https://www.hl7.org/fhir/): Thinking
in particular of `Observation`, `Report`, `Specimen`, `BodyStructure` `ImagingStudy`, and `ServiceRequest`, i.e.
the transactional meta-data part of the events.
- Importing and ex-porting to [XES](http://www.xes-standard.org/) at some point, which however is a bit unwieldly
since it is XML-based (= lots of overhead), and it therefore is row-based rather than column-based. The latter
being much more efficient for analytical data (= data is often being aggregated) and [Parquet](https://parquet.apache.org/)
actually comes out as a far more superior data format in this case.
- Seamless integration with the plethora of medical coding systems out there: [SNMOED-CT](https://www.snomed.org/), 
[NORPAT](https://www.ehelse.no/standardisering/standarder/norsk-patologikodeverk), [NLK](https://www.ehelse.no/kodeverk-og-terminologi/Laboratoriekodeverk), ...
