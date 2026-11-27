({
    doInit: function(component, event, helper)
    {
        helper.init(component, event, helper);
    },

    handleEdit : function(component, event, helper){
        helper.showEditMode(component, event)
    },

    handleCancel : function(component, event, helper){
        helper.showViewMode(component, event, helper);
    },

    handleSave : function(component, event, helper){
        helper.saveAccount(component, event, helper);
    }
})