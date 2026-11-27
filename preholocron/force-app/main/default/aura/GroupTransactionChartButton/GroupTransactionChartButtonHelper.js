({
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