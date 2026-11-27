({
    init : function (component, event, helper) {
        component.set("v.showSpinner", true);
        var action = component.get("c.getOppData");
        console.log('action start');
        action.setParams({
            'OppId' : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                component.set("v.showSpinner", false);
                var result = response.getReturnValue();
                if (result == null) {
                    console.log('LOG null result ');
                    helper.showToast("Error!", "error", "Opportunity data not found!");
                }else {
                    let retVals = JSON.parse(result);
                    console.log('result : ');
                    console.log(retVals);
                    component.set("v.OppObject", retVals);
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

    saveOpportunity : function (component, event, helper) {
        let oppObj = component.get("v.OppObject");
        var action = component.get("c.saveOppData");
        component.set("v.showSpinner", true);
        action.setParams({
            'oppData' : JSON.stringify(oppObj)
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                component.set("v.showSpinner", false);
                var result = response.getReturnValue();
                console.log('result : ' + result);
                if (result == null) {
                    console.log('LOG null result ');
                    helper.showToast("Error!", "error", "Something went wrong. Please contact the administrator.");
                }if (result.includes('Error upon saving the record')) {
                    console.log('LOG error result ');
                    helper.showToast("Error!", "error", result);
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

    showToast : function(title, type, message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            type: type,
            "title": title,//"Success!",
            "message": message
        });
        toastEvent.fire();
    },

    showViewMode : function(component, event, helper){
        component.set("v.showEdit", false);
        //Edit  
        let curGrp = component.find("div-grp-edit");
        if( curGrp ){
            if( $A.util.hasClass(curGrp,"slds-hide") ){
                $A.util.removeClass(curGrp,"slds-hide");
            }
        }

        let editGrp = component.find("div-grp-save");
        if( editGrp ){
            if( !$A.util.hasClass(editGrp,"slds-hide") ){
                $A.util.addClass(editGrp,"slds-hide");
            }
        }   
        this.init(component,event,helper);
    },

    showEditMode : function ( component, event ){
        component.set("v.showEdit", true);

        let curGrp = component.find("div-grp-save");
        if( curGrp ){
            if( $A.util.hasClass(curGrp,"slds-hide") ){
                $A.util.removeClass(curGrp,"slds-hide");
            }
        }

         //Edit  
         let editGrp = component.find("div-grp-edit");
         if( editGrp ){
             if( !$A.util.hasClass(editGrp,"slds-hide") ){
                 $A.util.addClass(editGrp,"slds-hide");
             }
         } 
    },
})