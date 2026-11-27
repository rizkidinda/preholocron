({
    doInit: function(component, event, helper)
    {
        helper.init(component, event, helper);
    },
    
    save: function(component, event, helper)
    {
        helper.validateValue(component, event, helper);
        if(component.get("v.error")!=true)
            helper.saveHelper(component, event, helper);
    },
    deleteRamp: function(component, event, helper) 
    { 
        component.set("v.showSpinner", true);
        var rowIndex=event.getSource().get("v.name");
        var action = component.get("c.deleteRampRecord");
        action.setParams({
            'index' : rowIndex,
            'data' : component.get("v.displayData")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS")
            {
                var result = response.getReturnValue();
                component.set("v.displayData",result);
                if (result.resultMessage.includes('error')) {
                    console.log('LOG null result ');
                    helper.showToast("Error!", "error", "Unexpected Error Occured. Contact Admin!");
                }else {
                    helper.showToast("Success!", "success", "Successfully deleted ramp record");
                }
            } 
        });
        $A.enqueueAction(action);
        component.set("v.showSpinner", false);
    },
    addRamp: function(component, event, helper) 
    {
        component.set("v.showSpinner", true);
        var action = component.get("c.addRampRecord");
        action.setParams({
            'data' : component.get("v.displayData"),
            'recordId': component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS")
            {
                var result = response.getReturnValue();
                component.set("v.displayData",result);
                if (result.resultMessage.includes('error')) {
                    console.log('LOG null result ');
                    helper.showToast("Error!", "error", "Unexpected Error Occured. Contact Admin!");
                }
            } 
        });
        $A.enqueueAction(action);
        component.set("v.showSpinner", false);
    },
    refreshRamp: function(component, event, helper) 
    { 
        component.set("v.showSpinner", true);
        var action = component.get("c.refreshRampRecord");

        let currentData = component.get("v.displayData");
        let isOverrideDefaultRamp = component.get("v.isOverrideAutomatedValue") == "Yes" ? true : false;
        currentData.opp.Is_Override_Default_Ramp__c = isOverrideDefaultRamp;
        component.set("v.displayData", currentData);

        action.setParams({
            'data' : component.get("v.displayData")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS")
            {
                var result = response.getReturnValue();
                console.log('result refresh ramp : ');
                console.log(result);
                component.set("v.displayData",result);
                console.log('result refresh ramp 2 ');
                console.log(component.get('v.displayData'));
            } 
        });
        $A.enqueueAction(action);
        component.set("v.showSpinner", false);
    },

    updateAutomatedValue: function(component, event, helper){

        let currentData = component.get("v.displayData");
        let isOverrideDefaultRamp = component.get("v.isOverrideAutomatedValue") == "Yes" ? true : false;
        if(!isOverrideDefaultRamp){
            component.set("v.showSpinner", true);
            var action = component.get("c.refreshRampRecord");
            currentData.opp.Is_Override_Default_Ramp__c = isOverrideDefaultRamp;
            component.set("v.displayData", currentData);

            action.setParams({
                'data' : component.get("v.displayData")
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS")
                {
                    var result = response.getReturnValue();
                    console.log('result refresh ramp : ');
                    console.log(result);
                    component.set("v.displayData",result);
                    console.log('result refresh ramp 2 ');
                    console.log(component.get('v.displayData'));
                } 
            });
            $A.enqueueAction(action);
            component.set("v.showSpinner", false);
        }
    }
})