import { LightningElement, wire, track, api } from 'lwc';
import getFinancialData from '@salesforce/apex/FinancialDataManager.getFinancialData';
import { loadScript } from 'lightning/platformResourceLoader';
import chartjs from '@salesforce/resourceUrl/ChartJs';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';



export default class ParentFinancialChartContainer extends LightningElement {
    @track financialData;
    @track unemploymentData;
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

                loadScript(this, chartjs + '.js').then(() => {
                    console.log('script loaded');
                    this.isChartJsInitialized = true;
                //org
                //loadScript(this, chartjs).then(() => {
                    
                    this.config.data.datasets[0].data = this.inflationData;
                    console.log('config: ' + JSON.stringify(this.config.data.datasets[0].data));
                    const canvas = document.createElement('canvas');
                    this.template.querySelector('div.chart').appendChild(canvas);
                    const ctx = canvas.getContext('2d');
                    this.chart = new window.Chart(ctx, this.config);
                    this.chart.canvas.parentNode.style.height = '100%';
                    this.chart.canvas.parentNode.style.width = '100%';
                }).catch(error => {
                    console.log("Error:", JSON.stringify(error));
                    
                    
                });
            })
            
    } 

    

    connectedCallback(){
        //

        
    }
}