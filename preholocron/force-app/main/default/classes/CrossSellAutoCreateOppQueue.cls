public class CrossSellAutoCreateOppQueue implements Queueable{
    Map<String, Map<String, Set<Id>>> accIdOppProductMap = new Map<String, Map<String,Set<Id>>>();
    Map<String, Set<Id>> accIdContactRoleMap = new Map<String, Set<Id>>();
    Map<String, Set<String>> accIdCampInflKeyMap = new Map<String, Set<String>>();
    Map<String, OpportunityContactRole> oppContactRoleMap = new Map<String, OpportunityContactRole>();
    String objective = '';
    public CrossSellAutoCreateOppQueue(Map<String, Map<String,Set<Id>>> accIdProductMap, Map<String, Set<Id>> accIdContactMap, Map<String, Set<String>> accIdCIKeyMap, Map<String, OpportunityContactRole> oppContRoleMap, String strObj) {
        accIdOppProductMap = accIdProductMap;
        accIdContactRoleMap = accIdContactMap;
        accIdCampInflKeyMap = accIdCIKeyMap;
        oppContactRoleMap = oppContRoleMap;
        objective = strObj;
    }

    public void execute(QueueableContext qc){
        try{
            CampaignMemberHelper.AutoCreateOpportunity(accIdOppProductMap, accIdContactRoleMap, accIdCampInflKeyMap, oppContactRoleMap, objective);
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('CrossSellAutoCreateOppQueue','CrossSellAutoCreateOppQueue', 'CrossSellAutoCreateOppQueue', 'Queue',  e);
        }
    }
}