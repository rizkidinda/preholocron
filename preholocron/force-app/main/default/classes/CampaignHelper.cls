/**
 * @description       : 
 * @group             : 
 * @last modified on  : 28-11-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
public without sharing class CampaignHelper {
    public static void preProcessCampaign(List<Campaign>  newCampaignList, Map<Id, Campaign> oldCampaignMap){
        for (Campaign cm : newCampaignList) {
            Campaign oldCm = new Campaign();
            if (oldCampaignMap != null && oldCampaignMap.get(cm.Id) != null) {
                oldCm = oldCampaignMap.get(cm.Id);
            } else {
                oldCm = null;
            }

            if (oldCm == null || (oldCm != null && (cm.StartDate != oldCm.StartDate || cm.EndDate != oldCm.EndDate))) {
                cm.isActive = checkCampaignPeriod(cm.StartDate, cm.EndDate);
            }
        }
    }

    //Auto Populate Program and Master Campaign based on Tactic Start and End Date period.
    public static void popoulateParentCampaignPeriod(List<Campaign>  newCampaignList, Map<Id, Campaign> oldCampaignMap){
        Set<Id> tacticCampaignToProcess = new Set<Id>();
        Set<Id> programCampaignToProcess = new Set<Id>();
        List<Campaign> campaignToUpdate = new List<Campaign>();

        for (Campaign cm : newCampaignList) {
            Campaign oldCm = new Campaign();
            if (oldCampaignMap != null && oldCampaignMap.get(cm.Id) != null) {
                oldCm = oldCampaignMap.get(cm.Id);
            } else {
                oldCm = null;
            }

            if (oldCm == null || (oldCm != null && (cm.StartDate != oldCm.StartDate || cm.EndDate != oldCm.EndDate))) {
                programCampaignToProcess.add(cm.ParentId);
            }
        }

        if (programCampaignToProcess.size() > 0) {
            Map<Id,AggregateResult> tacticProgramAggregates = new Map<Id,AggregateResult>([SELECT ParentId Id, Parent.ParentId masterId, MIN(StartDate) startDate, MAX(EndDate) endDate FROM Campaign WHERE ParentId IN :programCampaignToProcess GROUP BY Parent.ParentId, ParentId]);
            for (Id agr : tacticProgramAggregates.keySet()) {
                AggregateResult agrResult = tacticProgramAggregates.get(agr);
                Id programId = agr;
                Date startDate = (Date)agrResult.get('startDate');
                Date endDate = (Date)agrResult.get('endDate');
                Boolean isActive = checkCampaignPeriod(startDate, endDate);

                Campaign cmpProgram = new Campaign();
                cmpProgram.Id = programId;
                cmpProgram.StartDate = startDate;
                cmpProgram.EndDate = endDate;
                cmpProgram.isActive = isActive;
                campaignToUpdate.add(cmpProgram);

                // Campaign cmpMaster = new Campaign();
                // cmpMaster.Id = masterId;
                // cmpMaster.StartDate = startDate;
                // cmpMaster.EndDate = endDate;
                // cmpMaster.isActive = isActive;
                // campaignToUpdate.add(cmpMaster);
            }

            //Get master id
            Set<Id> masterIds = new Set<Id>();
            for (Campaign cmp : [SELECT ParentId FROM Campaign WHERE Id IN :programCampaignToProcess]) {
                masterIds.add(cmp.ParentId);
            }

            if (masterIds.size() > 0) {
                Map<Id,AggregateResult> tacticMasterAggregates = new Map<Id,AggregateResult>([SELECT Parent.ParentId Id, MIN(StartDate) startDate, MAX(EndDate) endDate FROM Campaign WHERE Parent.ParentId IN :masterIds GROUP BY Parent.ParentId]);
                for (Id agr : tacticMasterAggregates.keySet()) {
                    AggregateResult agrResult = tacticMasterAggregates.get(agr);
                    Id masterId = agr;
                    Date startDate = (Date)agrResult.get('startDate');
                    Date endDate = (Date)agrResult.get('endDate');
                    Boolean isActive = checkCampaignPeriod(startDate, endDate);

                    Campaign cmpMaster = new Campaign();
                    cmpMaster.Id = masterId;
                    cmpMaster.StartDate = startDate;
                    cmpMaster.EndDate = endDate;
                    cmpMaster.isActive = isActive;
                    campaignToUpdate.add(cmpMaster);
                }
            }
        }

        if (campaignToUpdate.size() > 0) {
            update campaignToUpdate;
        }
    }

    public static boolean checkCampaignPeriod(Date StartDate, Date EndDate) {
        Boolean isWithinPeriod = false;
        Date todayDate = Date.today();
        isWithinPeriod = todayDate >= startDate && todayDate <= endDate;
        if (isWithinPeriod) {
            isWithinPeriod = true;
        }
        return isWithinPeriod;
    }

    public static void campaignStatusManager(List<Campaign>  newCampaignList, Map<Id, Campaign> oldCampaignMap){
        for (Campaign cmp : newCampaignList) {
            String parentStatus;
            if (cmp.Parent_Status__c != null && cmp.Parent_Status__c != '') {
                parentStatus = cmp.Parent_Status__c;
            }

            String tempStatus;
            if (Trigger.isInsert) {
                if (cmp.isActive && ((cmp.Status == 'Confirmed' && parentStatus == null) || (cmp.Status == 'Confirmed' && (parentStatus == 'Confirmed' || parentStatus == 'In Progress')))) {
                    tempStatus = 'In Progress';
                }
            } else if (Trigger.isUpdate) {
                Campaign oldCmp = oldCampaignMap.get(cmp.Id);
                if (cmp.isActive && (cmp.Status != oldCmp.Status || cmp.StartDate != oldCmp.StartDate || cmp.EndDate != oldCmp.EndDate)) {
                    if (cmp.isActive && ((cmp.Status == 'Confirmed' && parentStatus == null) || (cmp.Status == 'Confirmed' && (parentStatus == 'Confirmed' || parentStatus == 'In Progress')))) {
                        tempStatus = 'In Progress';
                    }
                }
            }

            system.debug('***Status:' + cmp.Status);
            if (tempStatus != null && tempStatus != '') {
                cmp.Status = tempStatus;
            }
        }
    }
}