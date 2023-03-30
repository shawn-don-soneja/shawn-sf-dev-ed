import { LightningElement, wire, track, api } from 'lwc';
import getFinancialData from '@salesforce/apex/FinancialDataManager.getFinancialData';
import chartjs from '@salesforce/resourceUrl/ChartJs';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FinancialChartComponent extends LightningElement {
    @track mainData;
    @track chartData = [];
    @track chartLabels = [];
    @track isChartJsInitialized;
    chart;
    //@track isLoading = true;

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
                display: false,
                text: 'CPI Data'
            },
            scales: {
                xAxes: [{
                    type: 'time',
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
                        suggestedMax: 1,
                        stepSize: 0.1,
                    }
                }]
            },
        }
    };

    /*
    renderedCallback() {
        

        getFinancialData()
            .then(result => {
            this.mainData = result.filter((eachItem) => eachItem.Type__c == 'CPI');
            var dataPoints = [];
            var chartLabels = [];
            //var timePoints = [];
            this.mainData.sort((a,b) => (a.Date__c > b.Date__c) ? 1 : ((b.Date__c > a.Date__c) ? -1 : 0));
            var index = 1;
            this.mainData.forEach((item) => {
                //dataPoints.push({x: index, y: item.Value__c});
                chartLabels.push(item.Date__c);
                dataPoints.push({x: item.Date__c, y: item.Value__c});
                index++;
                //timePoints.push(item.Date__c);
            })
            console.log('unemployment data before: ', this.chartData );
            console.log('datapoints: ' + JSON.stringify(dataPoints));
            this.chartData = [{y: 12, x: 122}, {y: 13, x: 122}];
            //this.chartLabels = chartLabels;

            console.log('unemployment data after: ', this.chartData );
            console.log('config: ', JSON.stringify(this.config.data));
            var myconfig = this.config;
            myconfig.data.datasets[0].data = dataPoints;
            myconfig.data.labels = chartLabels;

            //local
            loadScript(this, chartjs + '.js').then(() => {
            
            //org
            //loadScript(this, chartjs).then(() => {
                const ctx = this.template.querySelector('canvas.linechart').getContext('2d');
                this.chart = new window.Chart(ctx, myconfig);
                this.chart.canvas.parentNode.style.height = '100%';
                this.chart.canvas.parentNode.style.width = '100%';
            }).catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error loading ChartJS',
                        message: JSON.stringify(error),
                        variant: 'error',
                    }),
                );
                console.log("Error:", JSON.stringify(error));
            });
        })
        if (this.isChartJsInitialized) {
            return;
        }
        this.isChartJsInitialized = true;
    } 
    */
}