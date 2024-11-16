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
        //prepare data
        Map<String, Schema.RecordTypeInfo> recordTypeInfoMap = Schema.getGlobalDescribe()
        .get('Financial_Data__c')
        .getDescribe()
        .getRecordTypeInfosByName();

        Id archivedRecordType = recordTypeInfoMap.get('Archived Prediction').getRecordTypeId();
        Id predictionRecordType = recordTypeInfoMap.get('Prediction').getRecordTypeId();
        System.debug('Record Types: ' + predictionRecordType + ' | ' + archivedRecordType);

        List<Financial_Data__c> dataToUpsert = new List<Financial_Data__c>();

        for(Integer i = 0; i < dataTypesToPredictOn.size(); i++){
            String dataType = dataTypesToPredictOn[i];
            //retrieve data
            List<Financial_Data__c> requestData = [SELECT Id, Value__c, Date__c FROM Financial_Data__c WHERE Type__c = :dataType AND RecordType.Name = 'Active' ORDER BY Date__c ASC];
            Date mostRecentDate;
            if(requestData.size() > 0){
                mostRecentDate = requestData[0].Date__c;
            }else{
                mostRecentDate = Date.newInstance(2024, 11, 11); // November 11, 2024

            }

            System.debug(dataType);
            //prepares payload and sends request
            HttpResponse response = sendRequest(requestData);
            List<Financial_Data__c> responseData = processResponse(response, dataType, mostRecentDate, archivedRecordType, predictionRecordType);
            dataToUpsert.addAll(responseData);
        }
        
        //upsert all data
        System.debug('Data to Upsert: ' + dataToUpsert);
    }

    private static HttpResponse sendRequest(List<Financial_Data__c> requestData){
        //prepare request
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        String api_key = API_Keys__mdt.getInstance('AWS_Prediction_Service').Key__c;
        System.debug('key: ' + api_key);
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
    
    private static List<Financial_Data__c> processResponse(HttpResponse response, String dataType, Date mostRecentDate, Id archivedRecordTypeId, Id predictionRecordTypeId){

        //handle new predictions, by preparing them as a list
        List<Financial_Data__c> financialDataToInsert = new List<Financial_Data__c>();
		
        if (response.getStatusCode() == 200) {
            AutomatedProcessLog__c resultLog = new AutomatedProcessLog__c(Status__c='Success',Log__c=response.getBody());
            //insert resultLog;
            
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
            
            
            for(Object prediction : predictions){
                System.debug('Value: ' + prediction);
                List<Object> predictionValueParsed = (List<Object>) prediction;
                System.debug('Exact Value: ' + predictionValueParsed[0]);
                Decimal formattedValue = (Decimal) predictionValueParsed[0];
                if(dataType == 'GDP'){
                    mostRecentDate = mostRecentDate.addMonths(3); //each data point is quarterly
                }else{
                    mostRecentDate = mostRecentDate.addMonths(1); //all other data points are monthly
                }
                financialDataToInsert.add(new Financial_Data__c(Value__c = formattedValue.round(), Type__c = dataType, Date__c = mostRecentDate, RecordTypeId=predictionRecordTypeId));
            }
            
            System.debug('Data to Insert: ' + financialDataToInsert);

            //archive all existing predictions
            List<Financial_Data__c> dataToArchive = [SELECT Id, Value__c FROM Financial_Data__c WHERE RecordType.Name = 'Prediction'];
            for(Financial_Data__c record : dataToArchive){
                record.RecordTypeId = archivedRecordTypeId;
                financialDataToInsert.add(record);
            }           
        } else {
            // Handle non-200 response codes
            System.debug('Error: ' + response.getStatusCode() + ' - ' + response.getStatus());
        }
        
        return financialDataToInsert;
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