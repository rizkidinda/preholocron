/**
 * @description       : 
 * @group             : 
 * @last modified on  : 18-01-2024
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
({
    init : function (component, event, helper) {
        component.set("v.showSpinner", true);
        
        var action = component.get("c.getCurrentUserProfileName");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var userProfile = response.getReturnValue();
                console.log("User Profile: " + userProfile);
                
                if (userProfile.includes('Sales Manager') || userProfile.includes('Ops') || userProfile.includes('System Administrator')) {
                    component.set("v.showCOGS", true);
                }
            } else {
                console.error("Error calling Apex method: " + state);
            }
        });
        $A.enqueueAction(action);

        var action = component.get("c.getApprovalData");
        console.log('action start');
        action.setParams({
            'approvalId' : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                component.set("v.showSpinner", false);
                var result = response.getReturnValue();
                if (result == null) {
                    console.log('LOG null result ');
                    helper.showToast("Error!", "error", "Opportunity Approval data not found!");
                }else {
                    let retVals = JSON.parse(result);
                    console.log('result : ');
                    console.log(retVals);
                    if(retVals.approvalObj){
                        component.set("v.approvalObject", retVals.approvalObj);
                    }

                    if(retVals.oppList){
                        component.set("v.oppProdList", retVals.oppList);
                    }

                    if(retVals.rateOriCurrency){
                        component.set("v.rateOriCurrency", retVals.rateOriCurrency);
                    }

                    if(retVals.headlineTotalRevenue){
                        component.set("v.headlineTotalRevenue", retVals.headlineTotalRevenue);
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