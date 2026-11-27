({
    init : function (component, event, helper) {
        let today = new Date();
        let firstDate = 1;
        let endDate = 9;
        component.set('v.currentPeriodStart', helper.updateDateFormat(today.getFullYear() + "-" + (today.getMonth() + 1) + "-" + firstDate));
        component.set('v.currentPeriodEnd', helper.updateDateFormat(today.getFullYear() + "-" + (today.getMonth() + 1) + "-" + endDate));
        component.set('v.nextPeriodStart', helper.updateDateFormat((today.getMonth() + 1 == 12 ? today.getFullYear() + 1 : today.getFullYear()) + "-" + (today.getMonth() + 1 == 12 ? 1 : today.getMonth() + 2) + "-" + firstDate));
        component.set('v.nextPeriodEnd', helper.updateDateFormat((today.getMonth() + 1 == 12 ? today.getFullYear() + 1 : today.getFullYear()) + "-" + (today.getMonth() + 1 == 12 ? 1 : today.getMonth() + 2) + "-" + endDate));
        component.set('v.currMonthInt', today.getMonth() + 1);
        component.set('v.currYearInt', today.getFullYear());
        component.set('v.currDatePeriod', ((today.getDate() >= firstDate) && (today.getDate() <= endDate)));
        component.set("v.showSpinner", true);
        var action = component.get("c.setupData");
        action.setParams({
            'AccountId' : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                component.set("v.showSpinner", false);
                var result = response.getReturnValue();
                if (result == null) {
                    console.log('LOG null result ');
                    helper.showToast("Error!", "error", "Forecasting data not found!");
                }else {
                    let retVals = JSON.parse( result );
                    component.set("v.estAnnualTPV", retVals.estAnnualTPV);
                    component.set("v.accType",retVals.accType);
                    component.set("v.strHistory",retVals.strHistory);
                    if(retVals.forecastDetails != null && retVals.forecastDetails.length > 0){
                        let totalFinalForecastTPVUSD = 0;
                        let totalDisplayTPVUSD = 0;
                        let totalSalesInputperMonthTPVUSD = [];
                        component.set("v.forecastList",retVals.forecastDetails);
                        retVals.forecastDetails.forEach(element => {
                            //final forecast total
                            if(element.allTotalWrapper.totalForecastTPV){
                                totalFinalForecastTPVUSD += element.allTotalWrapper.totalForecastTPV;
                            }

                            //display TPV total
                            if(element.allTotalWrapper.totalDisplayTPV){
                                totalDisplayTPVUSD += element.allTotalWrapper.totalDisplayTPV;
                            }
                            
                            //sales team approval total
                            if(element.tempTPVDisplay){
                                totalSalesInputperMonthTPVUSD.push(element.tempTPVDisplay);
                            }else{
                                totalSalesInputperMonthTPVUSD.push(null);
                            }
                        });
                        component.set("v.totalFinalForecastTPVUSD", totalFinalForecastTPVUSD);
                        component.set("v.totalDisplayTPVUSD", totalDisplayTPVUSD);
                        component.set("v.totalSalesInputperMonthTPVUSD", totalSalesInputperMonthTPVUSD);

                        let totalSalesInputAllMonth = totalSalesInputperMonthTPVUSD.reduce((a, b) => a + b, 0);
                        component.set("v.totalSalesInputAllMonth", totalSalesInputAllMonth);
                        component.set("v.totalMasterTPV", totalSalesInputAllMonth);
                    }

                    if(retVals.accType == 'XP MASTER'){
                        helper.getSubAccount(component, event, helper);
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
    },

    getSubAccount : function (component, event, helper) {
        component.set("v.showSpinner", true);
        var action = component.get("c.setupSubAccountData");
        action.setParams({
            'AccountId' : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                component.set("v.showSpinner", false);
                component.set("v.subAccountforecastList",[]);
                var result = response.getReturnValue();
                if (result == null) {
                    console.log('LOG null result ');
                    //helper.showToast("Error!", "error", "Sub Account Forecasting data not found!");
                }else {
                    let retVals = JSON.parse( result );
                    component.set("v.subAccountforecastList",retVals);

                    //pagination
                    let pageSize = component.get("v.pageSize");
                    component.set("v.startPage",0);
                    component.set("v.endPage",pageSize-1);

                    let pgList = [];
                    let totalRecNum = retVals.length;

                    if( totalRecNum == 0 ){
                        component.set('v.PaginationList', pgList );  
                    }else{
                        let totalRec = Number(totalRecNum)-Number(1);
                        component.set("v.totalRecords", totalRec );              
                        for(let i=0; i< pageSize; i++){
                            if(totalRecNum > i){
                                pgList.push(retVals[i]);    
                            }     
                        }
                        component.set('v.PaginationList', pgList);    
                    }

                    let totalSalesInputperMonthTPVUSD = component.get("v.totalSalesInputperMonthTPVUSD");
                    if(!totalSalesInputperMonthTPVUSD || totalSalesInputperMonthTPVUSD.length == 0){
                        let tempArr = [];
                        for(var i = 0; i < 12; i++){
                            tempArr.push(null);
                        }
                        component.set("v.totalSalesInputperMonthTPVUSD",tempArr);
                    }

                    let totalSalesInputperMonthTPVUSD2 = component.get("v.totalSalesInputperMonthTPVUSD");
                    for(var i = 0; i < 12; i++){
                        let currTotalSalesInput = totalSalesInputperMonthTPVUSD2[i] ? totalSalesInputperMonthTPVUSD2[i] : 0;
                        let newVal = 0;
                        retVals.forEach(element => {
                            if(element.subAccForecastDetails[i].tempTPVDisplay){
                                newVal += element.subAccForecastDetails[i].tempTPVDisplay;
                            }
                        });

                        if(newVal > 0){
                            newVal += currTotalSalesInput;
                            totalSalesInputperMonthTPVUSD2[i] = newVal;
                        }
                    }

                    component.set("v.totalSalesInputperMonthTPVUSD", totalSalesInputperMonthTPVUSD2);

                    let totalSalesInputAllMonth = totalSalesInputperMonthTPVUSD2.reduce((a, b) => a + b, 0);
                    component.set("v.totalSalesInputAllMonth", totalSalesInputAllMonth);
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
    },

    saveData: function (component, event, helper) {
        let forecastList = component.get("v.forecastList");
        let subAccountforecastList = component.get("v.PaginationList"); //v.subAccountforecastList
        let updateSubAccForecastList = [];
        if(subAccountforecastList && subAccountforecastList.length > 0){
            for(let x in subAccountforecastList){
                if(subAccountforecastList[x].subAccForecastDetails && subAccountforecastList[x].subAccForecastDetails.length > 0){
                    const res = subAccountforecastList[x].subAccForecastDetails.filter(val => val.tempSalesInput === true);
                    for(let y in res){
                        updateSubAccForecastList.push(res[y]);
                    }
                    
                }
            }
        }
        var action = component.get("c.saveForecastData");
        component.set("v.showSpinner", true);
        action.setParams({
            'forecastList' : JSON.stringify(forecastList),
            'subAccForecastList' : updateSubAccForecastList && updateSubAccForecastList.length > 0 ? JSON.stringify(updateSubAccForecastList) : ''
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                component.set("v.showSpinner", false);
                var result = response.getReturnValue();
                if (result == null) {
                    console.log('LOG null result ');
                    helper.showToast("Error!", "error", "Something went wrong. Please contact the administrator.");
                }else{
                    helper.showToast("Success!", "success", "Data has been saved successfully.");
                    helper.showViewMode(component, event, helper);
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
    },

    commitTPV : function (component, event, helper) {
        let forecastList = component.get("v.forecastList");
        let subAccountforecastList = component.get("v.subAccountforecastList");
        let currMonthInt = component.get("v.currMonthInt");
        let updateSubAccForecastList = [];
        if(subAccountforecastList && subAccountforecastList.length > 0){
            for(let x in subAccountforecastList){
                if(subAccountforecastList[x].subAccForecastDetails && subAccountforecastList[x].subAccForecastDetails.length > 0){
                    const res = subAccountforecastList[x].subAccForecastDetails.filter(val => val.month === currMonthInt);
                    for(let y in res){
                        updateSubAccForecastList.push(res[y]);
                    }
                }
            }
        }

        var action = component.get("c.commitForecastData");
        component.set("v.showSpinner", true);
        action.setParams({
            'forecastList' : JSON.stringify(forecastList),
            'subAccForecastList' : updateSubAccForecastList && updateSubAccForecastList.length > 0 ? JSON.stringify(updateSubAccForecastList) : '',
            'currMonthInt' : currMonthInt
            
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                component.set("v.showSpinner", false);
                var result = response.getReturnValue();
                if (result == null) {
                    console.log('LOG null result ');
                    helper.showToast("Error!", "error", "Something went wrong. Please contact the administrator.");
                }else{
                    helper.showToast("Success!", "success", "Data has been saved successfully.");
                    helper.showViewMode(component, event, helper);
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
    },

    showEditMode : function ( component, event ){
        component.set("v.showEdit", true);

        let curGrp = component.find("div-grp-save");
        let curGrp2 = component.find("div-grp-save2");
        if( curGrp ){
            if( $A.util.hasClass(curGrp,"slds-hide") ){
                $A.util.removeClass(curGrp,"slds-hide");
            }
        }

        if( curGrp2 ){
            if( $A.util.hasClass(curGrp2,"slds-hide") ){
                $A.util.removeClass(curGrp2,"slds-hide");
            }
        }

         //Edit  
         let editGrp = component.find("div-grp-edit");
         let editGrp2 = component.find("div-grp-edit2");
         if( editGrp ){
             if( !$A.util.hasClass(editGrp,"slds-hide") ){
                 $A.util.addClass(editGrp,"slds-hide");
             }
         } 

         if( editGrp2 ){
            if( !$A.util.hasClass(editGrp2,"slds-hide") ){
                $A.util.addClass(editGrp2,"slds-hide");
            }
        } 
    },

    showViewMode : function(component, event, helper){
        component.set("v.showEdit", false);
        //Edit  
        let curGrp = component.find("div-grp-edit");
        let curGrp2 = component.find("div-grp-edit2");
        if( curGrp ){
            if( $A.util.hasClass(curGrp,"slds-hide") ){
                $A.util.removeClass(curGrp,"slds-hide");
            }
        }

        if( curGrp2 ){
            if( $A.util.hasClass(curGrp2,"slds-hide") ){
                $A.util.removeClass(curGrp2,"slds-hide");
            }
        }

        let editGrp = component.find("div-grp-save");
        let editGrp2 = component.find("div-grp-save2");
        if( editGrp ){
            if( !$A.util.hasClass(editGrp,"slds-hide") ){
                $A.util.addClass(editGrp,"slds-hide");
            }
        }   

        if( editGrp2 ){
            if( !$A.util.hasClass(editGrp2,"slds-hide") ){
                $A.util.addClass(editGrp2,"slds-hide");
            }
        }   
        this.init(component,event,helper);
    },

    updateDateFormat : function(editDate){
        let updateDate = $A.localizationService.formatDate(editDate, "dd/MM/yyyy");
        return updateDate;
    },

    showToast : function(title, type, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            type: type,
            "title": title,//"Success!",
            "message": message
        });
        toastEvent.fire();
    },

    applyCSS: function(component, event, helper, currRowIndex){
        //apply CSS
        let salesInputs = component.find("salesinput1");
        salesInputs = salesInputs.length? salesInputs : [salesInputs];
        if( !$A.util.hasClass(salesInputs[currRowIndex], 'changeValue') ){
            $A.util.addClass(salesInputs[currRowIndex], 'changeValue');
        }

        //assign sales input value
        let forecastList = component.get("v.forecastList");
        for(let x in forecastList){
            if(x == currRowIndex){
                forecastList[x].tempSalesInput = true;
                let tempDisplayTPV = (forecastList[x].tempTPVDisplay) ? forecastList[x].tempTPVDisplay : null;
                forecastList[x].tempTPVDisplay = tempDisplayTPV;
            }
        }
        component.set("v.forecastList", forecastList);
    },

    applySubAccCSS: function(component, event, helper, currRowIndex){
        let intArray =  currRowIndex.split(":::");
        if(intArray.length == 2){

            //apply CSS
            let salesInputs = component.find('salesinput2');
            let arr0 = parseInt(intArray[0]);
            let arr1 = parseInt(intArray[1]);
            let selectIdx = (arr0 * 12) + arr1; //(0 * 12) + 1 = 1, (1 * 12) + 2 = 14
            salesInputs = salesInputs.length? salesInputs : [salesInputs];
            if( !$A.util.hasClass(salesInputs[selectIdx], 'changeValue') ){
                $A.util.addClass(salesInputs[selectIdx], 'changeValue');
            }
            
            //assign sales input value
            let subAccountforecastList = component.get("v.PaginationList"); //v.subAccountforecastList
            for(let x in subAccountforecastList){
                if(x == intArray[0]){
                    let subAccForecastDetails = subAccountforecastList[x].subAccForecastDetails;
                    for(let y in subAccForecastDetails){
                        if(y == intArray[1]){
                            subAccForecastDetails[y].tempSalesInput = true;
                            let tempDisplayTPV = (subAccForecastDetails[y].tempTPVDisplay) ? subAccForecastDetails[y].tempTPVDisplay : null;
                            subAccForecastDetails[y].tempTPVDisplay = tempDisplayTPV;
                        }
                    }
                }
            }
            component.set("v.PaginationList", subAccountforecastList);
        }
    },

    previous : function(component, event){
        var sObjectList = component.get("v.subAccountforecastList");
        var end = component.get("v.endPage");
        var start = component.get("v.startPage");
        var pageSize = component.get("v.pageSize");
        var Paginationlist = [];
        var counter = 0;
        
        if(!$A.util.isEmpty(sObjectList)){
            for(var i= start-pageSize; i < start ; i++){
                if(i > -1){
                    Paginationlist.push(sObjectList[i]);
                    counter ++;
                }else{
                    start++;
                }
            } 
            start = start - counter;
            end = end - counter;
            component.set("v.startPage",start);
            component.set("v.endPage",end);
            component.set('v.PaginationList', Paginationlist);            
        }
    },

    next : function(component, event){
        var sObjectList = component.get("v.subAccountforecastList");
        var end = component.get("v.endPage");
        var start = component.get("v.startPage");
        var pageSize = component.get("v.pageSize");
        var Paginationlist = [];
        
        if(!$A.util.isEmpty(sObjectList)){
            var cnt = 0;
            var itrStart = Number(end)+Number(1);
            var itrEnd = Number(end)+Number(pageSize)+Number(1);
            for(var i=itrStart; i<itrEnd; i++){
                if(sObjectList.length > i){
                    Paginationlist.push(sObjectList[i]);
                    cnt++;
                }
                
            }   
            end = Number(end*1) + Number(cnt*1);
            start = Number(start*1) + Number(cnt*1);

            component.set("v.startPage",start);
            component.set("v.endPage",end);
            component.set('v.PaginationList', Paginationlist);            
        }
    }, 
})