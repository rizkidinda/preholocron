({
    init : function (component, event, helper) {
        component.set("v.showSpinner", true);
        var action = component.get("c.setupData");
        action.setParams({
            'recordId' : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS")
            {
                var result = response.getReturnValue();
                if (result == null) {
                    console.log('LOG null result ');
                    helper.showToast("Error!", "error", "Opportunity not found!");
                }else {
                    component.set("v.displayData", result);
                    if(result.opp.Is_Override_Default_Ramp__c){
                        console.log('isOverrideAutomatedValue true');
                        component.set("v.isOverrideAutomatedValue","Yes");
                        console.log('aaa');
                        component.find('automateDefaultRamp').set('v.value','Yes');
                        console.log('bbb');
                    }else{
                        console.log('isOverrideAutomatedValue false');
                        component.set("v.isOverrideAutomatedValue","No");
                        console.log('aaa');
                        component.find('automateDefaultRamp').set('v.value','No');
                        console.log('bbb');
                    }
                    var data=component.get("v.displayData");
                }
            } 
            else if (state === "INCOMPLETE") { 
                // do something
            }else if (state === "ERROR") {
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
            }
            component.set("v.showSpinner", false);
            var tableHeaderList=["Transaction Date","Month","Default","Adjusted Value(%)"];
            tableHeaderList.push(" ");
            component.set("v.tableHeader",tableHeaderList);
        });
        $A.enqueueAction(action);
    },
    saveHelper : function (component, event, helper) {
        component.set("v.showSpinner", true);
        let currentData = component.get("v.displayData");
        let isOverrideDefaultRamp = component.get("v.isOverrideAutomatedValue") == "Yes" ? true : false;
        currentData.opp.Is_Override_Default_Ramp__c = isOverrideDefaultRamp;
        component.set("v.displayData", currentData);
        
        var action = component.get("c.updateData");
        action.setParams({
            'data' : component.get("v.displayData")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS")
            {
                var result = response.getReturnValue();
                component.set("v.displayData",result);
                if (result.resultMessage.includes('successfully')){
                    helper.showToast("Success!", "success", result.resultMessage);
                } else if (result.resultMessage.includes('Error')){
                    helper.showLongerToast("Error!", "error", result.resultMessage);
                }
                
            } 
            component.set("v.showSpinner", false);
        });
        $A.enqueueAction(action);
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
    showLongerToast : function(title, type, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            type: type,
            "title": title,//"Success!",
            "message": message,
            mode: 'sticky'
        });
        toastEvent.fire();
    },
    validateValue: function(component, event, helper)
    {
        var dataRec=component.get("v.displayData");
        var oppRampSize=dataRec.rampListSize;
        var message='';
        var highervalue=0;
        var lastRowPer=0;
        component.set("v.error",false);
        for(let i=1;i<oppRampSize;i++){
            var previousIndex=i-1;
            var value1=dataRec.oppRampList[i].Adjusted_Percentage__c/100; 
            var value2=dataRec.oppRampList[previousIndex].Adjusted_Percentage__c/100;
            if(value2>highervalue)highervalue=value2;
            var highervalper=highervalue*100;
            if(value1 < highervalue){
                if(message=='')
                    message="Month: "+ dataRec.oppRampList[i].Month__c+" Adjusted value ("+dataRec.oppRampList[i].Adjusted_Percentage__c+"%) must be greater than highest previous value ("+highervalper+"%).";
                else
                    message=message+"\n"+"Month: "+ dataRec.oppRampList[i].Month__c+" Adjusted value ("+dataRec.oppRampList[i].Adjusted_Percentage__c+"%) must be greater than highest previous value ("+highervalper+"%).";
                component.set("v.error",true);
            }
            lastRowPer=value1*100;
        }
        if(lastRowPer!=100){
            message=message!=''? message+'\n'+'Last row should be 100%':'Last row should be 100%';
            component.set("v.error",true);
        }
        helper.showLongerToast("Error!", "error", message);
        component.set("v.displayData",dataRec);
        
    },
    
})