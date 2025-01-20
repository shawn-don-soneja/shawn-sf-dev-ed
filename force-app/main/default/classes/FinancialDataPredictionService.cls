public class FinancialDataPredictionService {
	//to be invoked by scheduler
	
	/*
	scheduler calls class

	query all financial data, separate it into different types for callout

	callout and process response for each callout
		if success
			if predictions.length > 1 and slope != null 
			mark all existing predictions as 'archived'
			store new records as predictions
			store slope, as financial_data__c, record type = 'prediction'

		if fail
			don't take any action
	*/
    
    /*
	public static List<String> dataTypesToPredictOn = new List<String>{'GDP', 'Interest Rates', 'Unemployment', 'Inflation'};
    public enum dataTypesToPredictOn {
        GDP,
        IN_PROGRESS,
        COMPLETED,
        CLOSED
    }
	*/
    
    public static void predictOnData(){
        //Grab Record Type Info
        Map<String, Schema.RecordTypeInfo> recordTypeInfoMap = Schema.getGlobalDescribe()
        .get('Financial_Data__c')
        .getDescribe()
        .getRecordTypeInfosByName();

        Id archivedRecordType = recordTypeInfoMap.get('Archived Prediction').getRecordTypeId();
        Id predictionRecordType = recordTypeInfoMap.get('Prediction').getRecordTypeId();
        Id trendRecordType = recordTypeInfoMap.get('Trend').getRecordTypeId();
        Id archivedTrendRecordType = recordTypeInfoMap.get('Archived Trend').getRecordTypeId();
        
        System.debug('Record Types: ' + predictionRecordType + ' | ' + archivedRecordType);
		
        //Prepare active (actual) metrics, to be predicted on
        List<Financial_Data__c> dataToUpsert = new List<Financial_Data__c>();
        List<AutomatedProcessLog__c> loggersToUpsert = new List<AutomatedProcessLog__c>();
        
        List<Financial_Data__c> gdpData = new List<Financial_Data__c>();
		List<Financial_Data__c> unemploymentData = new List<Financial_Data__c>();
        List<Financial_Data__c> interestRateData = new List<Financial_Data__c>();
        List<Financial_Data__c> cpiData = new List<Financial_Data__c>();

		List<Financial_Data__c> requestData = [SELECT Id, Value__c, Date__c, Type__c, CreatedDate FROM Financial_Data__c WHERE RecordType.Name = 'Active' ORDER BY Date__c ASC];
        for (Financial_Data__c record : requestData){
        	if(record.Type__c == 'GDP') gdpData.add(record);
			else if(record.Type__c == 'Unemployment') unemploymentData.add(record);
            else if(record.Type__c == 'Interest Rate') interestRateData.add(record);
            else if(record.Type__c == 'CPI') cpiData.add(record);
        }
        
        //Grab legacy predictions, so we can archive them (if we recieved new predictions for that data type)
        List<Financial_Data__c> gdpData_existingPredictions = new List<Financial_Data__c>();
		List<Financial_Data__c> unemploymentData_existingPredictions = new List<Financial_Data__c>();
        List<Financial_Data__c> interestRateData_existingPredictions = new List<Financial_Data__c>();
        List<Financial_Data__c> cpiData_existingPredictions = new List<Financial_Data__c>();
        
        //Same for trend predictions -- needs to be archived, if that prediction type is being updated
        List<Financial_Data__c> gdpData_existingTrend = new List<Financial_Data__c>();
		List<Financial_Data__c> unemploymentData_existingTrend = new List<Financial_Data__c>();
        List<Financial_Data__c> interestRateData_existingTrend = new List<Financial_Data__c>();
        List<Financial_Data__c> cpiData_existingTrend = new List<Financial_Data__c>();
        
        List<Financial_Data__c> existingPredictionData = [SELECT Id, Value__c, Date__c, Type__c, CreatedDate, RecordType.Name FROM Financial_Data__c WHERE RecordType.Name = 'Prediction' OR RecordType.Name = 'Trend' ORDER BY Date__c ASC];
        for (Financial_Data__c record : existingPredictionData){
            if(record.RecordType.Name == 'Trend'){
                if(record.Type__c == 'GDP') gdpData_existingTrend.add(record);
                else if(record.Type__c == 'Unemployment') unemploymentData_existingTrend.add(record);
                else if(record.Type__c == 'Interest Rate') interestRateData_existingTrend.add(record);
                else if(record.Type__c == 'CPI') cpiData_existingTrend.add(record);
            }else if(record.RecordType.Name == 'Prediction'){
                if(record.Type__c == 'GDP') gdpData_existingPredictions.add(record);
                else if(record.Type__c == 'Unemployment') unemploymentData_existingPredictions.add(record);
                else if(record.Type__c == 'Interest Rate') interestRateData_existingPredictions.add(record);
                else if(record.Type__c == 'CPI') cpiData_existingPredictions.add(record);
            }
        }

		Boolean predictOnGDP = false;
        Boolean predictOnUnemployment = false;
        Boolean predictOnInterestRates = false;
        Boolean predictOnCpi = false; // <--- if our active data has changed (latest active record has created date >= latest prediction record), then set to true
        
        //check if predictions are needed
        //if latest ACTUAL record was created after latest PREDICTION record
        if(gdpData[gdpData.size() - 1].CreatedDate > gdpData_existingPredictions[gdpData_existingPredictions.size() - 1].CreatedDate){
            predictOnGDP = true;
        }
        if(unemploymentData[unemploymentData.size() - 1].CreatedDate > unemploymentData_existingPredictions[unemploymentData_existingPredictions.size() - 1].CreatedDate){
            predictOnUnemployment = true;
        }
        if(interestRateData[interestRateData.size() - 1].CreatedDate > interestRateData_existingPredictions[interestRateData_existingPredictions.size() - 1].CreatedDate){
            predictOnInterestRates = true;
        }
        if(cpiData[cpiData.size() - 1].CreatedDate > cpiData_existingPredictions[cpiData_existingPredictions.size() - 1].CreatedDate){
            predictOnCpi = true;
        }
        
        System.debug('Predict?');
        System.debug('GDP: ' + predictOnGDP);
        System.debug('Unemployment: ' + predictOnUnemployment);
        System.debug('Interest Rates: ' + predictOnInterestRates);
        System.debug('CPI: ' + predictOnCpi);
        
        AutomatedProcessLog__c toPredictLog = new AutomatedProcessLog__c(Status__c='Predict Today?',Log__c='__');
        toPredictLog.Log__c += ('GDP: ' + predictOnGDP);
        toPredictLog.Log__c += ('| Unemployment: ' + predictOnUnemployment);
        toPredictLog.Log__c += ('| Interest Rates:' + predictOnInterestRates);
        toPredictLog.Log__c += ('| CPI: ' + predictOnCpi);

        loggersToUpsert.add(toPredictLog);
        
        AutomatedProcessLog__c processingLog = new AutomatedProcessLog__c(Status__c='Processing Status',Log__c='==');
        
        try{
            
            if( predictOnGDP ){
                Date mostRecentDate;
                if(requestData.size() > 0){
                    mostRecentDate = requestData[requestData.size() - 1].Date__c; //we need this, so we can write back PREDICTIONS with the appropriate future dates
                }else{
                    mostRecentDate = Date.newInstance(2024, 11, 11); // November 11, 2024
    
                }
                HttpResponse response = sendRequest(gdpData); // <--- initiates request, formats payload
                List<Financial_Data__c> responseData = processResponse(response, 'GDP', mostRecentDate, archivedRecordType, predictionRecordType, trendRecordType); // <--- receives response, returns objects to insert (log + financial data);
                dataToUpsert.addAll(responseData);
                
                //if there are new predictions, then archive the old ones for this data type
                if(responseData.size() > 0){
                    processingLog.Log__c += '__GDP Data Received__';
                    
                    //archive all existing predictions
                    for(Financial_Data__c record : gdpData_existingPredictions){
                        record.RecordTypeId = archivedRecordType;
                        dataToUpsert.add(record);
                    }
                    
                    //archive all existing trends
                    for(Financial_Data__c record : gdpData_existingTrend){
                        record.RecordTypeId = archivedTrendRecordType;
                        dataToUpsert.add(record);
                    }  
                }else{
                    processingLog.Log__c += '__GDP NO DATA Received__';
                }
            }

                
            if ( predictOnUnemployment ){
               	Date mostRecentDate;
                if(requestData.size() > 0){
                    mostRecentDate = requestData[requestData.size() - 1].Date__c; //we need this, so we can write back PREDICTIONS with the appropriate future dates
                }else{
                    mostRecentDate = Date.newInstance(2024, 11, 11); // November 11, 2024
    
                }
                HttpResponse response = sendRequest(unemploymentData); // <--- initiates request, formats payload
                List<Financial_Data__c> responseData = processResponse(response, 'Unemployment', mostRecentDate, archivedRecordType, predictionRecordType, trendRecordType); // <--- receives response, returns objects to insert (log + financial data);
                dataToUpsert.addAll(responseData);
                
                //if there are new predictions, then archive the old ones for this data type
                if(responseData.size() > 0){
                    processingLog.Log__c += '__Unemployment Data Received__';
                    
                    //archive all existing predictions
                    for(Financial_Data__c record : unemploymentData_existingPredictions){
                        record.RecordTypeId = archivedRecordType;
                        dataToUpsert.add(record);
                    }  
                    
                    //archive all existing trends
                    for(Financial_Data__c record : unemploymentData_existingTrend){
                        record.RecordTypeId = archivedTrendRecordType;
                        dataToUpsert.add(record);
                    }  
                }else{
                    processingLog.Log__c += '__Unemployment NO DATA Received__';
                }
            }
                
                
            if ( predictOnInterestRates ){
                Date mostRecentDate;
                if(requestData.size() > 0){
                    mostRecentDate = requestData[requestData.size() - 1].Date__c; //we need this, so we can write back PREDICTIONS with the appropriate future dates
                }else{
                    mostRecentDate = Date.newInstance(2024, 11, 11); // November 11, 2024
    
                }
                HttpResponse response = sendRequest(interestRateData); // <--- initiates request, formats payload
                List<Financial_Data__c> responseData = processResponse(response, 'Interest Rate', mostRecentDate, archivedRecordType, predictionRecordType, trendRecordType); // <--- receives response, returns objects to insert (log + financial data);
                dataToUpsert.addAll(responseData);
                
                //if there are new predictions, then archive the old ones for this data type
                if(responseData.size() > 0){
                    processingLog.Log__c += '__Interest Rate Data Received__';
                    
                    //archive all existing predictions
                    for(Financial_Data__c record : interestRateData_existingPredictions){
                        record.RecordTypeId = archivedRecordType;
                        dataToUpsert.add(record);
                    }
                    
                    //archive all existing trends
                    for(Financial_Data__c record : interestRateData_existingTrend){
                        record.RecordTypeId = archivedTrendRecordType;
                        dataToUpsert.add(record);
                    }  
                }else{
                    processingLog.Log__c += '__Interest Rate NO DATA Received__';

                }
            }
                
            if ( predictOnCpi ){
                Date mostRecentDate;
                if(requestData.size() > 0){
                    mostRecentDate = requestData[requestData.size() - 1].Date__c; //we need this, so we can write back PREDICTIONS with the appropriate future dates
                }else{
                    mostRecentDate = Date.newInstance(2024, 11, 11); // November 11, 2024
    
                }
                HttpResponse response = sendRequest(cpiData); // <--- initiates request, formats payload
                List<Financial_Data__c> responseData = processResponse(response, 'CPI', mostRecentDate, archivedRecordType, predictionRecordType, trendRecordType); // <--- receives response, returns objects to insert (log + financial data);
                dataToUpsert.addAll(responseData);
                
                //if there are new predictions, then archive the old ones for this data type
                if(responseData.size() > 0){
                    processingLog.Log__c += '__CPI Data Received__';
                    
                    //archive all existing predictions
                    for(Financial_Data__c record : cpiData_existingPredictions){
                        record.RecordTypeId = archivedRecordType;
                        dataToUpsert.add(record);
                    }          
                    
                    //archive all existing trends
                    for(Financial_Data__c record : cpiData_existingTrend){
                        record.RecordTypeId = archivedTrendRecordType;
                        dataToUpsert.add(record);
                    }  
                    
                }else{
                    processingLog.Log__c += '__CPI NO Data Received__';
                }
            }
            
            loggersToUpsert.add(processingLog);
              
            System.debug('Total Data To Upsert: ' + dataToUpsert.size());
            System.debug('dataToUpsert: ' + dataToUpsert);
            System.debug('Total Loggers To Upsert: ' + loggersToUpsert.size());
            System.debug('loggersToUpsert: ' + loggersToUpsert);
            upsert dataToUpsert;
            insert loggersToUpsert;
                
        }catch(Exception e){
                AutomatedProcessLog__c logger = new AutomatedProcessLog__c(Status__c='Error', Log__c = e.getMessage());
            	insert logger;
            	System.debug('Error: ' + e.getMessage());
        }
    }

    private static HttpResponse sendRequest(List<Financial_Data__c> requestData){
        //prepare request
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        String api_key = API_Keys__mdt.getInstance('AWS_Prediction_Service').Key__c;
        //System.debug('key: ' + api_key);
        request.setEndpoint('callout:AWS_Prediction_Service');
        request.setMethod('POST');
        request.setHeader('x-api-key',api_key);
        request.setHeader('Content-Type', 'application/json');
        
        //preparePayload()
        String payload = preparePayload(requestData);
        System.debug('Payload: ' + payload);
        
        //initiate request
        request.setBody(payload);
                     
		HttpResponse response = http.send(request);
        System.debug('response' + response);
        return response;
    }
    
    private static List<Financial_Data__c> processResponse(HttpResponse response, String dataType, Date mostRecentDate, Id archivedRecordTypeId, Id predictionRecordTypeId, Id trendRecordTypeId){

        //handle new predictions, by preparing them as a list
        List<Financial_Data__c> financialDataToReturn = new List<Financial_Data__c>();
		
        if (response.getStatusCode() == 200) {
            AutomatedProcessLog__c resultLog = new AutomatedProcessLog__c(Status__c='Success',Log__c=response.getBody());
            //insert resultLog;
            
            //Successfully received a response
            //System.debug('response' + response);
            //System.debug('response BODY' + response.getBody());
            
            //Parse out needed data
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            List<Object> predictions = (List<Object>) responseMap.get('predictions'); // PREDICTIONS
            List<Object> slope = (List<Object>) responseMap.get('slope'); //SLOPE
            
            Decimal exactSlope = (Decimal) slope[0];
            System.debug('Slope: ' + exactSlope);
            
            System.debug('Predictions, Length: ' + predictions.size());
            
            //create dates, 'x' values to all my predicted y values (returned predictions)
            for(Object prediction : predictions){
                //System.debug('Value: ' + prediction);
                List<Object> predictionValueParsed = (List<Object>) prediction;
                //System.debug('Exact Value: ' + predictionValueParsed[0]);
                Decimal formattedValue = (Decimal) predictionValueParsed[0];
                if(dataType == 'GDP'){
                    mostRecentDate = mostRecentDate.addMonths(3); //gdp data points are quarterly
                }else{
                    mostRecentDate = mostRecentDate.addMonths(1); //all other data points are monthly
                }
                financialDataToReturn.add(new Financial_Data__c(Value__c = formattedValue.setScale(3, RoundingMode.HALF_UP), Type__c = dataType, Date__c = mostRecentDate, RecordTypeId = predictionRecordTypeId));
            }
            
            Financial_Data__c trend = new Financial_Data__c(RecordTypeId = trendRecordTypeId, Value__c = exactSlope, Type__c = dataType);
            
            financialDataToReturn.add(trend);
            //System.debug('Data to Insert: ' + financialDataToReturn);

        } else {
            // Handle non-200 response codes
            System.debug('Error: ' + response.getStatusCode() + ' - ' + response.getStatus());
        }
        
        return financialDataToReturn;
    }

    public static String preparePayload(List<Financial_Data__c> dataForPayload){
                                              
        List<List<Object>> x_Array = new List<List<Object>>();
        List<List<Object>> y_Array = new List<List<Object>>();
        
        for(Integer x = 0; x < dataForPayload.size(); x++){
            x_Array.add(new List<Object>{x});
            y_Array.add(new List<Object>{dataForPayload[x].Value__c});
        }
        
        Map<String, Object> payload = new Map<String, Object>{
            'data' => new Map<String, List<List<Object>>>{
                'x' => x_Array,
                'y' => y_Array
             }
        };

        return JSON.serialize(payload);
    }
}