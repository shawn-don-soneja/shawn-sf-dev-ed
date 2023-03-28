import { LightningElement, wire, track, api } from 'lwc';
import getFinancialData from '@salesforce/apex/FinancialDataManager.getFinancialData';
import chartjs from '@salesforce/resourceUrl/ChartJs';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FinancialChartComponent extends LightningElement {
    @track unemploymentData;
    @track unemploymentDataPoints;
    @track unemploymentTimePoints; 
    @track inflationData;
    @track inflationDataPoints;
    @track inflationTimePoints;
    @track isLoading = true;

    @api chartCategory = 'Unemployment';

    @track unemploymentChartData = [];

    @track isChartJsInitialized;
    chart;

    @track config = {
        type: 'line',
        data: {
            datasets: [{
                fill: false,
                label: 'Line Dataset',
                data: this.unemploymentChartData,
                backgroundColor: [
                    'rgba(255, 99, 132, 0.2)'
                ],
                borderColor: [
                    'rgba(255, 99, 132, 1)'
                ],
                pointBackgroundColor: 'rgba(255, 99, 132, 0.2)',
                pointBorderColor: 'rgba(255, 99, 132, 1)'
            },
            ]
        },
        options: {
            title: {
                display: true,
                text: 'Sand Samples Against Comm Weight %.'
            },
            scales: {
                xAxes: [{
                    type: 'linear',
                    ticks: {
                        suggestedMin: 0,
                        suggestedMax: 40,
                        stepSize: 1
                    }
                }],
                yAxes: [{
                    type: 'linear',
                    ticks: {
                        autoSkip: true,
                        suggestedMin: 0,
                        suggestedMax: 20000,
                        stepSize: 1000,
                        callback: function (value) {
                            return value + '%';
                        }
                    }
                }]
            },
        }
    };

    connectedCallback() {
        

        getFinancialData()
            .then(result => {
            this.unemploymentData = result.filter((eachItem) => eachItem.Type__c == 'Unemployment');
            var dataPoints = [];
            //var timePoints = [];
            this.unemploymentData.sort((a,b) => (a.Date__c > b.Date__c) ? 1 : ((b.Date__c > a.Date__c) ? -1 : 0));
            var index = 1;
            this.unemploymentData.forEach((item) => {
                dataPoints.push({x: index, y: item.Value__c});
                index++;
                //timePoints.push(item.Date__c);
            })
            console.log('unemployment data before: ', this.unemploymentChartData );
            console.log('datapoints: ' + JSON.stringify(dataPoints));
            this.unemploymentChartData = [{y: 12, x: 122}, {y: 13, x: 122}];

            console.log('unemployment data after: ', this.unemploymentChartData );
            console.log('config: ', JSON.stringify(this.config.data));
            var config = this.config;
            config.data.datasets[0].data = dataPoints;

            loadScript(this, chartjs).then(() => {
                const ctx = this.template.querySelector('canvas.linechart').getContext('2d');
                this.chart = new window.Chart(ctx, this.config);
                this.chart.canvas.parentNode.style.height = '100%';
                this.chart.canvas.parentNode.style.width = '100%';
            }).catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error loading ChartJS',
                        message: error.message,
                        variant: 'error',
                    }),
                );
            });
        })
        if (this.isChartJsInitialized) {
            return;
        }
        this.isChartJsInitialized = true;
    }
}