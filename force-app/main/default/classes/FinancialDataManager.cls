public class FinancialDataManager {
    private static String GDP = 'GDP';
    private static String CPI = 'CPI';
    private static String INTEREST_RATE = 'Interest Rate';
    private static String UNEMPLOYMENT = 'Unemployment';
    	
	@AuraEnabled
    public static List<Financial_Data__c> getFinancialData(String dataType){
        List<Financial_Data__c> output;
        if(dataType != null){
            output = [SELECT Id, Type__c, Value__c, Date__c FROM Financial_Data__c WHERE Type__c = :dataType AND RecordType.Name = 'Active'];
        }else{
            output = [SELECT Id, Type__c, Value__c, Date__c FROM Financial_Data__c WHERE RecordType.Name = 'Active'];
        }
        return output;
    }

    //Data Refresher
    @future(callout=true)
    public static void refreshAllFinancialData(){
        List<Financial_Data__c> allData = [SELECT Id, Type__c, Value__c, Date__c FROM Financial_Data__c ORDER BY Date__c DESC];
        
        //data we need, to figure out what data from the API should be inserted into DB
        //we only insert data points which are NEWER than those we have stored in the DB
        Date latestCPI;
        Date latestGDP;
        Date latestUnemployment;
        Date latestInterestRates;
        for(Financial_Data__c entry : allData){
            if(entry.Type__c == 'CPI' && latestCPI == null){
                latestCPI = entry.Date__c;
            }
            if(entry.Type__c == 'GDP' && latestGDP == null){
                latestGDP = entry.Date__c;
            }
            if(entry.Type__c == 'Unemployment' && latestUnemployment == null){
                latestUnemployment = entry.Date__c;
            }
            if(entry.Type__c == 'Interest Rate' && latestInterestRates == null){
                latestInterestRates = entry.Date__c;
            }
            if(latestCPI != null && latestGDP != null && latestUnemployment != null && latestInterestRates != null){
                break;
            }
        }
        
        //retrieve data from api's and filter to only new data to insert
        List<Financial_Data__c> toInsert = new List<Financial_Data__c>();
        
        List<Financial_Data__c> cpi_data = FinancialDataManager.retrieveCPI_Rice(); //CPI
        List<Financial_Data__c> cpi_data_filtered = filterForNewData(CPI, latestCPI, cpi_data);
        System.debug('CPI to Insert Length:' + cpi_data_filtered.size());
        System.debug('CPI to Insert:' + cpi_data_filtered);
        toInsert.addAll(cpi_data_filtered);
        //send for predictions on original, long list
        FinancialDataManagerHelper.normalizeDates(cpi_data, CPI); 
        
        List<Financial_Data__c> unemployment_data = retrieveUnemployment(); //unemployment data
		List<Financial_Data__c> unemployment_data_filtered = filterForNewData(UNEMPLOYMENT, latestUnemployment, unemployment_data);
        System.debug('UNEMPLOYMENT to Insert Length:' + unemployment_data_filtered.size());
        System.debug('UNEMPLOYMENT to Insert:' + unemployment_data_filtered);
        toInsert.addAll(unemployment_data_filtered);
        //send for predictions on original, long list
        FinancialDataManagerHelper.normalizeDates(unemployment_data, UNEMPLOYMENT); 

        
        List<Financial_Data__c> interest_rate_data = FinancialDataManager.retrieveInterestRates(); //interest rates
		List<Financial_Data__c> interest_rate_data_filtered = filterForNewData(INTEREST_RATE, latestInterestRates, interest_rate_data);
        System.debug('Interest Rates to Insert Length:' + interest_rate_data_filtered.size());
        System.debug('Interest Rates to Insert:' + interest_rate_data_filtered);
		toInsert.addAll(interest_rate_data_filtered);
        //send for predictions on original, long list
        FinancialDataManagerHelper.normalizeDates(interest_rate_data, INTEREST_RATE); 

        
        List<Financial_Data__c> gdp_data = FinancialDataManager.retrieveGDP();//GDP
        List<Financial_Data__c> gdp_data_filtered = filterForNewData(GDP, latestGDP, gdp_data);
        System.debug('GDP to Insert Length:' + gdp_data_filtered.size());
        System.debug('GDP to Insert:' + gdp_data_filtered);
        toInsert.addAll(gdp_data_filtered);
        //send for predictions on original, long list
        FinancialDataManagerHelper.normalizeDates(gdp_data, GDP); 

        
        insert toInsert;
    }
    
    public static List<Financial_Data__c> filterForNewData (String dataType, Date latestDate, List<Financial_Data__c> data){
		Date latestData;
        
        List<Financial_Data__c> toReturn = new List<Financial_Data__c>();
        for(Financial_Data__c entry : data){
            if(entry.Type__c == dataType && entry.Date__c > latestDate){
                toReturn.add(entry);
            }
        }
        //then return only GDP entries whose data is greater than the latest, stored GDP entry
        return toReturn;
    }

    public List<Financial_Data__c> predictOnData(List<List<List<Object>>> normalizedData){
        //normalize
        //List<Financial_Data__c> normalizedData = FinancialDataManagerHelper.normalizeDates(data);

        //request for predictions
        //uses Service Class, to deliver Payload and Receive Response

        //return list of predictions to be inserted
        List<Financial_Data__c> outputList = new List<Financial_Data__c>();
        return outputList;
    }
	
    //CPI
    public static List<Financial_Data__c> retrieveCPI_Rice(){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:BLS_CPI');
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        List<Financial_Data__c> listToInsert = new List<Financial_Data__c>();
        // If the request is successful, parse the JSON response.
        if(response.getStatusCode() == 200) {
            // Deserialize the JSON string into collections of primitive data types.
            Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            // Cast the values in the 'animals' key as a 
           	Map<String, Object> results = (Map<String, Object>) parsedResponse.get('Results');
            List<Object> series = (List<Object>) results.get('series');
            Map<String, Object> seriesData = (Map<String, Object>) series[0];
            List<Object> data = (List<Object>) seriesData.get('data');
            System.debug('Received the following data:' + data);
            System.debug('Data Length' + data.size());
            
            for(Object dataEntry : data){
                Map<String, Object> parsedDataEntry = (Map<String, Object>) dataEntry;
                Integer integerYear = Integer.valueOf(parsedDataEntry.get('year'));
                String month = (String) parsedDataEntry.get('period');
                month = month.substring(1);
                Integer integerMonth = Integer.valueOf(month);
                //System.debug('received month: ' + month + ' | new month: ' + integerMonth);
                //System.debug('data: ' + dataEntry);
                Date entryDate = date.newInstance(integerYear, integerMonth, 1);
                String stringValue = (String) parsedDataEntry.get('value');
                Decimal value = Decimal.valueOf(stringValue);
                Financial_Data__c itemToInsert = new Financial_Data__c(Type__c='CPI',Sub_Type__c='Rice Price', Date__c=entryDate, Value__c=value);
            	listToInsert.add(itemToInsert);
            }
            System.debug('list:' + listToInsert);
            //insert listToInsert;
            /*
			
			*/
            
        }
        //List<Financial_Data__c> output = new List<Financial_Data__c>();
        return listToInsert;
    }
    //Unemployment
    public static List<Financial_Data__c> retrieveUnemployment(){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:BLS_Unemployment');
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        List<Financial_Data__c> listToInsert = new List<Financial_Data__c>();
        // If the request is successful, parse the JSON response.
        if(response.getStatusCode() == 200) {
            // Deserialize the JSON string into collections of primitive data types.
            Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            // Cast the values in the 'animals' key as a 
           	Map<String, Object> results = (Map<String, Object>) parsedResponse.get('Results');
            List<Object> series = (List<Object>) results.get('series');
            Map<String, Object> seriesData = (Map<String, Object>) series[0];
            List<Object> data = (List<Object>) seriesData.get('data');
            System.debug('Received the following data:' + data);
            System.debug('Data Length' + data.size());
            
            for(Object dataEntry : data){
                Map<String, Object> parsedDataEntry = (Map<String, Object>) dataEntry;
                Integer integerYear = Integer.valueOf(parsedDataEntry.get('year'));
                String month = (String) parsedDataEntry.get('period');
                month = month.substring(1);
                Integer integerMonth = Integer.valueOf(month);
                //System.debug('received month: ' + month + ' | new month: ' + integerMonth);
                //System.debug('data: ' + dataEntry);
                Date entryDate = date.newInstance(integerYear, integerMonth, 1);
                String stringValue = (String) parsedDataEntry.get('value');
                Decimal value = Decimal.valueOf(stringValue);
                    Financial_Data__c itemToInsert = new Financial_Data__c(Type__c='Unemployment',Sub_Type__c='Local Area', Date__c=entryDate, Value__c=value);
            	listToInsert.add(itemToInsert);
            }
            System.debug('list:' + listToInsert);
            //insert listToInsert;
            /*
			
			*/
            
        }
        //List<Financial_Data__c> output = new List<Financial_Data__c>();
        return listToInsert;
    }
    //Interest Rates
    public static List<Financial_Data__c> retrieveInterestRates(){
        System.debug('REQUEST INTEREST RATES');
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
		//https://api.fiscaldata.treasury.gov/services/api/fiscal_service/v2/accounting/od/avg_interest_rates?sort=-record_date&filter=security_desc:eq:United%20States%20Savings%20Inflation%20Securities
        request.setEndpoint('callout:Fiscal_Data_Interest_Rates');
        request.setMethod('GET');
        System.debug('Request: ' + request);
        HttpResponse response = http.send(request);
        List<Financial_Data__c> listToInsert = new List<Financial_Data__c>();

        // If the request is successful, parse the JSON response.
        if(response.getStatusCode() == 200) {
            System.debug('Success | Response: ' + response);
            // Deserialize the JSON string into collections of primitive data types.
            Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            // HERE'S THE LOGIC FOR PARSING THIS SPECIFIC API
            List<Object> data = (List<Object>) parsedResponse.get('data');
            System.debug('Received the following data:' + data);
            System.debug('Data Length' + data.size());
            
            for(Object dataEntry : data){
                Map<String, Object> parsedDataEntry = (Map<String, Object>) dataEntry;
                Integer integerYear = Integer.valueOf(parsedDataEntry.get('record_calendar_year'));
                String month = (String) parsedDataEntry.get('record_calendar_month');
                month = month.substring(1);
                Integer integerMonth = Integer.valueOf(month);
                //System.debug('received month: ' + month + ' | new month: ' + integerMonth);
                //System.debug('data: ' + dataEntry);
                Date entryDate = date.newInstance(integerYear, integerMonth, 1);
                String stringValue = (String) parsedDataEntry.get('avg_interest_rate_amt');
                Decimal value = Decimal.valueOf(stringValue);
                    Financial_Data__c itemToInsert = new Financial_Data__c(Type__c='Interest Rate',Sub_Type__c='Average Interest Rates', Date__c=entryDate, Value__c=value);
            	listToInsert.add(itemToInsert);
            }
            System.debug('list:' + listToInsert);
            System.debug('list length:' + listToInsert.size());
            System.debug('last item' + listToInsert[listToInsert.size() - 1]);
            //insert listToInsert;
            /*
			
			*/
            
        }else{
            System.debug('Error | Response: ' + response);
        }
        //List<Financial_Data__c> output = new List<Financial_Data__c>();
        return listToInsert;
    }
    //GDP
    public static List<Financial_Data__c> retrieveGDP(){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:GDP');
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        List<Financial_Data__c> listToInsert = new List<Financial_Data__c>();
        // If the request is successful, parse the JSON response.
        if(response.getStatusCode() == 200) {
            System.debug('Response: ' + response);
            // Deserialize the JSON string into collections of primitive data types.
            Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            // HERE'S THE LOGIC FOR PARSING THIS SPECIFIC API
           	Map<String, Object> results = (Map<String, Object>) parsedResponse.get('BEAAPI');
            List<Object> series = (List<Object>) results.get('Results');
            Map<String, Object> seriesData = (Map<String, Object>) series[0];
            List<Object> data = (List<Object>) seriesData.get('Data');
            System.debug('Received the following data:' + data);
            System.debug('Data Length' + data.size());

            for(Object dataEntry : data){
                Map<String, Object> parsedDataEntry = (Map<String, Object>) dataEntry;
                String industryType = (String) parsedDataEntry.get('Industry');

                //we receive GDP across industries with this query, and we only want to show overall GDP figure right now
                if(industryType == 'GDP'){
                    Integer integerYear = Integer.valueOf(parsedDataEntry.get('Year'));
                    String quarter = (String) parsedDataEntry.get('Quarter');
                    Integer quarter_int = 0;
                    Integer integerMonth = 0;
                    if(quarter == 'I'){
                        quarter_int = 1;
                        integerMonth = 3;
                    }else if(quarter == 'II'){
                        quarter_int = 2;
                        integerMonth = 6;
                    }else if(quarter == 'III'){
                        quarter_int = 3;
                        integerMonth = 9;
                    }else if(quarter == 'IV'){
                        quarter_int = 4;
                        integerMonth = 12;
                    }
                    //quarter = quarter.substring(1);
                    //Integer integerMonth = 00;
                    //System.debug('received quarter: ' + quarter + ' | new month: ' + quarter_int);
                    //System.debug('data: ' + dataEntry);
                    Date entryDate = date.newInstance(integerYear, integerMonth, 1);
                    String stringValue = (String) parsedDataEntry.get('DataValue');
                    Decimal value = Decimal.valueOf(stringValue);
                    Financial_Data__c itemToInsert = new Financial_Data__c(Type__c='GDP', Date__c=entryDate, Value__c=value);
                    listToInsert.add(itemToInsert);
                }
                
            }
            System.debug('list:' + listToInsert);
            System.debug('length: ' + listToInsert.size());
            System.debug('last item' + listToInsert[listToInsert.size() - 1]);
            //insert listToInsert;
        }else{
            if(response.getStatusCode() == 301 || response.getStatusCode() == 302){    
                request.setEndpoint(response.getHeader('Location'));
                HttpResponse response2 = http.send(request);
                System.debug('Response2' + response2);
            }
            System.debug('Error:' + response);
        }
        //List<Financial_Data__c> output = new List<Financial_Data__c>();        
        return listToInsert;
    }
    
    
}