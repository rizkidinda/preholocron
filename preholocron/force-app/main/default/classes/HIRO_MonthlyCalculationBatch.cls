/**
 * @description       : 
 * @group             : 
 * @last modified on  : 15-12-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
public without sharing class HIRO_MonthlyCalculationBatch implements Database.Batchable<sObject>, Database.Stateful {
    public List<HIRO_Percentage__c> hiroToUpsert = new List<HIRO_Percentage__c>();
    public Map<String, Set<Opportunity>> mapNumeratorByPipelineSource = new Map<String, Set<Opportunity>>();
    public Map<String, Set<Opportunity>> mapDenominatorByPipelineSource = new Map<String, Set<Opportunity>>();
    public Map<String, Double> mapHIROPercentage = new Map<String, Double>();
    
    // public HIRO_MonthlyCalculationBatch(String query) {
    //     this.query = query;
    // }

    public Database.QueryLocator start(Database.BatchableContext context) {
        Set<String> monthsCycle6_Pipeline = new Set<String>{
            'Outbound', 
            'Undeclared Interest', 
            'Declared Interest',
            'Events'
        };
        Id parentRecordTypeId = OpportunityHelper.getParentRecordTypeId();
        String query = 'SELECT Id, StageName, IsClosed, Pipeline_Source__c,Qualification_Date__c, Discovery_Date__c, Evaluation_Date__c, Negotiation_Date__c, Onboarding_Contracting_Date__c, Integration_Date__c, Activation_Date__c, Closed_Won_Date__c, Closed_Lost_Date__c  FROM Opportunity WHERE Pipeline_Source__c != null AND ((Pipeline_Source__c IN :monthsCycle6_Pipeline AND Qualification_Date__c = LAST_N_MONTHS:6) OR (Pipeline_Source__c NOT IN :monthsCycle6_Pipeline AND Qualification_Date__c = LAST_N_MONTHS:3)) AND RecordTypeId = :parentRecordTypeId';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext ctx, List<Opportunity> scope) {
        system.debug('***List Size : '+ scope.size());
        for (Opportunity opp : scope) {
            Set<String> mapKeys = new Set<String>();
            String mapKey = opp.Pipeline_Source__c;
            if (opp.Qualification_Date__c != null) {
                mapKey = mapKey + '_Qualification';
                mapKeys.add(mapKey);
                mapKey = opp.Pipeline_Source__c;
            } if (opp.Discovery_Date__c != null) {
                mapKey = mapKey + '_Discovery';
                mapKeys.add(mapKey);
                mapKey = opp.Pipeline_Source__c;
            } if (opp.Evaluation_Date__c != null) {
                mapKey = mapKey + '_Evaluation';
                mapKeys.add(mapKey);
                mapKey = opp.Pipeline_Source__c;
            } if (opp.Negotiation_Date__c != null) {
                mapKey = mapKey + '_Negotiation';
                mapKeys.add(mapKey);
                mapKey = opp.Pipeline_Source__c;
            } if (opp.Onboarding_Contracting_Date__c != null) {
                mapKey = mapKey + '_Contracting';
                mapKeys.add(mapKey);
                mapKey = opp.Pipeline_Source__c;
            } if (opp.Integration_Date__c != null) {
                mapKey = mapKey + '_Integration';
                mapKeys.add(mapKey);
                mapKey = opp.Pipeline_Source__c;
            } if (opp.Activation_Date__c != null) {
                mapKey = mapKey + '_Activation';
                mapKeys.add(mapKey);
                mapKey = opp.Pipeline_Source__c;
            }
            
            for (String stages : mapKeys) {
                //Get Numerator
                if (opp.Closed_Won_Date__c != null) {
                    if(mapNumeratorByPipelineSource.containsKey(stages)) {
                        Set<Opportunity> tempValue = mapNumeratorByPipelineSource.get(stages);
                        tempValue.add(opp);
                        mapNumeratorByPipelineSource.put(stages, tempValue);
                    } else {
                        mapNumeratorByPipelineSource.put(stages, new Set<Opportunity> { opp });
                    }
                }

                //Get Denominator
                //if (opp.IsClosed) {
                    if(mapDenominatorByPipelineSource.containsKey(stages)) {
                        Set<Opportunity> tempValue = mapDenominatorByPipelineSource.get(stages);
                        tempValue.add(opp);
                        mapDenominatorByPipelineSource.put(stages, tempValue);
                    } else {
                        mapDenominatorByPipelineSource.put(stages, new Set<Opportunity> { opp });
                    }
                //}
            }            
        }

        if (mapNumeratorByPipelineSource != null && !mapNumeratorByPipelineSource.isEmpty() && mapDenominatorByPipelineSource != null && !mapDenominatorByPipelineSource.isEmpty()) {
            for (String numeratorKey : mapNumeratorByPipelineSource.keySet()) {
                if (mapDenominatorByPipelineSource.get(numeratorKey) != null && mapDenominatorByPipelineSource.get(numeratorKey).size() > 0) {
                    Double HIROPercentage = Double.valueOf(mapNumeratorByPipelineSource.get(numeratorKey).size()) / Double.valueOf(mapDenominatorByPipelineSource.get(numeratorKey).size());
                    mapHIROPercentage.put(numeratorKey, HIROPercentage);
                }
            }
        }
    }

    public void finish(Database.BatchableContext ctx) {
        if (mapHIROPercentage.size() != null && !mapHIROPercentage.isEmpty()) {
            for (String hiroList : mapHIROPercentage.keySet()) {
                String[] tempArray = hiroList.split('_');
                String pipelineSource = tempArray[0];
                String stageName = tempArray[1];
                String month = String.valueOf(Date.Today().month());
                String year = String.valueOf(Date.Today().year());

                HIRO_Percentage__c hiro = new HIRO_Percentage__c();
                hiro.External_Id__c = hiroList;
                hiro.Name = pipelineSource + '-' + stageName + ' ' + month + '-' + year;
                hiro.Stage__c = stageName;
                hiro.Date__c = Date.Today();
                hiro.Pipeline_Source__c = pipelineSource;
                hiro.HIRO_Percentage__c = mapHIROPercentage.get(hiroList) * 100;
                hiroToUpsert.add(hiro);
            }
        }

        system.debug('***HIRO Records: '+ ((String)JSON.serialize(hiroToUpsert)));

        if (hiroToUpsert.size() > 0) {
            upsert hiroToUpsert External_Id__c;
        }

        String query = 'SELECT Id, StageName, IsClosed, Pipeline_Source__c,Qualification_Date__c, Discovery_Date__c, Evaluation_Date__c, Negotiation_Date__c, Onboarding_Contracting_Date__c, Integration_Date__c, Activation_Date__c, Closed_Won_Date__c, Closed_Lost_Date__c  FROM Opportunity WHERE isClosed = FALSE AND Pipeline_Source__c != null';
        HIRO_MonthlyOppCalculationBatch batchUpdate = new HIRO_MonthlyOppCalculationBatch(query);
        Database.executeBatch(batchUpdate, 200);
    } 
}