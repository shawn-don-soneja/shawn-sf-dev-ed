public class FinancialDataManagerHelper {
    private static String GDP = 'GDP';
    private static String CPI = 'CPI';
    private static String INTEREST_RATE = 'Interest Rate';
    private static String UNEMPLOYMENT = 'Unemployment';

    //This function converts dates, to relative, numerical values, so that the LTSM model has more usable data
    public static List<List<List<Object>>> normalizeDates(List<Financial_Data__c> data, String type){        
        ////lets return the x and y arrays, as arrays of arrays
        List<List<Integer>> xArray = new List<List<Integer>>();
        List<List<Double>> yArray = new List<List<Double>>();

        Integer entryIndex = 1;

        for(Integer i=0; i<data.size(); i++){
            Financial_Data__c entry = data[i];
            if(entry.Type__c == type){
                xArray.add(new List<Integer>{i});
                yArray.add(new List<Double>{entry.Value__c});
            }
        }
        
        List<List<List<Object>>> output = new List<List<List<Object>>>();
        output.add(xArray);
        output.add(yArray);
        
        System.debug('Normalized Data:');
        System.debug('xArray: ' + xArray);
        System.debug('yArray: ' + yArray);

        return output;
    }
}