({
    doInit: function(component, event, helper)
    {
        helper.init(component, event, helper);
    },

    save: function(component, event, helper)
    {
        helper.saveData(component,event,helper);
    },

    handleEdit : function(component, event, helper){
        helper.showEditMode(component, event)
    },

    handleCommit : function(component, event, helper){
        if (confirm('This action will commit all TPV for this month. Proceed?')) {
            helper.commitTPV(component, event, helper);
        }
    },

    handleCancel : function(component, event, helper){
        helper.showViewMode(component, event, helper);
    },

    inputUpdateCSS: function(component, event, helper){
        let currRowIndex = event.getSource().get("v.label");
        helper.applyCSS(component, event, helper, currRowIndex);
    },

    inputSubUpdateCSS: function(component, event, helper){
        let currRowIndex = event.getSource().get("v.label");
        helper.applySubAccCSS(component, event, helper, currRowIndex);
    },

    onPageValChange : function (component, event, helper){
        var sObjectList = component.get("v.subAccountforecastList");
        var pageSize = component.find("recNumId").get("v.value"); 
        component.set("v.pageSize", pageSize);

        var end = pageSize-1;
        var start = 0;

        var Paginationlist = [];
        var counter = 0;
        
        if( !$A.util.isEmpty(sObjectList) ){
            for(var i=start; i<pageSize; i++){
                if( sObjectList.length > i ){
                    Paginationlist.push(sObjectList[i]);
                    counter ++ ;
                }
            }
            component.set("v.startPage",start);
            component.set("v.endPage",end);
            component.set('v.PaginationList', Paginationlist);                    
        }
    },

    previous : function (component, event, helper){
        helper.previous(component, event);
    },

    next : function (component, event, helper){
        helper.next(component, event);
    },

    onPageValChange : function (component, event, helper){
        var sObjectList = component.get("v.subAccountforecastList");
        var pageSize = component.find("recNumId").get("v.value"); 
        component.set("v.pageSize", pageSize);

        var end = pageSize-1;
        var start = 0;

        var Paginationlist = [];
        var counter = 0;
        
        if( !$A.util.isEmpty(sObjectList) ){
            for(var i=start; i<pageSize; i++){
                if( sObjectList.length > i ){
                    Paginationlist.push(sObjectList[i]);
                    counter ++ ;
                }
            }
            component.set("v.startPage",start);
            component.set("v.endPage",end);
            component.set('v.PaginationList', Paginationlist);                    
        }
    },
})