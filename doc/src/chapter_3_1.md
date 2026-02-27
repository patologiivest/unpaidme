# Event Names

As mentioned earlier, this data model also comes with a proposal for the pathology process.
In the first place, there is a list of _names_ for events and activities.
Each name has a numeric id, which makes it more efficient to store references to the process
step in the event log. 
The numbering of this event names follows some soft-semantic rules, i.e. the decimal-ten position indicates
in what order this activity/event usually appears in the process.


|id|name|type|
|--:|:----|------------------|
|   0 | specimenTaken                   |                  Evt|
|  10 | requisitionReceived             |                  Evt|
|  11 | consultationReceived            |                  Evt|
|  19 | requisitionRetracted            |                  Evt|
|  20 | accessioning                    |                  Act|
|  26 | consultationBlockRegistered     |                  Evt|
|  27 | consultationSlideRegistered     |                  Evt|
|  30 | grossing                        |                  Act|
|  31 | specimenContainerArchived       |                  Evt|
|  32 | specimenContainerRetrieved      |                  Evt|
|  35 | blockPrinted                    |                  Evt|
|  39 | dictationTranscription          |                  Act|
|  40 | processing                      |                  Act|
|  41 | decalcination                   |                  Act|
|  42 | processingPCR                   |                  Act|
|  43 | flowCytometry                   |                  Act|
|  50 | manualEmbedding                 |                  Act|
|  51 | automaticEmbedding              |                  Act|
|  59 | Koordinering                    |                  Act|
|  60 | manualSectioning                |                  Act|
|  61 | automaticSectioning             |                  Act|
|  66 | slidePrinted                    |                  Evt|
|  67 | blockArchived                   |                  Evt|
|  68 | blockRetrieved                  |                  Evt|
|  69 | blockDestroyed                  |                  Evt|
|  70 | automaticStaining               |                  Act|
|  71 | manualStaining                  |                  Act|
|  72 | stainingIHC                     |                  Act|
|  73 | molecularAnalysis               |                  Act|
|  80 | caseAssigned                    |                  Evt|
|  81 | caseReassgined                  |                  Evt|
|  82 | caseCoResponsibleAssigned       |                  Evt|
|  85 | scanning                        |                  Act|
|  87 | slideArchived                   |                  Act|
|  88 | slideRetrieved                  |                  Act|
|  89 | slideDestroyed                  |                  Act|
|  90 | microscopicAnalysis             |                  Act|
|  91 | additionalSlidesRequested       |                  Evt|
|  92 | additionalAnalysisRequested     |                  Evt|
|  93 | additionalGrossingRequested     |                  Evt|
|  94 | molpatRequested                 |                  Evt|
|  95 | electronMicroscopyRequested     |                  Evt|
|  96 | sendInForExternalConsultation   |                  Act|
|  97 | reportSubmittedForReview        |                  Evt|
|  98 | preliminaryReportFinished       |                  Evt|
|  99 | finalReportFinished             |                  Evt|
| 100 | caseArchived                    |                  Evt|
| 101 | caseReopened                    |                  Evt|
| 102 | reportAugmented                 |                  Evt|
| 103 | reportCorrected                 |                  Evt|
| 106 | archivedSlideRescanRequest      |                  Evt|
| 107 | archivedSlideRetrievalRequested |                  Evt|
| 108 | archivedBlockRetrievalRequested |                  Evt|
| 110 | requisitionAnswered             |                  Evt|


