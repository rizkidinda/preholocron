({
    doInit: function(component, event, helper)
    {
        component.set("v.columns",[
            {label:'Product Name', fieldName:'prdName', type: 'text'},
            {label: 'Product Code', fieldName: 'prdCode', type: 'text'}
        ]);
        helper.init(component, event, helper);
    },

    updateSelectedProduct: function(component, event, helper){
        helper.updateSelectedPrd(component, event, helper);
    },

    saveSelectedProduct: function(component, event, helper){
        helper.saveSelectedPrd(component, event, helper);
    }
})