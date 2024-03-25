public class FinancialDataManagerHelper {
    //This function converts dates, to relative, numerical values, so that the LTSM model has more usable data
    public static void normalizeDates(List<Financial_Data__c> data){
        //orders all dates
        //gives relative value, based on the month & year

        //since each 'type' of financial data record is taken at consistent increments,
        //I can just normalize the data by giving an 'x' value for each entry as its index
        //that way it's consistent spacing between each entry OF A GIVEN TYPE

        /*
        
        params: all entries of data

        Integer GDP_Index = 0;
        Integer CPI_Index = 0;
        Integer Unemploment_Index = 0;
        Integer Interest_Rate_Index = 0;

        for(Financial_Data__c entry : data){
            //ADD NEW ATTRIBUTE TO EACH ENTRY
            entry.Index = ...
        }
        
        */
    }
}