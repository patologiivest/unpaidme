# Introduction


The goal of this project is to create a (more or less) _universal_ data model for the domain of _pathology_.
The model is centred around the notion of _events_ and, thus, provides a foundation for _process mining_ across different laboratories.

## Problem Statement

As with many domains within healthcare, also pathology is marred by lacking interoperability.
Traditionally, interoperability among _laboratory information systems (LISs)_ was not a priority for neither suppliers or end users.
Hence, there is **no** commonly agreed-upon data model or exchange format that facilitates portability of data from one system to another. 

You may now think of initiatives like HL7 (most and foremost FHIR) or Dicom, which are promising/successful approaches
for achieving interoperability of health record data and clinical images respectively.
However, when it comes to _event data_ in general and _pathology event data_ in particular, there are no such standards.
Interestingly, due to legal regulations, most suppliers of LIS systems are obliged to record everything that a user 
does within the system in order to allow for revision and tracing (and by projection capture most of what happens in the 
lab as well).
But, there is common format in which these tracing/logging information must be recorded and stored. 
This data model is an attempt to create this missing format and data model in a bottom-up approach.


## How to use this repository?

The contents of this repository, i.e. database schemas, scripts and tools are freely available under the MIT license.
Feel free to use it for your own use cases and feel free to contribute back to this repository and it's proposed data models:
A standard is only truly useful if it is adopted by as many as possible.
By learning from one another and seeing how others have modelled the "same" ideas, 
there may be a chance to achieve something interoperable and useful!


