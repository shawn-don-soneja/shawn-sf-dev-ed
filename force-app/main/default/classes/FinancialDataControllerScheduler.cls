global class FinancialDataControllerScheduler implements Schedulable {
    global void execute(SchedulableContext ctx){
        /*
		1. Call FinancialDataController Class
		2. Contoller handles processing of data, as well as cleansing
		*/
        System.debug('Scheduled job is running on: ' + Datetime.now());
    }
}