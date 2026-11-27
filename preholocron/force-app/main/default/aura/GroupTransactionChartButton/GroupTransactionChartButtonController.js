({
    doInit : function(component, event, helper) {
    },
    openReportWindow : function(component, event, helper) {
        var action = component.get("c.setupReportURL");
        action.setParams({
            'reportName': component.get("v.reportName")
        });
        var url;
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                url = response.getReturnValue();
                let recId = component.get("v.recordId").slice(0,15);
                url = url + "?fv0=" + recId + "&fv1=" + recId + "&fv2=" + recId + "&fv3=" + recId + "&fv4=" + recId + "&fv5=" + recId;
                let isMonthly = component.get("v.showMonthlyReport");
                if(isMonthly){
                    url += "&fv6=Monthly";
                }
                console.log('URL:'+ url);
                window.open(url);
            }
        })
        $A.enqueueAction(action);
    },
    createPlannedchart: function(component, event, helper) {
        console.log('createPlannedChart');
        var chartCanvas = component.find("plannedChart").getElement();
        var action = component.get("c.setupData");
        action.setParams({
            'AccountId' : component.get("v.recordId"),
            'isMonthly' : component.get("v.showMonthlyReport"),
            'reportName': component.get("v.reportName")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                component.set("v.showSpinner", false);
                var result = response.getReturnValue();
                if (result == null) {
                    helper.showToast("Error!", "error", "Something wrong with loading chart data. Please contact system administrator.");
                }else {
                    let retVals = JSON.parse( result );
                    console.log('result :');
                    console.log(retVals);
                    var chartData = [];
                    var chartDataSet = [];
                    var chartLabels = [];
                    var nullcheckDown = retVals.groupingsDown.groupings;
                    var nullcheckAccross = retVals.groupingsAcross.groupings;
                    var yAxesLabel = '';
                    var yAxesIdx = null;
                    if (nullcheckDown !== null && nullcheckAccross !== null) {
                        for (var i = 0; i < (nullcheckDown.length); i++) {
                            //Iterate and prepare the list of Labels for the chart
                            var labelItem = nullcheckDown[i].label;
                            chartLabels.push(labelItem);
                            var keyTemp = nullcheckDown[i].key;
                            //Prepare the chart data to be plotted.
                            var valueTempArray = retVals.factMap[keyTemp + "!T"].aggregates;
                            var valueTemp = 0;
                            if(valueTempArray != null){
                                valueTemp = valueTempArray[1].label; //array[1] for Sum of TPV (USD)
                            }

                            chartData.push(valueTemp);
                        }

                        for (var k = 0; k < (nullcheckAccross.length); k++) {
                            let setlabelItem = nullcheckAccross[k].label;
                            let setKeyTemp = nullcheckAccross[k].key;
                            let tempData = [];
                            let setDataObj = {};
                            for(var l = 0; l < (nullcheckDown.length); l++){
                                let groupKeyTemp = nullcheckDown[l].key;
                                let setValueArr = retVals.factMap[groupKeyTemp + "!" + setKeyTemp].aggregates; //0!0, 1!0
                                let setValueTemp = 0;
                                if(setValueArr != null){
                                    let TPVUSDIdx  = 1;
                                    setValueTemp = setValueArr[TPVUSDIdx].value.toFixed(2);
                                    yAxesIdx = TPVUSDIdx;

                                    //add all values from the grouping date (var i) for each product (var k)
                                    tempData.push(setValueTemp);
                                }
                            }
                            setDataObj.label = setlabelItem;
                            setDataObj.data = tempData;
                            setDataObj.backgroundColor = "#000000".replace(/0/g,function(){return (~~(Math.random()*16)).toString(16);});
                            setDataObj.stack = 'Stack 0';
                            chartDataSet.push(setDataObj);
                        }

                        if(retVals.reportExtendedMetadata.aggregateColumnInfo !== null && retVals.reportMetadata.aggregates !== null){
                            yAxesLabel = retVals.reportExtendedMetadata.aggregateColumnInfo[retVals.reportMetadata.aggregates[yAxesIdx]].label;
                        }
                    }

                    //Construct chart-doughnut/bar
                    //documentation : https://www.chartjs.org/docs/2.7.3/
                    var plannedChart = new Chart(chartCanvas, {
                        type: 'bar',
                        data: {
                            labels: chartLabels,
                            datasets: chartDataSet
                        },
                        options: {
                            responsive: true,
                            title: {
                                display: true,
                                text: retVals.reportMetadata.name,
                                fullSize: true
                            },
                            scales: {
                                xAxes: [{
                                    stacked : true,
                                    beginAtZero: true
                                }],
                                yAxes: [{
                                    stacked : true,
                                    beginAtZero: true,
                                    position: 'left',
                                    scaleLabel: {
                                        display: true,
                                        labelString: yAxesLabel
                                    }
                                }]
                            },
                            maintainAspectRatio: false,
                            legend: {
                                display: false
                            },
                            tooltips: {
                                callbacks: {
                                    label: function(tooltipItem, data) {
                                        var label = data.datasets[tooltipItem.datasetIndex].label || '';
                    
                                        if (label) {
                                            label += ': ';
                                        }
                                        var numVal = tooltipItem.yLabel || 0;
                                        label += 'USD ' + numVal.toLocaleString('en-US');
                                        return label;
                                    },
                                    footer: function(tooltipItem,data) {
                                        var footer = 'Total :';
                                        var numVal = chartData[tooltipItem[0].index] || '';
                                        
                                        if (numVal) {
                                            footer += numVal;
                                        }
                                        return footer;
                                    }
                                }
                            }
                        }
                    });

                    if(component.get("v.showMonthlyReport")){
                        document.getElementById('js-legend-monthly').innerHTML = plannedChart.generateLegend();
                    }else{
                        document.getElementById('js-legend').innerHTML = plannedChart.generateLegend();
                    }
                }
            }else if (state === "ERROR") {
                component.set("v.showSpinner", false);
                var errors = response.getError();
                console.log('LOG ERROR ' + errors);
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }else{
                component.set("v.showSpinner", false);
            }
        });
        $A.enqueueAction(action);
    }
})