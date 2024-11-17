//FinancialDataManagerPredictionService.predictOnData();

List<Financial_Data__c> toMakeActive = [SELECT Id, CreatedDate, Type__c, RecordType.Name, Value__c, Date__c
FROM Financial_Data__c
WHERE CreatedDate < 2024-11-10T16:29:08.772-05:00 
ORDER BY CreatedDate DESC];

for(Financial_Data__c record : toMakeActive){
    record.RecordTypeId = '0125e000000aQviAAE';
}

update toMakeActive;