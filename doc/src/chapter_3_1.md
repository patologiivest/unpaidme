# Event Names

As mentioned earlier, this data model also comes with a proposal for the pathology process.
In the first place, there is a list of _names_ for events and activities.
Each name has a numeric id, which makes it more efficient to store references to the process
step in the event log. 
The numbering of this event names follows some soft-semantic rules, i.e. the decimal-ten position indicates
in what order this activity/event usually appears in the process.


|id|name|type|
|--:|----|------------------|
|0|specimenTaken|EVENT|
|10|requisitionReceived|EVENT|
|11|consultationReceived|EVENT|
|19|requisitionRetracted|EVENT|
|20|accessioning|ACTITVITY|
|26|consultationBlockRegistered|EVENT|
|27|consultationSlideRegistered|EVENT|
|30|grossing|ACTITVITY|
|31|specimenContainerArchived|EVENT|
|32|specimenContainerRetrieved|EVENT|
|33|grossingKidney|ACTITVITY|
|34|grossingIHC|ACTITVITY|
|35|blockPrinted|EVENT|
|39|dictationTranscription|ACTITVITY|
|40|processing|ACTITVITY|
|41|decalcination|ACTITVITY|
|42|processingPCR|ACTITVITY|
|43|flowCytometry|ACTITVITY|
|50|manualEmbedding|ACTITVITY|
|51|automaticEmbedding|ACTITVITY|
|59|Koordinering|ACTITVITY|
|60|manualSectioning|ACTITVITY|
|61|automaticSectioning|ACTITVITY|
|62|sectioningIHC|ACTITVITY|
|63|sectioningMolecular|ACTITVITY|
|64|sectioningKidney|ACTITVITY|
|65|sectioningNeurology|ACTITVITY|
|66|slidePrinted|EVENT|
|67|blockArchived|EVENT|
|68|blockRetrieved|EVENT|
|69|blockDestroyed|EVENT|
|70|automaticStaining|ACTITVITY|
|71|manualStaining|ACTITVITY|
|72|stainingIHC|ACTITVITY|
|73|molecularAnalysis|ACTITVITY|
|74|stainingKidney|ACTITVITY|
|75|stainingNeurology|ACTITVITY|
|80|caseAssigned|EVENT|
|81|caseReassgined|EVENT|
|82|caseCoResponsibleAssigned|EVENT|
|85|scanning|ACTITVITY|
|87|slideArchived|ACTITVITY|
|88|slideRetrieved|ACTITVITY|
|89|slideDestroyed|ACTITVITY|
|90|microscopicAnalysis|ACTITVITY|
|91|ihcRequested|EVENT|
|92|specialStainRequested|EVENT|
|93|additionalGrossingRequested|EVENT|
|94|molpatRequested|EVENT|
|95|electronMicroscopyRequested|EVENT|
|96|sendInForExternalConsultation|EVENT|
|97|reportSubmittedForReview|EVENT|
|98|preliminaryReportFinished|EVENT|
|99|finalReportFinished|EVENT|
|100|caseArchived|EVENT|
|101|caseReopened|EVENT|
|102|reportAugmented|EVENT|
|103|reportCorrected|EVENT|
|107|archivedSlideRetrievalRequested|EVENT|
|108|archivedBlockRetrievalRequested|EVENT|
|110|requisitionAnswered|EVENT|

