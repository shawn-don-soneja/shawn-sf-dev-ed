// helloWorld.js
import { LightningElement, wire, track, api } from 'lwc';
import getFinancialData from '@salesforce/apex/FinancialDataManager.getFinancialData';

import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
 
//table columns for bureau of labor statistics callout
const columns_bls = [
    { label: 'Price', fieldName: 'Value__c' },
    { label: 'Date', fieldName: 'Date__c'},
];

export default class HelloWorld extends LightningElement {
  @track unemploymentData; 
  @track inflationData;
  @track isLoading = true;
  //@wire (getFinancialData, {}) financialData; 

  //headers of table - other is columns_bls
  columns = columns_bls;
  
  connectedCallback() {
    //this.callBureauOfLaborStatistics();
    getFinancialData()
      .then(result => {
        this.unemploymentData = result.filter((eachItem) => eachItem.Type__c == 'Unemployment');
        this.inflationData = result.filter((eachItem) => eachItem.Type__c == 'CPI');
        this.data = result;
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