import { LightningElement, wire, track, api } from 'lwc';
import getFinancialData from '@salesforce/apex/FinancialDataManager.getFinancialData';
import { loadScript } from 'lightning/platformResourceLoader';
import chartjs from '@salesforce/resourceUrl/ChartJs';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';



export default class ParentFinancialChartContainer extends LightningElement {
    @track financialData;
    gdpDataPoints = [];
    unemploymentData = [];
    interestRateData = [];
    inflationData = [{x: "12/02/2022", y:50}, {x: "12/05/2022", y:60}];
    @track isChartJsInitialized;
    @track isLoading = true;
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
            layout: {
                padding: {
                    left: 40,
                    right: 50,
                    bottom: 10,
                }
            },
            title: {
                display: false,
                text: 'CPI Data'
            },
            scales: {
                xAxes: [{
                    type: 'time',
                    time: {
                        // Luxon format string
                        tooltipFormat: 'MMM YYYY',
                        displayFormats: {
                            year: 'YYYY'
                        },
                        unit: 'year',
                        //min: '2020-01-01 00:00:00'
                    },
                    ticks: {
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
    @track unemploymentConfig = {
        type: 'line',
        data: {
            labels: ["January","January","January","January","January",],
            datasets: [{
                fill: false,
                label: 'Unemployment Rate',
                data: this.chartData,
                backgroundColor: [
                    'rgba(75, 192, 217, 0.2)'
                ],
                borderColor: [
                    'rgba(75, 192, 217, 1)'
                ],
                pointBackgroundColor: 'rgba(75, 192, 217, 0.2)',
                pointBorderColor: 'rgba(75, 192, 217, 1)'
            },
            ]
        },
        options: {
            layout: {
                padding: {
                    left: 40,
                    right: 50,
                    bottom: 10,
                }
            },
            title: {
                display: false,
                text: 'Unemployment Data'
            },
            scales: {
                xAxes: [{
                    type: 'time',
                    time: {
                        // Luxon format string
                        tooltipFormat: 'MMM YYYY',
                        displayFormats: {
                            year: 'YYYY'
                        },
                        unit: 'year'
                    },
                    ticks: {
                        stepSize: 0.5,
                    }
                }],
                yAxes: [{
                    type: 'linear',
                    ticks: {
                        min: 15000,
                        max: 20000,
                        stepSize: 1000,
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
                    'rgba(97, 161, 223, 0.2)'
                ],
                borderColor: [
                    'rgba(97, 161, 223, 1)'
                ],
                pointBackgroundColor: 'rgba(97, 161, 223, 0.2)',
                pointBorderColor: 'rgba(97, 161, 223, 1)'
            },
            ]
        },
        options: {
            title: {
                display: true,
                text: 'GDP'
            },
            layout: {
                padding: {
                    left: 40,
                    right: 50,
                    bottom: 10,
                }
            },
            scales: {
                xAxes: [{
                    type: 'time',
                    
                }],
                yAxes: [{
                    type: 'linear',
                    ticks: {
                        min: 15000,
                        max: 30000,
                    },
                    min: '2021-11-07 00:00:00',
                }],
            },
        }
    }
    @track interestRateConfig = {
        type: 'line',
        data: {
            labels: ["January"],
            datasets: [{
                fill: false,
                label: 'Interest Rates',
                data: this.chartData,
                backgroundColor: [
                    'rgba(142, 170, 247, 0.2)'
                ],
                borderColor: [
                    'rgba(142, 170, 247, 1)'
                ],
                pointBackgroundColor: 'rgba(142, 170, 247, 0.2)',
                pointBorderColor: 'rgba(142, 170, 247, 1)'
            },
            ]
        },
        options: {
            title: {
                display: true,
                text: 'Interest Rates'
            },
            layout: {
                padding: {
                    left: 40,
                    right: 50,
                    bottom: 10,
                }
            },
            scales: {
                xAxes: [{
                    type: 'time',
                }],
                yAxes: [{
                    type: 'linear',
                    ticks: {
                        min: 0,
                        max: 15,
                    }
                }]
            },
        }
    }
    @track lastModifiedDate;
    
    //@track interestRateData;
    //@track gdpData;

    //query for financial data, to pass to children charts
    renderedCallback() {
        getFinancialData()
            .then(result => {
                //sort all data by its date
                var sortedData = result;
                console.log('sorted data length before filter: ' + sortedData.length);
                sortedData.sort((a,b) => (a.Date__c > b.Date__c) ? 1 : ((b.Date__c > a.Date__c) ? -1 : 0));
                sortedData = sortedData.filter((item) => item.Date__c > '2021-01-01' );
                this.lastModifiedDate = sortedData[sortedData.length - 1].Date__c;
                console.log('sorted data length after filter: ' + sortedData.length);
                //format the data to pass to child charts
                var unemploymentDataPoints = [];
                var unemploymentLabels = [];
                var inflationDataPoints = [];
                var inflationLabels = [];
                var gdpDataPoints = [];
                var gdpLabels = [];
                var interestRateDataPoints = [];
                var interestRateLabels = [];
                sortedData.forEach((item) => {
                    if(item.Type__c == 'Unemployment'){
                        unemploymentDataPoints.push({x: item.Date__c, y: item.Value__c});
                        unemploymentLabels.push(item.Date__c);
                    }else if(item.Type__c == 'CPI'){
                        inflationDataPoints.push({x: item.Date__c, y: item.Value__c});
                    }else if(item.Type__c == 'GDP'){
                        gdpDataPoints.push({x: item.Date__c, y: item.Value__c});
                        gdpLabels.push(item.Date__c);
                    }else if(item.Type__c == 'Interest Rate'){
                        interestRateDataPoints.push({x: item.Date__c, y: item.Value__c});
                        interestRateLabels.push(item.Date__c);
                    }
                })
                this.inflationData = inflationDataPoints;
                this.unemploymentData = unemploymentDataPoints;
                this.gdpData = gdpDataPoints;
                this.interestRateData = interestRateDataPoints;
                //local
                //loadScript(this, chartjs + '.js').then(() => {

                //org
                loadScript(this, chartjs).then(() => {
                    console.log('script loaded');
                    this.isChartJsInitialized = true;
                    //inflation
                    var inflationConfig = {...this.config};
                    inflationConfig.data.datasets[0].data = this.inflationData;
                    inflationConfig.data.labels = inflationLabels;
                    const canvas = document.createElement('canvas');
                    this.template.querySelector('div.chart').appendChild(canvas);
                    const ctx = canvas.getContext('2d');
                    this.chart = new window.Chart(ctx, inflationConfig);
                    this.chart.canvas.parentNode.style.height = '100%';
                    //this.chart.canvas.parentNode.style.width = '100%';

                    //unemployment
                    var unemploymentConfig = {...this.unemploymentConfig};
                    unemploymentConfig.data.datasets[0].data = this.unemploymentData; //changing this makes everything forking crash :(
                    unemploymentConfig.data.labels = unemploymentLabels;
                    console.log('unemployment data: ' + JSON.stringify(this.unemploymentData));
                    const canvas2 = document.createElement('canvas');
                    this.template.querySelector('div.unemploymentchart').appendChild(canvas2);
                    const ctx2 = canvas2.getContext('2d');
                    
                    this.chart2 = new window.Chart(ctx2, unemploymentConfig);
                    //this.chart2.canvas.parentNode.style.height = '100%';
                    //this.chart2.canvas.parentNode.style.width = '100%';

                    //GDP
                    var gdpConfig = {...this.gdpConfig};
                    gdpConfig.data.datasets[0].data = this.gdpData; //changing this makes everything forking crash :(
                    gdpConfig.data.labels = gdpLabels;
                    console.log('gdp data: ' + JSON.stringify(this.gdpData));
                    const canvas3 = document.createElement('canvas');
                    this.template.querySelector('div.gdpchart').appendChild(canvas3);
                    const ctx3 = canvas3.getContext('2d');
                    this.chart3 = new window.Chart(ctx3, gdpConfig);

                    //Interest Rate
                    var interestRateConfig = {...this.interestRateConfig};
                    interestRateConfig.data.datasets[0].data = this.interestRateData; //changing this makes everything forking crash :(
                    interestRateConfig.data.labels = interestRateConfig;
                    console.log('interest rate data: ' + JSON.stringify(this.interestRateData));
                    const canvas4 = document.createElement('canvas');
                    this.template.querySelector('div.interestratechart').appendChild(canvas4);
                    const ctx4 = canvas4.getContext('2d');
                    this.chart4 = new window.Chart(ctx4, interestRateConfig);

                    this.isLoading = false;
                }).catch(error => {
                    console.log("Error:", JSON.stringify(error));
                    this.isLoading = false;
                });
            })
            
    } 
}