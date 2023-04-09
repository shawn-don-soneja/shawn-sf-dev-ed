import { LightningElement, wire, track, api } from 'lwc';
import getFinancialData from '@salesforce/apex/FinancialDataManager.getFinancialData';
import chartjs from '@salesforce/resourceUrl/ChartJs';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';



export default class ParentFinancialChartContainer extends LightningElement {
    @track financialData;
    @track unemploymentData;
    @track inflationData;
    @track isChartJsInitialized;
    chart;
    unemploymentChart;
    //@track interestRateData;
    //@track gdpData;

    @track config = {
        type: 'line',
        data: {
            labels: ["January"],
            datasets: [{
                fill: false,
                label: 'Inflation Rate',
                data: [],
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
                        autoSkip: true,
                        min: 2021,
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

    @track config_unemployment = {
        type: 'line',
        data: {
            labels: ["January"],
            datasets: [{
                fill: false,
                label: 'Unemployment Rate',
                data: [],
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
                text: 'Unemployment Rate'
            },
            scales: {
                xAxes: [{
                    type: 'time',
                    ticks: {
                        autoSkip: true,
                        min: 2021,
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
                sortedData.forEach((item) => {
                    if(item.Type__c == 'Unemployment'){
                        unemploymentDataPoints.push({x: item.Date__c, y: item.Value__c});
                    }else if(item.Type__c == 'CPI'){
                        inflationDataPoints.push({x: item.Date__c, y: item.Value__c});
                    }
                })
                this.inflationData = inflationDataPoints;
                this.unemploymentData = unemploymentDataPoints;

                if(this.isChartJsInitialized)
                    return;

                //render chart
                if(!this.isChartJsInitialized){
                    this.isChartJsInitialized = true;
                    console.log("called to initilaize");
                    console.log('inflation data: ' + JSON.stringify(this.inflationData))

                    //local
                    loadScript(this, chartjs + '.js').then(() => {
                        console.log('script loaded');
                    //org
                    //loadScript(this, chartjs).then(() => {
                        const ctx = this.template.querySelector('.linechartcpi').getContext('2d');
                        const ctx_unemployment = this.template.querySelector('.linechartunemployment').getContext('2d');
                        this.config.data.datasets[0].data = this.inflationData;
                        this.chart = new window.Chart(ctx, this.config);
                        this.config_unemployment.data.datasets[0].data = this.unemploymentData;
                        //this.unemploymentChart = new window.Chart(ctx_unemployment, this.config_unemployment);
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

            })
    } 
}