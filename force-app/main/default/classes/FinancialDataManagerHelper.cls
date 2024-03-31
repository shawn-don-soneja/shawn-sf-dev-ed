public class FinancialDataManagerHelper {
    private static String GDP = 'GDP';
    private static String CPI = 'CPI';
    private static String INTEREST_RATE = 'Interest Rate';
    private static String UNEMPLOYMENT = 'Unemployment';

    //This function converts dates, to relative, numerical values, so that the LTSM model has more usable data
    public static List<Financial_Data__c> normalizeDates(List<Financial_Data__c> data){
        //orders all dates
        //gives relative value based on index order of the data

        Integer GDP_Index = 1;
        Integer CPI_Index = 1;
        Integer Unemploment_Index = 1;
        Integer Interest_Rate_Index = 1;

        for(Integer i=0; i<data.size(); i++){
            Financial_Data__c entry = data[i];
            if(entry.Type__c == GDP){
                data[i].Index__c = GDP_Index;
                GDP_Index++;
            }else if(entry.Type__c == CPI){
                data[i].Index__c = CPI_Index;
                CPI_Index++;
            }else if(entry.Type__c == INTEREST_RATE){
                data[i].Index__c = Interest_Rate_Index;
                Interest_Rate_Index++;
            }else if(entry.Type__c == UNEMPLOYMENT){
                data[i].Index__c = Unemploment_Index;
                Unemploment_Index++;
            }
        }

        List<Financial_Data__c> outputList = new List<Financial_Data__c>();
        return outputList;
    }
}