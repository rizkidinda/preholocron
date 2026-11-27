/**
 * @description       : 
 * @group             : 
 * @last modified on  : 27-11-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
public without sharing class HIRO_MonthlyOppCalculationBatch implements Database.Batchable<sObject>, Database.Stateful{
    public String query;
    
    public HIRO_MonthlyOppCalculationBatch(String query) {
        this.query = query;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext ctx, List<Opportunity> scope) {
        List<Opportunity> oppToUpdate = new List<Opportunity>();
        if (scope.size() > 0) {
            Map<String, HIRO_Percentage__c> hiroMap = new Map<String, HIRO_Percentage__c>();
            for (HIRO_Percentage__c hiro : [SELECT External_Id__c, HIRO_Percentage__c, HIRO__c FROM HIRO_Percentage__c WHERE Date__c = THIS_MONTH]) {
                hiroMap.put(hiro.External_Id__c, hiro);
            }
	
            system.debug('***Check map test: '+ ((String)JSON.serialize(hiroMap)));
            for (Opportunity opp : scope) {
                String mapKey = opp.Pipeline_Source__c + '_' + opp.StageName;
                system.debug('***Check test class: '+ mapKey);
                if (hiroMap.get(mapKey) != null && hiroMap.get(mapKey).HIRO__c) {
                    Opportunity oppUp = new Opportunity();
                    oppUp.Id = opp.Id;
                    oppUp.HIRO_Stage__c = opp.StageName;
                    oppUp.Marked_As_HIRO_Before__c = hiroMap.get(mapKey).HIRO__c;
                    if (opp.StageName == 'Qualification') {
                        oppUp.HIRO_Stage_Date__c = opp.Qualification_Date__c;
                    } if (opp.StageName == 'Discovery') {
                        oppUp.HIRO_Stage_Date__c = opp.Discovery_Date__c;
                    } if (opp.StageName == 'Evaluation') {
                        oppUp.HIRO_Stage_Date__c = opp.Evaluation_Date__c;
                    } if (opp.StageName == 'Negotiation') {
                        oppUp.HIRO_Stage_Date__c = opp.Negotiation_Date__c;
                    } if (opp.StageName == 'Contracting') {
                        oppUp.HIRO_Stage_Date__c = opp.Onboarding_Contracting_Date__c;
                    } if (opp.StageName == 'Integration') {
                        oppUp.HIRO_Stage_Date__c = opp.Integration_Date__c;
                    } if (opp.StageName == 'Activation') {
                        oppUp.HIRO_Stage_Date__c = opp.Activation_Date__c;
                    }
                    oppToUpdate.add(oppUp);
                } else if (hiroMap.get(mapKey) != null && !hiroMap.get(mapKey).HIRO__c) {
                    Opportunity oppUp = new Opportunity();
                    oppUp.Id = opp.Id;
                    oppUp.HIRO_Stage__c = null;
                    oppUp.HIRO_Stage_Date__c = null;
                    oppToUpdate.add(oppUp);
                }
            }
        }

        if (oppToUpdate.size() > 0) {
            TriggerBypassUtility.opportunityTriggerBypass = true;
            update oppToUpdate;
        }
    }

    public void finish(Database.BatchableContext ctx) {

    }
}