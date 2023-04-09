import { LightningElement, wire, track, api } from 'lwc';
import getFinancialData from '@salesforce/apex/FinancialDataManager.getFinancialData';
import chartjs from '@salesforce/resourceUrl/ChartJs';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FinancialChartComponent extends LightningElement {
    @api inflationdata;
    @track mainData;
    @track chartData = [{x: 1, y: 2}];
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

    connectedCallback(){
        console.log('inflation data:' + this.inflationdata);

        //render chart
        if(!this.isChartJsInitialized){
            this.isChartJsInitialized = true;
            console.log("called to initilaize");

            //local
            loadScript(this, chartjs + '.js').then(() => {
                console.log('script loaded');
            //org
            //loadScript(this, chartjs).then(() => {
                const ctx = this.template.querySelector('canvas.linechartcpi').getContext('2d');
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
                console.log("Error:", JSON.stringify(error));
            });
        }
    }
}