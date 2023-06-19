import { LightningElement, wire, track, api } from 'lwc';
import getFinancialData from '@salesforce/apex/FinancialDataManager.getFinancialData';
import { loadScript } from 'lightning/platformResourceLoader';
import chartjs from '@salesforce/resourceUrl/ChartJs';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';



export default class ParentFinancialChartContainer extends LightningElement {
    @track financialData;
    gdpDataPoints = [];
    unemploymentData = [];
    inflationData = [{x: "12/02/2022", y:50}, {x: "12/05/2022", y:60}];
    @track isChartJsInitialized;
    chart;
    @track config = {
        type: 'line',
        data: {
            labels: ["January"],
            datasets: [{
                fill: false,
                label: 'Inflation Rate',
                data: this.chartData,
                backgroundColor: [
                    'rgba(37, 150, 190, 0.2)'
                ],
                borderColor: [
                    'rgba(37, 150, 190, 1)'
                ],
                pointBackgroundColor: 'rgba(37, 150, 190, 0.2)',
                pointBorderColor: 'rgba(37, 150, 190, 1)'
            },
            ]
        },
        options: {
            title: {
                display: true,
                text: 'CPI Data'
            },
            scales: {
                xAxes: [{
                    type: 'time',
                    time:{
                        min: 1681956535,
                    }
                    
                }],
                yAxes: [{
                    type: 'linear',
                    ticks: {
                        autoSkip: true,
                        suggestedMin: 0,
                        suggestedMax: 1,
                        stepSize: 0.1,
                    }
                }]
            },
        }
    };
    @track unemploymentConfig = {
        type: 'line',
        data: {
            labels: ["January"],
            datasets: [{
                fill: false,
                label: 'Unemployment Rate',
                data: this.chartData,
                backgroundColor: [
                    'rgba(37, 150, 190, 0.2)'
                ],
                borderColor: [
                    'rgba(37, 150, 190, 1)'
                ],
                pointBackgroundColor: 'rgba(37, 150, 190, 0.2)',
                pointBorderColor: 'rgba(37, 150, 190, 1)'
            },
            ]
        },
        options: {
            title: {
                display: true,
                text: 'Unemployment Data'
            },
            scales: {
                xAxes: [{
                    type: 'time',

                }],
                yAxes: [{
                    type: 'linear',
                    ticks: {
                        min: 15000,
                        max: 20000,
                    }
                }]
            },
        }
    };
    @track gdpConfig = {
        type: 'line',
        data: {
            labels: ["January"],
            datasets: [{
                fill: false,
                label: 'GDP',
                data: this.chartData,
                backgroundColor: [
                    'rgba(37, 150, 190, 0.2)'
                ],
                borderColor: [
                    'rgba(37, 150, 190, 1)'
                ],
                pointBackgroundColor: 'rgba(37, 150, 190, 0.2)',
                pointBorderColor: 'rgba(37, 150, 190, 1)'
            },
            ]
        },
        options: {
            title: {
                display: true,
                text: 'GDP'
            },
            scales: {
                xAxes: [{
                    type: 'time',

                }],
                yAxes: [{
                    type: 'linear',
                    ticks: {
                        min: 15000,
                        max: 20000,
                    }
                }]
            },
        }
    }
    
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
                var unemploymentDataPoints = [];
                var inflationDataPoints = [];
                var gdpDataPoints = [];
                sortedData.forEach((item) => {
                    if(item.Type__c == 'Unemployment'){
                        unemploymentDataPoints.push({x: item.Date__c, y: item.Value__c});
                    }else if(item.Type__c == 'CPI'){
                        inflationDataPoints.push({x: item.Date__c, y: item.Value__c});
                    }else if(item.Type__c == 'GDP'){
                        gdpDataPoints.push({x: item.Date__c, y: item.Value__c});
                    }
                })
                this.inflationData = inflationDataPoints;
                this.unemploymentData = unemploymentDataPoints;
                this.gdpData = gdpDataPoints;
                loadScript(this, chartjs + '.js').then(() => {
                    console.log('script loaded');
                    //console.log('config: ' + JSON.stringify(this.config.data.datasets[0].data));
                    this.isChartJsInitialized = true;
                //org
                //loadScript(this, chartjs).then(() => {
                    
                    var inflationConfig = {...this.config};
                    inflationConfig.data.datasets[0].data = this.inflationData;
                    const canvas = document.createElement('canvas');
                    this.template.querySelector('div.chart').appendChild(canvas);
                    const ctx = canvas.getContext('2d');
                    
                    this.chart = new window.Chart(ctx, inflationConfig);
                    this.chart.canvas.parentNode.style.height = '100%';
                    this.chart.canvas.parentNode.style.width = '100%';

                    /*
                    
                    */
                    var unemploymentConfig = {...this.unemploymentConfig};
                    unemploymentConfig.data.datasets[0].data = this.unemploymentData; //changing this makes everything forking crash :(
                    console.log('unemployment data: ' + JSON.stringify(this.unemploymentData));
                    const canvas2 = document.createElement('canvas');
                    this.template.querySelector('div.unemploymentchart').appendChild(canvas2);
                    const ctx2 = canvas2.getContext('2d');
                    
                    this.chart2 = new window.Chart(ctx2, unemploymentConfig);
                    //this.chart2.canvas.parentNode.style.height = '100%';
                    //this.chart2.canvas.parentNode.style.width = '100%';

                    var gdpConfig = {...this.gdpConfig};
                    gdpConfig.data.datasets[0].data = this.gdpData; //changing this makes everything forking crash :(
                    console.log('gdp data: ' + JSON.stringify(this.gdpData));
                    const canvas3 = document.createElement('canvas');
                    this.template.querySelector('div.gdpchart').appendChild(canvas2);
                    const ctx3 = canvas3.getContext('2d');
                    
                    this.chart2 = new window.Chart(ctx3, gdpConfig);
                }).catch(error => {
                    console.log("Error:", JSON.stringify(error));
                    
                    
                });
            })
            
    } 

    

    connectedCallback(){
        //

        
    }
}