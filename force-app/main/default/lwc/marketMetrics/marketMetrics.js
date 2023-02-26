// helloWorld.js
import { LightningElement, wire, track, api } from 'lwc';

//table columns for bureau of labor statistics callout
const columns_bls = [
    { label: 'Price', fieldName: 'value' },
    { label: 'Month', fieldName: 'periodName'},
    { label: 'Year', fieldName: 'year'},
];

export default class HelloWorld extends LightningElement {
  @track data; //variable for table's data
  @track isLoading = true;

  //headers of table - other is columns_bls
  columns = columns_bls;
  
  connectedCallback() {
    this.callBureauOfLaborStatistics();
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