# Use Cases 

This section discusses some common use cases, which are enabled by applying the UNPAIDME data format.


## "Live View"


"Live View" is the working product title of a dashboard application, which has been implemented at the 
department of pathology at Haukeland university hospital. 
It has shown to offer several benefits w.r.t. reporting, observability and worker satisfaction. 

In principle, this use case is simply a _live_ overview of the daily production, which is implemented as a view definition.


## Production View

This is the historic counterpart to the daily "live view":
It shows the historic record over the production numbers of the past.
Since this may require a lot of event data to be processed, it is advisable to implement it as a _materialized view_.


## Arrears View 


In pathology laboratories it is common that not all incoming cases can be answered within the same day.
Hence, there is a possibility to arrears to accumulate.
For the lab management it is impoortant to keep an overview of how many cases are currently waiting within the lab.


## Specimen Type Analysis

In order to model and simulate the behaviour of a pathology laboratory, the specimen types play a fundamental role
in creating an accurate model since they are the primary source of variability.
Every modeling effort should therefore start by creating a good catalog of specimen types (see `master.specimen_types`).
Once, this catalog has been established and cases are linked with this specimen type catalog one may begin 
to analyze the existing specimen types. 
