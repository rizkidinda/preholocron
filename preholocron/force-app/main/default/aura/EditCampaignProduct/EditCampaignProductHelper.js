({
    init : function (component, event, helper) {
        component.set("v.showSpinner", true);
        let action = component.get("c.setupData");
        action.setParams({
            'campaignId' : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS"){
                component.set("v.showSpinner", false);
                let result = response.getReturnValue();
                if (result == null) {
                    console.log('LOG null result ');
                    helper.showToast("Error!", "error", "Error occured while loading Product data. Please contact System Administrator for more info.");
                }else {
                    let retVals = JSON.parse( result );
                    let selectedPrdList = [];
                    component.set("v.prodFamList", retVals);
                    if(component.get("v.prodFamList").length > 0){
                        let allProdFam = [];
                        let prodFamList = component.get("v.prodFamList");
                        for(let i = 0 ; i < prodFamList.length ; i++){
                            allProdFam.push(prodFamList[i].prodFamily);
                            let prds = prodFamList[i].productList;
                            for(let j = 0 ; j < prds.length ; j++){
                                let prd = prds[j];
                                if(prd.isSelected){
                                    selectedPrdList.push(prd.Id);
                                }
                            }
                        }        
                        component.set("v.activeSections", allProdFam);   
                        component.set("v.selectedPrdList", selectedPrdList);           
                    }
                }
            }else if (state === "ERROR") {
                component.set("v.showSpinner", false);
                let errors = response.getError();
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

    updateSelectedPrd : function(component, event, helper){
        let dataTableCmps = component.find("prdTable");
        let tableData = component.get("v.prodFamList");
        let selectedPrdList = [];
        
        if (Array.isArray(dataTableCmps)) {
            for (let i = 0; i < dataTableCmps.length; i++) {
                let dataTableCmp = dataTableCmps[i];
                let data = tableData[i].productList;
                let selectedRows = dataTableCmp.getSelectedRows();
                if(selectedRows.length > 0){
                    for (var j = 0; j < selectedRows.length; j++) {
                        let selectedRow = selectedRows[j];
                        selectedPrdList.push(selectedRow.Id);
                    }
                }
            }
            component.set("v.selectedPrdList",selectedPrdList);
        }
    },

    saveSelectedPrd : function(component, event, helper){
        component.set("v.showSpinner", true);
        let selectedPrdList = component.get("v.selectedPrdList");
        let action = component.get("c.saveData");
        let selectedPrdListStr = JSON.stringify(selectedPrdList);
        action.setParams({
            'campaignId' : component.get("v.recordId"),
            'productIdStr' : JSON.stringify(selectedPrdList) 
        });
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS"){
                component.set("v.showSpinner", false);
                var result = response.getReturnValue();
                if (result == null) {
                    console.log('LOG null result ');
                    helper.showToast("Error!", "error", "Something went wrong. Please contact the administrator.");
                }else{
                    $A.get("e.force:closeQuickAction").fire();
                    helper.showToast("Success!", "success", "Data has been saved successfully.");
                    $A.get('e.force:refreshView').fire();
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

})