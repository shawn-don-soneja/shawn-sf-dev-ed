import { LightningElement, wire, track, api } from 'lwc';
import getFinancialData from '@salesforce/apex/FinancialDataManager.getFinancialData';
import { loadScript } from 'lightning/platformResourceLoader';



export default class ParentFinancialChartContainer extends LightningElement {
    @track financialData;
    @track unemploymentData;
    inflationData;
    //@track interestRateData;
    //@track gdpData;

    //query for financial data, to pass to children charts
    renderedCallback() {
        getFinancialData()
            .then(result => {
                //sort all data by its date
                var sortedData = result;
                sortedData.sort((a,b) => (a.Date__c > b.Date__c) ? 1 : ((b.Date__c > a.Date__c) ? -1 : 0));

                //format the data to pass to child charts
                var unemploymentData = [];
                var inflationDataPoints = [];
                sortedData.forEach((item) => {
                    if(item.Type__c == 'Unemployment'){
                        unemploymentData.push({x: item.Date__c, y: item.Value__c});
                    }else if(item.Type__c == 'CPI'){
                        inflationDataPoints.push({x: item.Date__c, y: item.Value__c});
                    }
                })
                this.inflationData = inflationDataPoints;
            })
    } 
}