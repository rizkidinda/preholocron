/*
Type Name: XenditOppApproval_TriggerHandler
Author: Xendit
Created Date: 27/09/2022
Description: Opportunity Approval Apex Trigger Handler
Change History:
27/09/2022      BCX Admin       Created
08/03/2023      GDevita         SFDC-133: Pricing Approval revamp
08/01/2024      RizkiA          SFDC-489: Update L3 Mapping
*/

public class XenditOppApproval_TriggerHandler{

    /*
    Method Name: beforeInsert
    Description: function for Before Insert Trigger
    */
    public static void beforeInsert(List<Opportunity_Approval__c> listNew){
        updateApproverManagers(listNew, null);
    }

    /*
    Method Name: beforeUpdate
    Description: function for Before Update Trigger
    */
    public static void beforeUpdate(List<Opportunity_Approval__c> listNew, Map<Id, Opportunity_Approval__c> mapOld){
        updateApproverManagers(listNew, mapOld);
        updateFinalApproverandRejecter(listNew);
    }
    
    /*
    Method Name: afterUpdate
    Description: function for After Update Trigger
    */
    public static void afterUpdate(List<Opportunity_Approval__c> listNew){
        set<id> targetObjectIds=new set<id>();
        system.debug('$$$entered');
        for (Opportunity_Approval__c  rec: listNew) {
            if (rec.Approval_Step__c>0 && !rec.History_Updated__c){
                targetObjectIds.add(rec.id);
            } 
        }
        if(!targetObjectIds.isEmpty()){
            XenditOppApproval_TriggerHandler.updateApprovalHistory(targetObjectIds);
        }
    }

    /************************************ Helper Methods ************************************/

    /*
    Method Name: getPricingApprRecordTypeId
    Description: return Pricing Approval record type id
    */
    public static String getPricingApprRecordTypeId()
    {
        return Schema.SObjectType.Opportunity_Approval__c.getRecordTypeInfosByName().get('Pricing Approval').getRecordTypeId();
    }

    /*
    Method Name: updateApprovalHistory
    Description: stamp approval details for every approval steps
    */
    @future
    public static void updateApprovalHistory(set<id> TargetObjectIds){
        list<Opportunity_Approval__c > updateList=new list<Opportunity_Approval__c  >();
        set<id> instanceIds=new set<id>();
        map<id,ProcessInstance> processInstanceMap=new map<id,ProcessInstance>();
        map<id,list<ProcessInstanceStep>> processInstanceStepMap=new  map<id,list<ProcessInstanceStep>>();
        map<id,string> userMap=new map<id,string>();
        for(user u:[select id, firstname,lastname from user]){
            userMap.put(u.id,u.firstname+' '+u.lastname);
        }
        system.debug('$$$targetob'+TargetObjectIds);
        for(ProcessInstance p: [select id,TargetObjectId from processInstance where TargetObjectId=:TargetObjectIds order by CreatedDate Desc ]){
            if(!processInstanceMap.containsKey(p.TargetObjectId)){
                instanceIds.add(p.id);
                processinstanceMap.put(p.TargetObjectId,p);
            }
        }
        system.debug('$$$processInstanceMap'+processInstanceMap);
        for(ProcessInstanceStep rec: [select id, stepstatus,processInstanceId,comments,actorId from ProcessInstanceStep where processInstanceId=:instanceIds order by createdDate asc]){
            list<ProcessInstanceStep>templist=new list<ProcessInstanceStep>();
            if(processInstanceStepMap.containsKey(rec.processInstanceId))
                templist=processInstanceStepMap.get(rec.processInstanceId);
            templist.add(rec);
            processInstanceStepMap.put(rec.processInstanceId,templist);
        }
        system.debug('$$$processInstanceStepMap'+processInstanceStepMap);
        
        for(id targetObj:processinstanceMap.keyset()){
            Opportunity_Approval__c app=new Opportunity_Approval__c();
            app.id=targetObj;
            id processInstanceId=processinstanceMap.get(targetObj).id;
            if(processInstanceStepMap.containsKey(processInstanceId)){
                 integer counter=0;
                for(ProcessInstanceStep step:processInstanceStepMap.get(processInstanceId)){
                    if(step.StepStatus!='Started'){
                        string username=userMap.containsKey(step.ActorId)?userMap.get(step.actorId):step.actorId;
                        string message='Step '+counter+' : Approver - '+username+' ; '+'Status - '+step.stepstatus+' ; '+'Comments - '+step.Comments;
                        app.Approval_History__c=app.Approval_History__c==null?message:app.Approval_History__c+'<br>'+message;
                        app.History_Updated__c=true;
                    }
                    counter=counter+1;
                }
                system.debug('$$$'+app);
                updateList.add(app);
            }
        }
        if(!updateList.isEmpty()){
            TriggerBypassUtility.opportunityApprovalTriggerBypass = true;
            update updateList;
            TriggerBypassUtility.opportunityApprovalTriggerBypass = false;
        }
    }

    /*
    Method Name: updateApproverManagers
    Description: stamp approver manager based on opportunity owner approver level
    */
    public static void updateApproverManagers(List<Opportunity_Approval__c> listNew, Map<Id, Opportunity_Approval__c> mapOld){
        List<Opportunity_Approval__c> updateOppApprovalList = new List<Opportunity_Approval__c>();
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        String userRoleNames;
        for(Opportunity_Approval__c appr: listNew){
            Boolean isNew = mapOld == null;
            Boolean isOppOwnerUpdate = mapOld != null && mapOld.get(appr.Id).Opportunity_Owner_Update__c != appr.Opportunity_Owner_Update__c && appr.Opportunity_Owner_Update__c;
            if(isNew || isOppOwnerUpdate){
                updateOppApprovalList.add(appr);
                oppMap.put(appr.Opportunity__c, new Opportunity());
            }   
        }

        for(Opportunity opp : [SELECT Id, Owner.Approval_Level__c, Owner.ManagerId, Owner.Manager.ManagerId, Owner.Manager.Manager.ManagerId, Account.Country_of_HQ__c, Owner.UserRole.Name FROM Opportunity WHERE Id IN :oppMap.keySet()]){
            oppMap.put(opp.Id, opp);
            userRoleNames = opp.Owner.UserRole.Name;
        }

        if(updateOppApprovalList.size()>0){
            String setCountry;
            if(userRoleNames.contains('Reg')){
                setCountry = 'Reg';
            }else{
                setCountry = 'ID';
            }
            L3_Approver_Default__mdt L3ApprovalList = [SELECT Assigned_Approver__c, Country__c FROM L3_Approver_Default__mdt WHERE Country__c = :setCountry LIMIT 1];            
            
            //get User of the L3 ID Approver
            User l3IDApprover = [SELECT Id, name FROM User WHERE FederationIdentifier = :L3ApprovalList.Assigned_Approver__c LIMIT 1];

            for(Opportunity_Approval__c appr : updateOppApprovalList){
                Opportunity masterOpp = oppMap.get(appr.Opportunity__c);
                //if owner's approver level = empty -> level 0
                String lvl1Manager = String.isBlank(masterOpp.Owner.Approval_Level__c) ? masterOpp.Owner.ManagerId : null;
                String lvl2Manager = getL2Manager(masterOpp.Owner.Approval_Level__c, masterOpp.Owner.ManagerId, masterOpp.Owner.Manager.ManagerId, l3IDApprover.Id);
                String lvl3Manager = (String.isBlank(masterOpp.Owner.Approval_Level__c) || masterOpp.Owner.Approval_Level__c == '1' || masterOpp.Owner.Approval_Level__c == '2') && (String.isBlank(masterOpp.Owner.UserRole.Name) || (!String.isBlank(masterOpp.Owner.UserRole.Name) && !masterOpp.Owner.UserRole.Name.contains('PH'))) ? l3IDApprover.Id : null;
                
                appr.L1_Manager__c = lvl1Manager;
                appr.L2_Manager__c = lvl2Manager;
                appr.L3_Manager__c = lvl3Manager;
                appr.Opportunity_Owner_Update__c = false;
            }
        }
    }

    /*
    Method Name: updateApproverRejecter
    Description: stamp approver and rejecter on opp approval level
    */
    public static void updateFinalApproverandRejecter(List<Opportunity_Approval__c> listNew){
        Map<Id,Opportunity_Approval__c> oppApprovalMap = new Map<Id,Opportunity_Approval__c>();
        Map<Id, Opportunity_Approval__c> updateOppApprovalMap = new Map<Id, Opportunity_Approval__c>();
        for(Opportunity_Approval__c appr: listNew){
            oppApprovalMap.put(appr.Id, appr);
        }

        for(ProcessInstance pi : [SELECT Id,TargetObjectId, LastActorId, Status from processInstance where TargetObjectId IN :oppApprovalMap.keySet() order by CreatedDate ASC]){
            Opportunity_Approval__c getOppAppr = oppApprovalMap.containsKey(pi.TargetObjectId) ? oppApprovalMap.get(pi.TargetObjectId) : null;
            if(getOppAppr != null && getOppAppr.Status__c == 'Approved' && pi.Status == 'Approved'){
                updateOppApprovalMap.put(pi.TargetObjectId, new Opportunity_Approval__c(Id = pi.TargetObjectId, Final_Approver__c = pi.LastActorId));
            }else if(getOppAppr != null && getOppAppr.Status__c == 'Rejected' && pi.Status == 'Rejected'){
                updateOppApprovalMap.put(pi.TargetObjectId, new Opportunity_Approval__c(Id = pi.TargetObjectId, Rejecter__c = pi.LastActorId));
            }
        }

        for(Opportunity_Approval__c appr: listNew){
            if(updateOppApprovalMap.containsKey(appr.Id)){
                Opportunity_Approval__c getOpprApprFromInstance = updateOppApprovalMap.get(appr.Id);
                appr.Final_Approver__c = getOpprApprFromInstance.Final_Approver__c;
                appr.Rejecter__c = getOpprApprFromInstance.Rejecter__c;
            }
        }
    }

    @InvocableMethod(label='Validate Approval Record')
    public static List<Boolean> validateApprovalRecord(List<String> apprId){
        List<Boolean> returnVal = new List<Boolean>();
        returnVal.add(Approval.isLocked(apprId[0]));
        return returnVal;
    }

    public static Id getL2Manager(String ownerLevel, Id Manager1Id, Id Manager2Id, Id l3ManagerId){
        Id returnVal = null;
        if(String.isBlank(ownerLevel)){ //level 0
            if(Manager2Id != null && Manager2Id != l3ManagerId){
                returnVal = Manager2Id;
            }
            else if(Manager2Id == l3ManagerId){
                returnVal = Manager1Id;
            }
        }else if(!String.isBlank(ownerLevel) && ownerLevel == '1' && Manager1Id != l3ManagerId){
            returnVal = Manager1Id;
        }
        return returnVal;
    }
    
}