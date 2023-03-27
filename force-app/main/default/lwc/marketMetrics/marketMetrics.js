// helloWorld.js
import { LightningElement, wire, track, api } from 'lwc';
import getFinancialData from '@salesforce/apex/FinancialDataManager.getFinancialData';

import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import TRAILHEAD_LOGO from '@salesforce/resourceUrl/chartjs_v280';
//https://d5e0000012hzdeai-dev-ed.lightning.force.com/resource/1678834348000/chartjs_v280
 
//table columns for bureau of labor statistics callout
const columns_bls = [
    { label: 'Price', fieldName: 'Value__c' },
    { label: 'Date', fieldName: 'Date__c'},
];

export default class HelloWorld extends LightningElement {
  @track unemploymentData;
  @track unemploymentDataPoints;
  @track unemploymentTimePoints; 
  @track inflationData;
  @track inflationDataPoints;
  @track inflationTimePoints;
  @track isLoading = true;
  //@wire (getFinancialData, {}) financialData; 

  //headers of table - other is columns_bls
  columns = columns_bls;
  
  connectedCallback() {
    //this.callBureauOfLaborStatistics();
    getFinancialData()
      .then(result => {
        this.unemploymentData = result.filter((eachItem) => eachItem.Type__c == 'Unemployment');
        var dataPoints = [];
        var timePoints = [];
        this.unemploymentData.sort((a,b) => (a.Date__c > b.Date__c) ? 1 : ((b.Date__c > a.Date__c) ? -1 : 0));
        this.unemploymentData.forEach((item) => {
          dataPoints.push(item.Value__c);
          timePoints.push(item.Date__c);
        })
        this.unemploymentDataPoints = dataPoints;
        this.unemploymentTimePoints = timePoints;

        this.inflationData = result.filter((eachItem) => eachItem.Type__c == 'CPI');
        var dataPoints_inflation = [];
        var timePoints_inflation = [];
        this.inflationData.sort((a,b) => (a.Date__c > b.Date__c) ? 1 : ((b.Date__c > a.Date__c) ? -1 : 0));
        this.inflationData.forEach((item) => {
          dataPoints_inflation.push(item.Value__c);
          timePoints_inflation.push(item.Date__c);
        })
        this.inflationDataPoints = dataPoints_inflation;
        this.inflationTimePoints = timePoints_inflation;
        this.isLoading = false;
      })
      .catch(error => {
        console.log('error' + JSON.stringify(error));
        this.isLoading = false;
    });
  }
  renderedCallback(){
    //console.log('rendered');
    //console.log('data: ' + JSON.stringify(this.data));
  }

  callBureauOfLaborStatistics(){
    var url = 'https://api.bls.gov/publicAPI/v2/timeseries/data/APU0000701312?registrationkey=ba862d2378f345e48d1f64bfda019ba2';
    fetch(url)
      .then((response) => { return response.json(); })
      .then( data => { 
        this.data = data.Results.series[0].data;
        this.isLoading = false;})
      .catch( error => { console.log(error); })
  }
}