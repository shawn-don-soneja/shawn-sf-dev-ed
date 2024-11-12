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
    public static List<String> dataTypesToPredictOn = new List<String>{'GDP', 'Interest Rates', 'Unemployment', 'Inflation'};
    
    public static void predictOnData(){
        for(String item : dataTypesToPredictOn){
            System.debug(item);
        }
        
        Map<String, Schema.RecordTypeInfo> recordTypeInfoMap = Schema.getGlobalDescribe()
        .get('Financial_Data__c')
        .getDescribe()
        .getRecordTypeInfosByName();
        
        Id archivedRecordType = recordTypeInfoMap.get('Archived Prediction').getRecordTypeId();
        Id predictionRecordType = recordTypeInfoMap.get('Prediction').getRecordTypeId();
        System.debug('Record Types: ' + predictionRecordType + ' | ' + archivedRecordType);
        
        List<Financial_Data__c> gdpData = [SELECT Id, Value__c, Date__c FROM Financial_Data__c WHERE Type__c = 'GDP' AND RecordType.Name = 'Active' ORDER BY Date__c ASC];
        Date mostRecentgdpDate = gdpData[gdpData.size()-1].Date__c;
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        String api_key = API_Keys__mdt.getInstance('AWS_Prediction_Service').Key__c;
        System.debug('key: ' + api_key);
        request.setEndpoint('callout:AWS_Prediction_Service');
        request.setMethod('POST');
        request.setHeader('x-api-key',api_key);
        request.setHeader('Content-Type', 'application/json');
        
        String payload = preparePayload(gdpData);
        System.debug('Payload: ' + payload);
        
        request.setBody(payload);
                     
		HttpResponse response = http.send(request);
        System.debug('response' + response);
        
        if (response.getStatusCode() == 200) {
            AutomatedProcessLog__c resultLog = new AutomatedProcessLog__c(Status__c='Success',Log__c=response.getBody());
            //String trimmedBody = response.getBody().length() > 255 ? response.getBody().substring(0, 255) : response.getBody();
            //resultLog.Log_Short__c = trimmedBody;
            insert resultLog;
            
            //Successfully received a response
            System.debug('response' + response);
            System.debug('response BODY' + response.getBody());
            
            //Parse out needed data
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            List<Object> predictions = (List<Object>) responseMap.get('predictions'); // PREDICTIONS
            List<Object> slope = (List<Object>) responseMap.get('slope'); //SLOPE
            
            Decimal exactSlope = (Decimal) slope[0];
            System.debug('Slope: ' + exactSlope);
            
            System.debug('Predictions, Length: ' + predictions.size());
            
            //handle new predictions, by preparing them as a list
            List<Financial_Data__c> financialDataToInsert = new List<Financial_Data__c>();
            for(Object prediction : predictions){
                System.debug('Value: ' + prediction);
                List<Object> predictionValueParsed = (List<Object>) prediction;
                System.debug('Exact Value: ' + predictionValueParsed[0]);
                Decimal formattedValue = (Decimal) predictionValueParsed[0];
                mostRecentgdpDate = mostRecentgdpDate.addMonths(3);
                financialDataToInsert.add(new Financial_Data__c(Value__c = formattedValue.round(), Type__c = 'GDP', Date__c = mostRecentgdpDate, RecordTypeId=predictionRecordType)); // need to assign correct date...
                // date will be next 'increment' after most recent data...
            }
            
            System.debug('Data to Insert: ' + financialDataToInsert);

            //archive all existing predictions
            List<Financial_Data__c> dataToArchive = [SELECT Id, Value__c FROM Financial_Data__c WHERE RecordType.Name = 'Prediction'];
            for(Financial_Data__c record : dataToArchive){
                record.RecordTypeId = archivedRecordType;
                financialDataToInsert.add(record);
            }

            upsert financialDataToInsert;            
            
            //for each prediction, create a new record, with the appropriate date value (3 mo increment) and record type (prediction)
            //also set old predictions to record type of 'archived'
            
            //for GDP, increment all predictions by 3 months (quarterly)
            //for all others, increment predictions by 1 month
            
            
            System.debug(archivedRecordType);
           
        } else {
            // Handle non-200 response codes
            System.debug('Error: ' + response.getStatusCode() + ' - ' + response.getStatus());
        }
        
        

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

/*

this code worked on 10/31

Http http = new Http();
HttpRequest request = new HttpRequest();
String api_key = API_Keys__mdt.getInstance('AWS_Prediction_Service').Key__c;
System.debug('key: ' + api_key);
request.setEndpoint('callout:AWS_Prediction_Service');
request.setMethod('POST');
request.setHeader('x-api-key',api_key);
request.setHeader('Content-Type', 'application/json');
// Define the JSON structure directly
String jsonBody = '{"data": {"x": [[1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12], [13], [14], [15], [16], [17], [18], [19], [20], [21], [22], [23], [24], [25], [26], [27], [28], [29], [30], [31], [32], [33], [34], [35], [36], [37], [38], [39], [40], [41], [42], [43], [44], [45], [46], [47], [48], [49], [50], [51], [52], [53], [54], [55], [56], [57], [58], [59], [60], [61], [62], [63], [64], [65], [66], [67], [68], [69], [70], [71], [72], [73], [74], [75], [76], [77], [78], [79], [80], [81], [82], [83], [84], [85], [86], [87], [88], [89], [90], [91], [92], [93], [94], [95], [96], [97], [98], [99], [100]], "y": [[0.728], [0.911], [0.245], [0.767], [0.543], [0.678], [0.456], [0.234], [0.654], [0.321], [0.789], [0.567], [0.345], [0.890], [0.456], [0.123], [0.801], [1.002], [0.269], [0.843], [0.597], [0.746], [0.502], [0.257], [0.719], [0.353], [0.868], [0.624], [0.380], [0.979], [0.502], [0.135], [0.728], [0.911], [0.245], [0.767], [0.543], [0.678], [0.456], [0.234], [0.654], [0.321], [0.789], [0.567], [0.345], [0.890], [0.456], [0.123], [0.801], [1.002], [0.269], [0.843], [0.597], [0.746], [0.502], [0.257], [0.719], [0.353], [0.868], [0.624], [0.380], [0.979], [0.502], [0.135], [0.728], [0.911], [0.245], [0.767], [0.543], [0.678], [0.456], [0.234], [0.654], [0.321], [0.789], [0.567], [0.345], [0.890], [0.456], [0.123], [0.801], [1.002], [0.269], [0.843], [0.597], [0.746], [0.502], [0.257], [0.719], [0.353], [0.868], [0.624], [0.380], [0.979], [0.502], [0.135], [0.380], [0.979], [0.502], [0.135]]}}';

// Set JSON body
request.setBody(jsonBody);
System.debug('request' + request);
HttpResponse response = http.send(request);
System.debug('response' + response);

*/