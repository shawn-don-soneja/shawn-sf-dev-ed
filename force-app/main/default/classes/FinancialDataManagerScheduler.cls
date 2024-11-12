global class FinancialDataManagerScheduler implements Schedulable{
	global void execute(SchedulableContext sc) {
        // Your logic here
        System.debug('Scheduled job is running.');
        
        // Example: Query accounts and update a field
        //FinancialDataManager fdm = new FinancialDataManager();
        FinancialDataManager.refreshAllFinancialData();
    }
}