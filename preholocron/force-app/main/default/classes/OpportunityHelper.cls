/**
 * @description       : 
 * @group             : 
 * @last modified on  : 28-12-2023
 * @last modified by  : rizki.asriningtyas@xendit.co
**/
public class OpportunityHelper {
    private static final String LAST_WEEK = 'LAST_WEEK';
    private static final String LAST_2_WEEKS = 'LAST_2_WEEKS';
    // get map of stage with number or order
    public static Map<String, Integer> getStageMap()
    {
        Map<String, Integer> mapRes = new Map<String, Integer>();
        Map<String, String> mapStages = Utility.getMapPicklist('Opportunity', 'StageName');
        Integer i = 0;
        for(String s: mapStages.keySet()) {
            mapRes.put(s, i);
            i++;
        }
        return mapRes;
    }
    
    public static String getChildRecordTypeId()
    {
        return Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Child Opportunity').getRecordTypeId();
    }
    
    public static String getParentRecordTypeId()
    {
        return Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Parent Opportunity').getRecordTypeId();
    }

    public static User getCurrentUser(){
        User getUser = [SELECT Id, ProfileId, Profile.Name, Bypass_VR__c, FederationIdentifier FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        return getUser;
    }

    public static Map<String, Decimal> getConversionRateMap(){
        Map<String, Decimal> conversionRateMap = new Map<String, Decimal>();
        for(CurrencyType ct : [SELECT Id, IsoCode, ConversionRate FROM CurrencyType]){
            conversionRateMap.put(ct.IsoCode, ct.ConversionRate);
        }
        return conversionRateMap;
    }
    
  
    // to update Parent Stage when child changes
    public static void UpdateParentStage(Opportunity[] listNew, Opportunity[] listOld)
    {
        try{
            Id idRTChild = getChildRecordTypeId();
            Id idRTParent = getParentRecordTypeId();
            
            Set<String> stCheckedStage = new Set<String>{'Integration', 'Activation', 'Closed Won'};
            Set<String> stUpsellStamp = new Set<String>{'Approved', 'Submitted', 'Reject'};
            Map<Id, Opportunity> mapOld = new Map<Id, Opportunity>();
            if (listOld != null) {
                for(Opportunity O: listOld) {
                    mapOld.put(O.Id, O);
                }
            }
            
            Set<Id> stOppIds = new Set<Id>();
            Set<Id> stOppNegoIds = new Set<Id>(); // id of Opp need pricing approval
            Set<Id> stOppStageIds = new Set<Id>(); // id of Opp change stage
            Set<Id> stOppIsTransacting = new Set<Id>();
            Set<Id> stOppFXProdIds = new Set<Id>(); // id of Opp need FX approval

            Map<String, String> mapStageNameId = new Map<String, String>();

            if (listNew != null) {
                for(Opportunity O: listNew) {
                    // only if child and stage name changed
                    if (O.RecordTypeId == idRTChild && O.Parent_Opportunity__c != null) 
                    {
                        if ((listOld == null || mapOld.get(O.Id).Pricing_Approval__c != O.Pricing_Approval__c || O.Upsell_Approval__c == null || O.FX_Product_Approval__c == null
                                || mapOld.get(O.Id).FX_Product_Approval__c != O.FX_Product_Approval__c)) {
                            stOppIds.add(O.Parent_Opportunity__c); // always check to make sure
                        }
                        /*
                        if (O.Pricing_Approval__c == 'Approval Required' && (listOld == null || mapOld.get(O.Id).Pricing_Approval__c != 'Approval Required'))
                        {
                            // changed of pricing approval, change parent to Negotiation
                            stOppNegoIds.add(O.Parent_Opportunity__c);
                            //stOppIds.add(O.Parent_Opportunity__c);
                        }
                        else */
                        if (stCheckedStage.contains(O.StageName) && (listOld == null || MapOld.get(O.Id).StageName != O.StageName)) 
                        {
                            stOppStageIds.add(O.Parent_Opportunity__c);
                            
                            stOppIds.add(O.Parent_Opportunity__c);
                            mapStageNameId.put(O.Parent_Opportunity__c, O.StageName);
                        }

                        if(O.Is_Transacting__c){
                            stOppIds.add(O.Parent_Opportunity__c);
                            stOppIsTransacting.add(O.Parent_Opportunity__c);
                        }
                        
                        
                    }
                }
            }
            
            if (stOppIds.size() > 0) {
                Map<Id, List<Opportunity>> parentChildOppMap = new Map<Id, List<Opportunity>>();
                // check for any pricing approval required in child
                for(Opportunity O : [SELECT Id, Name, StageName, FX_Product_Approval__c, Pricing_Approval__c, Parent_Opportunity__c FROM Opportunity
                                    WHERE Parent_Opportunity__c IN :stOppIds])
                {
                    if(O.Pricing_Approval__c == 'Approval Required'){
                        stOppNegoIds.add(O.Parent_Opportunity__c);
                    }

                    if(o.FX_Product_Approval__c == 'Approval Required'){
                        stOppFXProdIds.add(O.Parent_Opportunity__c);
                    }

                    if(!parentChildOppMap.containsKey(O.Parent_Opportunity__c)){
                        parentChildOppMap.put(O.Parent_Opportunity__c, new List<Opportunity>{O});
                    }else{
                        parentChildOppMap.get(O.Parent_Opportunity__c).add(O);
                    }
                }
                
                Map<String, Integer> mapStageOrder = getStageMap();
                List<Opportunity> lsParentOpp = new List<Opportunity>();
                Boolean bolSkip = false;
                Boolean bolAdd = false;
                //get parent opportunity
                for(Opportunity O : [SELECT Id, Name, StageName, Pricing_Approval__c, Is_Transacting__c, Type, Upsell_Approval__c, Created_via_Campaign__c, FX_Product_Approval__c,
                Qualification_Date__c, Discovery_Date__c, Evaluation_Date__c, Negotiation_Date__c, Onboarding_Contracting_Date__c, Integration_Date__c, Activation_Date__c, Closed_Won_Date__c
                                    FROM Opportunity
                                    WHERE Id IN :stOppIds ])
                {
                    bolSkip = false;
                    bolAdd = true;
                    if (O.Pricing_Approval__c != 'Submitted' && O.Pricing_Approval__c != 'Approved') {
                        O.Pricing_Approval__c = 'No approval required';
                        if(O.Type == 'Upsell' && !O.Created_via_Campaign__c && O.Pricing_Approval__c == 'No approval required' && !stUpsellStamp.contains(O.Upsell_Approval__c)){
                            System.debug('***Update child Approval Required');
                            O.Upsell_Approval__c = 'Approval Required';
                        }else if(O.Type != 'Upsell' && O.Pricing_Approval__c == 'No approval required' && !stUpsellStamp.contains(O.Upsell_Approval__c)){
                            O.Upsell_Approval__c = 'No Approval Required';
                        }
                        if (stOppNegoIds.contains(O.Id)) {
                            O.Pricing_Approval__c = 'Approval Required';
                            O.Upsell_Approval__c = 'No Approval Required';
                            bolSkip = true;
                        }						                        
                        bolAdd = true;
                    }

                    if (O.FX_Product_Approval__c != 'Submitted' && O.FX_Product_Approval__c != 'Approved') {
                        O.FX_Product_Approval__c = 'No approval required';
                        
                        if(stOppFXProdIds.contains(O.Id)){
                            o.FX_Product_Approval__c = 'Approval required';
                            bolSkip = true;
                        }
                        bolAdd = true;
                    }

                    if (!bolSkip) {
                        User currUser = getCurrentUser();
                        if (stOppStageIds.contains(O.Id) && mapStageNameId.get(O.Id) != null && mapStageNameId.get(O.Id) != 'Closed Won') {
                            if (O.StageName == null || (mapStageOrder.get(O.StageName) < mapStageOrder.get(mapStageNameId.get(O.Id)))) {
                                System.debug('Check stagename:'+ O.StageName + mapStageOrder.get(O.StageName) + ' and ' + mapStageOrder.get(mapStageNameId.get(O.Id)));
                                O.StageName = mapStageNameId.get(O.Id);
                                //lsParentOpp.add(O);
                                bolAdd = true;
                            }
                        }else if(stOppStageIds.contains(O.Id) && mapStageNameId.get(O.Id) != null && mapStageNameId.get(O.Id) == 'Closed Won' && parentChildOppMap.containsKey(O.Id)){
                            Set<String> childStages = new Set<String>();
                            for(Opportunity child : parentChildOppMap.get(O.Id)){
                                childStages.add(child.StageName);
                            }
                            if(!childStages.isEmpty() && ((childStages.size() == 1 && childStages.contains('Closed Won')) || (childStages.size() == 2 && childStages.contains('Closed Won') && childStages.contains('Closed Lost')))){
                                O.StageName = mapStageNameId.get(O.Id);
                                updateStageDate(O, O.StageName);
                                if(!Utility.adminProfilesSet().contains(currUser.Profile.Name)){
                                    O.Allow_Child_Opp_Stage_Update__c = true;
                                }
                                bolAdd = true;
                            }if(!childStages.isEmpty() && ((childStages.size() > 2 && childStages.contains('Closed Won')) || (childStages.size() == 2 && childStages.contains('Closed Won') && !childStages.contains('Closed Lost')))){
                                O.StageName = 'Activation';
                                updateStageDate(O, O.StageName);
                                if(!Utility.adminProfilesSet().contains(currUser.Profile.Name)){
                                    O.Allow_Child_Opp_Stage_Update__c = true;
                                }
                                bolAdd = true;
                            }
                        }
                    }

                    if(stOppIsTransacting.contains(O.Id)){
                        O.Is_Transacting__c = TRUE;
                        bolAdd = true;
                    }
                    
                    if (bolAdd) {
                        lsParentOpp.add(O);
                    }
                }
                
                if (lsParentOpp.size() > 0) {
                    TriggerBypassUtility.opportunityTriggerBypass = true;
                    update(lsParentOpp);
                    TriggerBypassUtility.opportunityTriggerBypass = false;
                    updateChildOppWithFlag(lsParentOpp);
                }
            }
        }catch(DmlException e){
            Set<String> errmsgList = new Set<String>();
            for (Integer i = 0; i < e.getNumDml(); i++) {
                // Process exception here
                errmsgList.add(e.getDmlMessage(i)); 
            }

            String errMsg = String.join(new List<String>(errmsgList), '\n');
            listNew[0].addError(errMsg);
            //ExceptionUtility.throwCustomExceptionApex(new List<String>{errMsg});
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('OpportunityHelper','Opportunity', 'UpdateParentStage', 'OpportunityTrigger',  e);
        }
    }
    
    public static void updateStageDate(Opportunity opp, String stageName){
        Opportunity tempOpp = opp;
        if(opp != null && (stageName == 'Activation' || stageName == 'Closed Won')){
            opp.Qualification_Date__c = getTodayDate(tempOpp.Qualification_Date__c); 
            opp.Discovery_Date__c = getTodayDate(tempOpp.Discovery_Date__c);
            opp.Evaluation_Date__c = getTodayDate(tempOpp.Evaluation_Date__c);
            opp.Negotiation_Date__c = getTodayDate(tempOpp.Negotiation_Date__c);
            opp.Onboarding_Contracting_Date__c = getTodayDate(tempOpp.Onboarding_Contracting_Date__c);
            opp.Integration_Date__c = getTodayDate(tempOpp.Integration_Date__c);
            opp.Activation_Date__c = getTodayDate(tempOpp.Activation_Date__c);
            if(stageName == 'Closed Won'){
                opp.Closed_Won_Date__c = getTodayDate(tempOpp.Closed_Won_Date__c);
            }
        }
    }

    public static Date getTodayDate(Date dateField){    
        return dateField == null ? Date.today() : dateField;
    }

    // check if child need to update parent field
    public static void CheckUpdateParentFields(Opportunity[] listNew, Opportunity[] listOld)
    {
        try{
            Id idRTChild = getChildRecordTypeId();
            String fxprodval;
            Map<Id, Opportunity> mapOld = new Map<Id, Opportunity>();
            List<Id> lsParentIds = new List<Id>();
            if (listOld != null) {
                for(Opportunity O: listOld) {
                    mapOld.put(O.Id, O);
                }
            }
            if (listNew != null) {
                
                for(Opportunity O: listNew) {
                    if (O.RecordTypeId == idRTChild && O.Parent_Opportunity__c != null) {
                        Boolean updatedPricing = mapOld.containsKey(O.Id) && ((O.Opp_Product_Below_COGS_Count__c != mapOld.get(O.Id).Opp_Product_Below_COGS_Count__c) || (O.Opp_Unsuported_Product_Count__c != mapOld.get(O.Id).Opp_Unsuported_Product_Count__c));
                        Boolean updatedCost = mapOld.containsKey(O.Id) && (O.Estimated_Monthly_Projected_Cost__c != mapOld.get(O.Id).Estimated_Monthly_Projected_Cost__c);
                        
                        if (listOld == null || (O.Estimated_Monthly_Potential_TPV__c != mapOld.get(O.Id).Estimated_Monthly_Potential_TPV__c))
                        {
                            lsParentIds.add(O.Parent_Opportunity__c);
                        }
                        else if (listOld == null || (O.Estimated_Monthly_Revenue__c != mapOld.get(O.Id).Estimated_Monthly_Revenue__c))
                        {
                            lsParentIds.add(O.Parent_Opportunity__c);
                        }
                        else if (listOld == null || updatedCost || updatedPricing)
                        {
                            lsParentIds.add(O.Parent_Opportunity__c);
                        }
                    }
                }
                
                system.debug('bool opp product update : ' + Xendit_CalculateEstimatedValues.boolOppProductRecalculate);
                if (lsParentIds.size() > 0 && !Xendit_CalculateEstimatedValues.boolOppProductRecalculate) {
                    UpdateParentRollupAmounts(lsParentIds);
                }

            }
        }catch(DmlException e){
            Set<String> errmsgList = new Set<String>();
            for (Integer i = 0; i < e.getNumDml(); i++) {
                // Process exception here
                errmsgList.add(e.getDmlMessage(i)); 
            }

            String errMsg = String.join(new List<String>(errmsgList), '\n');
            listNew[0].addError(errMsg);
            //ExceptionUtility.throwCustomExceptionApex(new List<String>{errMsg});
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('OpportunityHelper','Opportunity', 'CheckUpdateParentFields', 'OpportunityTrigger',  e);
        }
    }
        
    // update any "roll-up" fields in parent account as total from child account, only on selected parent Ids
    //@future
    public static void UpdateParentRollupAmounts(List<Id> lsIds)
    {
        
        if (lsIds.size() > 0) {
            Map<Id, String> mapfxProductVal = new Map<Id, String>();
            Map<Id, Double> mapTotalAddressable = new Map<Id, Double>();
            Map<Id, Double> mapTotalEstRevenue = new Map<Id, Double>();
            Map<Id, Double> mapTotalProjectedCost = new Map<Id, Double>();
            Map<Id, Integer> mapCountBelowCOGS = new Map<Id, Integer>();
            Map<Id, Integer> mapUnsupportedProducts = new Map<Id, Integer>();
            Double decTmp;
            
            // get total summary
            /*
            for(AggregateResult ar: [SELECT Parent_Opportunity__c, Count(Id) c, SUM(Estimated_Monthly_Potential_TPV__c) totalTPV
                                     FROM Opportunity WHERE Parent_Opportunity__c IN :lsIds GROUP BY Parent_Opportunity__c])
            */
            for(Opportunity O: [SELECT Id,FX_Product_Approval__c, Estimated_Monthly_Potential_TPV__c, Parent_Opportunity__c, Estimated_Monthly_Revenue__c, Estimated_Monthly_Projected_Cost__c, Opp_Product_Below_COGS_Count__c, Opp_Unsuported_Product_Count__c 
                                FROM Opportunity WHERE Parent_Opportunity__c IN :lsIds ORDER BY Parent_Opportunity__c] )
            {
                decTmp = 0.0;
                if (mapTotalAddressable.get(O.Parent_Opportunity__c) != null) {
                    decTmp = mapTotalAddressable.get(O.Parent_Opportunity__c);
                }
                if (O.Estimated_Monthly_Potential_TPV__c != null) decTmp += O.Estimated_Monthly_Potential_TPV__c;
                mapTotalAddressable.put(O.Parent_Opportunity__c, decTmp);
                
                decTmp = 0.0;
                if (mapTotalEstRevenue.get(O.Parent_Opportunity__c) != null) {
                    decTmp = mapTotalEstRevenue.get(O.Parent_Opportunity__c);
                }
                if (O.Estimated_Monthly_Revenue__c != null) decTmp += O.Estimated_Monthly_Revenue__c;
                mapTotalEstRevenue.put(O.Parent_Opportunity__c, decTmp);

                Double decTmpCost = 0;
                if (mapTotalProjectedCost.containsKey(O.Parent_Opportunity__c)) {
                    decTmpCost = mapTotalProjectedCost.get(O.Parent_Opportunity__c);
                }
                if (O.Estimated_Monthly_Projected_Cost__c != null) decTmpCost += O.Estimated_Monthly_Projected_Cost__c;
                mapTotalProjectedCost.put(O.Parent_Opportunity__c, decTmpCost);
                
                Integer intTmpCount = 0;
                if(mapCountBelowCOGS.containsKey(O.Parent_Opportunity__c)){
                    intTmpCount = mapCountBelowCOGS.get(O.Parent_Opportunity__c);
                }
                if(O.Opp_Product_Below_COGS_Count__c != null) intTmpCount += Integer.valueOf(O.Opp_Product_Below_COGS_Count__c);
                mapCountBelowCOGS.put(O.Parent_Opportunity__c, intTmpCount);

                Integer intTmpUnsupportedPrdCount = 0;
                if(mapUnsupportedProducts.containsKey(O.Parent_Opportunity__c)){
                    intTmpUnsupportedPrdCount = mapUnsupportedProducts.get(O.Parent_Opportunity__c);
                }
                if(O.Opp_Unsuported_Product_Count__c != null) intTmpUnsupportedPrdCount += Integer.valueOf(O.Opp_Unsuported_Product_Count__c);
                mapUnsupportedProducts.put(O.Parent_Opportunity__c, intTmpUnsupportedPrdCount);
            }
            
            List<Opportunity> lsUpdated = new List<Opportunity>();
            for(Opportunity O:[SELECT Id, FX_Product_Approval__c, Addressable_Opp_Volume_Annual_Local__c FROM Opportunity WHERE Id IN :lsIds])
            {
                /*
                O.Addressable_Opp_Volume_Annual_Local__c = 0; // default
                if (mapTotalAddressable.get(O.Id) != null) {
                    O.Addressable_Opp_Volume_Annual_Local__c = mapTotalAddressable.get(O.Id);
                }
                */
                O.Addressable_Merchant_TPV_Monthly__c = 0; // default
                if (mapTotalAddressable.get(O.Id) != null) {
                    O.Addressable_Merchant_TPV_Monthly__c = mapTotalAddressable.get(O.Id);
                }
                O.Addressable_Merchant_Revenue_Monthly__c = 0;
                if (mapTotalEstRevenue.get(O.Id) != null) {
                    O.Addressable_Merchant_Revenue_Monthly__c = mapTotalEstRevenue.get(O.Id);
                }
                if(mapTotalProjectedCost.containsKey(O.Id)){
                    O.Addressable_Project_Cost_Monthly__c = mapTotalProjectedCost.get(O.Id);
                }
                if(mapCountBelowCOGS.containsKey(O.Id)){
                    O.Opp_Product_Below_COGS_Count__c = mapCountBelowCOGS.get(O.Id);
                }
                if(mapUnsupportedProducts.containsKey(O.Id)){
                    O.Opp_Unsuported_Product_Count__c = mapUnsupportedProducts.get(O.Id);
                }
                O.Amount = O.Addressable_Merchant_Revenue_Monthly__c;
                
                lsUpdated.add(O);
            }
            if (lsUpdated.size() > 0) {
                TriggerBypassUtility.opportunityTriggerBypass = true;
                update(lsUpdated);
            }
        }
    }

    
    // check if parent opportunity is locked
    public static void CheckParentOpportunityLocked(Opportunity[] listOpp)
    {
        if (listOpp != null)
        {
            Set<Id> stParentIds = new Set<Id>();
            Set<Id> stLockedIds = new Set<Id>();
            String strErrMsg = '';
            for(Opportunity O: listOpp) {
                if (O.Parent_Opportunity__c != null && O.Is_Merged_Account__c == FALSE) {
                    stParentIds.add(O.Parent_Opportunity__c);
                }
            }
            if (stParentIds.size() > 0)
            {
                system.debug('DEBUG: parent ids ' + stParentIds);
                User currUser = getCurrentUser();
                // get parent opp information
                for(Opportunity Op: [SELECT Id, Name, StageName, Pricing_Approval__c FROM Opportunity WHERE Id IN :stParentIds])
                {
                    if (Op.StageName == 'Integration' || Op.StageName == 'Activation' || Op.StageName == 'Closed Won') {
                        stLockedIds.add(Op.Id);
                        strErrMsg = 'The Parent Opportunity is in ' + Op.StageName + ' Stage. You are not allowed to update the pricing anymore.';
                    }
                    else if (Op.Pricing_Approval__c == 'Submitted' || Op.Pricing_Approval__c == 'Approved') {
                        stLockedIds.add(Op.Id);
                        strErrMsg = 'Pricing Approval for this parent opportunity has been ' + Op.Pricing_Approval__c + '. You are not allowed to update the pricing anymore.';
                    }
                }
                
                if (stLockedIds != null) {
                    system.debug('DEBUG: parent locked ' + stLockedIds);
                    for(Opportunity O: listOpp) {
                        if (!currUser.Bypass_VR__c && O.Parent_Opportunity__c != null && stLockedIds.contains(O.Parent_Opportunity__c)) {
                            // O.addError('Parent_Opportunity__c', 'Parent Opportunity record is currently locked');
                            O.addError('Parent_Opportunity__c', strErrMsg);
                        }
                    }
                }
            }
        }
    }

    /*
    When enter Evaluation, check at least one contact Role PIC has to be identified
    When enter Discovery, check at least contact Role PIC or decision maker to be identified
    */
    public static void CheckAccountContact(List<Opportunity> listNew){
        Id idRTParent = getParentRecordTypeId();
        Set<Id> accountSet = new Set<Id>();
        Set<Id> parentOppIdSet = new Set<Id>();
        List<Opportunity> parentOppList = new List<Opportunity>();
        Map<Id, Set<String>> accRoleMap = new Map<Id, Set<String>>();
        Map<Id, Set<Id>> accContactMap = new Map<Id, Set<Id>>();
        Map<Id, Set<String>> oppContactRoleMap = new Map<Id, Set<String>>();

        try{

            for(Opportunity opp : listNew){
                //get parent opportunity with value as Evaluation or Discovery
                if(opp.RecordTypeId == idRTParent && (opp.StageName == 'Evaluation' || opp.StageName == 'Discovery' || opp.StageName == 'Negotiation') && opp.AccountId != null){
                    parentOppList.add(opp);
                    parentOppIdSet.add(opp.Id);
                }
            }
    
            if(!parentOppList.isEmpty()){
    			User getUser = getCurrentUser();
                
                for(Opportunity opp : parentOppList){
                    //get AccountId to retrieve contact
                    accountSet.add(opp.AccountId);
                }

                List<AccountContactRelation> accContactList = [SELECT Id, AccountId, ContactId, Contact.Decision_Making_Role__c FROM AccountContactRelation WHERE AccountId IN :accountSet];
                if(accContactList != null && !accContactList.isEmpty()){
                    //store accounts with PIC contact
                    accRoleMap = getAccContactRelationRoles(accContactList);

                    for(AccountContactRelation accContact : accContactList){
                   
                        //store accounts with Contact Id
                        if(!accContactMap.containsKey(accContact.AccountId)){
                            accContactMap.put(accContact.AccountId, new Set<Id>{accContact.ContactId});
                        } else{
                            accContactMap.get(accContact.AccountId).add(accContact.ContactId);
                        }
                    }
                }

                oppContactRoleMap = getOppContactRoles(parentOppIdSet);

                for(Opportunity opp : parentOppList){
                    Boolean isOppContactRoleExist = oppContactRoleMap.containsKey(opp.Id) && 
                                                    (oppContactRoleMap.get(opp.Id).contains('PIC') || oppContactRoleMap.get(opp.Id).contains('Founder / Owner / Director') || oppContactRoleMap.get(opp.Id).contains('Founder, Owner, Director') || 
                                                    (oppContactRoleMap.get(opp.Id).contains('Decision Maker')));
                    Boolean isAccountContactRelExist = accRoleMap.containsKey(opp.AccountId) && 
                                                        (accRoleMap.get(opp.AccountId).contains('PIC') || accRoleMap.get(opp.AccountId).contains('Founder / Owner / Director') || accRoleMap.get(opp.AccountId).contains('Founder, Owner, Director') || 
                                                        (accRoleMap.get(opp.AccountId).contains('Decision Maker')));

                    if(!getUser.Bypass_VR__c && getUser.Profile.Name != 'Xendit API Profile' && (opp.StageName == 'Evaluation' || opp.StageName == 'Discovery') && !isOppContactRoleExist && !isAccountContactRelExist){
                        if(opp.StageName == 'Evaluation'){
                            opp.addError('For Opportunity with Stage as Evaluation, at least one contact related to the Opportunity or Account with Role as "PIC" or "Founder / Owner / Director" or "Discovery" has to be identified');
                        }else if(opp.StageName == 'Discovery'){
                            opp.addError('For Opportunity with Stage as Discovery, at least one contact related to the Opportunity or Account with Role as "PIC" or "Decision Maker" or "Founder / Owner / Director"  or "Discovery" has to be identified');
                        }
                    }
                    
                    //throw error if Contract Contact doesn't related to the Account //commented out 13 Mar 2023 requested by Tracy
                    // else if(!getUser.Bypass_VR__c && getUser.Profile.Name != 'Xendit API Profile' && String.isNotBlank(opp.Contract_Contact__c) && (!accContactMap.containsKey(opp.AccountId) || (accContactMap.containsKey(opp.AccountId) && !accContactMap.get(opp.AccountId).contains(opp.Contract_Contact__c)))){
                    //     opp.addError('Please select Contract Contact related to the Opportunity Account');
                    // }
                }
            }
        }catch(Exception e){
            system.debug('error on function CheckAccountContact :' + e.getMessage());
        }
    }

    public static void AutoClosedWonChildOpportunity(List<Opportunity> listNew, Map<Id, Opportunity> oldMap){
        Id idRTParent = getParentRecordTypeId();
        List<Id> updatedParentOppId = new List<Id>();
        List<Opportunity> childOppCWList = new List<Opportunity>();
        List<Opportunity> childOppwithFlag = new List<Opportunity>();
        Set<String> oppTypeException = new Set<String>{'Upsell','Renegotiation'};
        
        try{
            for(Opportunity opp : listNew){
                Opportunity oldOpp = oldMap.get(opp.Id);

                //get parent opportunity Id which Ready_to_Closed_Won__c updated to TRUE
                if(opp.RecordTypeId == idRTParent && opp.Ready_to_Closed_Won__c == TRUE && opp.Ready_to_Closed_Won__c != oldOpp.Ready_to_Closed_Won__c){
                    updatedParentOppId.add(opp.Id);
                }
            }

            if(!updatedParentOppId.isEmpty()){
                User currUser = getCurrentUser();
                //get child opp with related parent opportunity with updated Ready_to_Closed_Won__c = TRUE
               for(Opportunity childOpp : [SELECT Id, Is_Transacting__c, StageName, Type,
                                           Qualification_Date__c, Discovery_Date__c, Evaluation_Date__c, Negotiation_Date__c, Onboarding_Contracting_Date__c, Integration_Date__c, Activation_Date__c, Closed_Won_Date__c,
                                           (SELECT Id, Product__r.Exclude_Auto_Closed_Won__c FROM Xendit_Opportunity_Products__r WHERE Product__r.Exclude_Auto_Closed_Won__c = TRUE) 
                                           FROM Opportunity WHERE Parent_Opportunity__c IN :updatedParentOppId AND StageName NOT IN ('Closed Won','Closed Lost') AND Is_Transacting__c = TRUE]){

                   //determine if child opportunity product related with product excluded from auto closed won
                   Boolean isExclude = false;
                   List<Xendit_Opportunity_Product__c> xOpList = childOpp.Xendit_Opportunity_Products__r;
                   if(xOpList != null && !xOpList.isEmpty()){
                       isExclude = true;
                   }

                   //auto CW only if Parent ready to closed won && Is Transacting = TRUE && Product not excluded from auto CW && Type not in exception list
                   if(childOpp.Is_Transacting__c && !isExclude && !oppTypeException.contains(childOpp.Type)){
                       Opportunity oppTemp = new Opportunity(Id = childOpp.Id, Qualification_Date__c = childOpp.Qualification_Date__c, Discovery_Date__c = childOpp.Discovery_Date__c, Evaluation_Date__c = childOpp.Evaluation_Date__c, Negotiation_Date__c = childOpp.Negotiation_Date__c, Onboarding_Contracting_Date__c = childOpp.Onboarding_Contracting_Date__c, Integration_Date__c = childOpp.Integration_Date__c, Activation_Date__c = childOpp.Activation_Date__c, Closed_Won_Date__c = childOpp.Closed_Won_Date__c, StageName = 'Closed Won');
                       updateStageDate(oppTemp, oppTemp.stageName);
                       if(!Utility.adminProfilesSet().contains(currUser.Profile.Name)){
                           oppTemp.Allow_Child_Opp_Stage_Update__c = true;
                       }
                       childOppCWList.add(oppTemp);
                   }
               }

               if(!childOppCWList.isEmpty()){
                   update childOppCWList;
                   updateChildOppWithFlag(childOppCWList);
               }
           }
        }catch(DmlException e){
            Set<String> errmsgList = new Set<String>();
            for (Integer i = 0; i < e.getNumDml(); i++) {
                // Process exception here
                errmsgList.add(e.getDmlMessage(i)); 
            }

            String errMsg = String.join(new List<String>(errmsgList), '\n');
            listNew[0].addError(errMsg);
            //ExceptionUtility.throwCustomExceptionApex(new List<String>{errMsg});
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('OpportunityHelper','Opportunity', 'AutoClosedWonChildOpportunity', 'OpportunityTrigger',  e);
        }
    }

    public static void CheckChildOpptyCurrency(List<Opportunity> listNew, Map<Id, Opportunity> oldMap){
        Id idRTParent = getParentRecordTypeId();
        Map<Id,Opportunity> parentOppMap = new Map<Id,Opportunity>(); //to store parent opp with local currencies
        Map<Id, List<Opportunity>> parentChildOppMap = new Map<Id, List<Opportunity>>(); //to store child opp with mismatch local currencies
        for(Opportunity opp : listNew){
            Opportunity oldOpp = oldMap.get(opp.Id);
            if(opp.RecordTypeId == idRTParent && opp.CurrencyIsoCode != oldOpp.CurrencyIsoCode && opp.CurrencyIsoCode != 'USD'){ //select local currency only
                parentOppMap.put(opp.Id,opp);
            }
        }

        if(!parentOppMap.isEmpty()){
            User currUser = getCurrentUser();
            for(Opportunity opp : [SELECT Id, Parent_Opportunity__c, CurrencyIsoCode FROM Opportunity WHERE Parent_Opportunity__c IN :parentOppMap.keySet()]){
                if(parentOppMap.get(opp.Parent_Opportunity__c).CurrencyIsoCode != opp.CurrencyIsoCode){
                    if(!parentChildOppMap.containsKey(opp.Parent_Opportunity__c)){  
                        parentChildOppMap.put(opp.Parent_Opportunity__c, new List<Opportunity>{opp});
                    }else{
                        parentChildOppMap.get(opp.Parent_Opportunity__c).add(opp);
                    }
                }
            }

            for(Opportunity parentOpp : parentOppMap.values()){
                if(!currUser.Bypass_VR__c && currUser.Profile.Name != 'Xendit API Profile' && parentChildOppMap.containsKey(parentOpp.Id) && parentChildOppMap.get(parentOpp.Id).size() > 0){
                    parentOpp.addError('Please make sure all child opportunities are using the same local currency');
                }
            }
        }
    }

    //update value to account
    public static void updateAddressableOppAccount(List<Opportunity> listNew, Map<Id, Opportunity> oldMap, List<Opportunity> rampParentOppList){
        Id idRTParent = getParentRecordTypeId();
        Set<String> parentAccIds = new Set<String>();
        if(listNew != null && oldMap != null){
            for(Opportunity opp : listNew){
                Opportunity oldOpp = oldMap.get(opp.Id);
                if(opp.RecordTypeId == idRTParent){
                    Boolean addressableiYRevenueChange = opp.Addressable_iY_Revenue__c != oldOpp.Addressable_iY_Revenue__c;
                    Boolean addressableiYTPVChange = opp.Addressable_iY_TPV__c != oldOpp.Addressable_iY_TPV__c;
                    Boolean addressableMonthlyRevenueChange = opp.Addressable_Merchant_Revenue_Monthly__c != oldOpp.Addressable_Merchant_Revenue_Monthly__c;
                    Boolean addressableMonthlyTPVChange = opp.Addressable_Merchant_TPV_Monthly__c != oldOpp.Addressable_Merchant_TPV_Monthly__c;
                    Boolean addressablewiYRevenueChange = opp.Addressable_wiY_Revenue__c != oldOpp.Addressable_wiY_Revenue__c;
                    Boolean addressablewiYTPVChange = opp.Addressable_wiY_TPV__c != oldOpp.Addressable_wiY_TPV__c;
                    Boolean updatedAddressableValues = addressableiYRevenueChange || addressableiYTPVChange || addressableMonthlyRevenueChange || addressableMonthlyTPVChange ||
                                                        addressablewiYRevenueChange || addressablewiYTPVChange;
    
                    if(updatedAddressableValues){
                        parentAccIds.add(opp.AccountId);
                    }
                }
            }
        }
        
        if(rampParentOppList != null){
            for(Opportunity opp : rampParentOppList){
                parentAccIds.add(opp.AccountId);
            }   
        }
        

        if(!parentAccIds.isEmpty()){
            ParentAccountRevenueUpdateBatch cx = new ParentAccountRevenueUpdateBatch(parentAccIds);
            Database.executeBatch( cx , 1 ); 
        }
    }

    public static void UpdateWeeklyUpdateHistory(List<Opportunity> listNew, Map<Id, Opportunity> oldMap){
        try{
            Id idRTParent = getParentRecordTypeId();
            for(Opportunity opp : listNew){
                if(opp.RecordTypeId == idRTParent){
                    DateTime todayDate = Datetime.now();
                    String strTodayDate = todayDate.format('dd/MM/yyyy');
                    String currWeeklyUpdate = !String.isBlank(opp.Weekly_Update__c) ? strTodayDate + ' ' + UserInfo.getName() + ': ' + opp.Weekly_Update__c : '';
                    String currUpdateCommentSE = !String.isBlank(opp.SE_Updates_Comments__c) ? strTodayDate + ' ' + UserInfo.getName() + ': ' + opp.SE_Updates_Comments__c : '';
                    if(oldMap == null){
                        opp.Weekly_Update_History__c = currWeeklyUpdate;
                        opp.SE_Update_with_History__c = currUpdateCommentSE;
                    }else if(opp.Id != null && oldMap.containsKey(opp.Id) && oldMap.get(opp.Id).Weekly_Update__c != opp.Weekly_Update__c){
                        String weeklyHistory = opp.Weekly_Update_History__c != null ? opp.Weekly_Update_History__c : '';
                        opp.Weekly_Update_History__c = currWeeklyUpdate +'<br/>'+weeklyHistory;
                    }else if(opp.Id != null && oldMap.containsKey(opp.Id) && oldMap.get(opp.Id).SE_Updates_Comments__c != opp.SE_Updates_Comments__c){
                        String weeklyHistorySE = opp.SE_Update_with_History__c != null ? opp.SE_Update_with_History__c : '';
                        opp.SE_Update_with_History__c = currUpdateCommentSE +'<br/>'+weeklyHistorySE;
                    }
                   
                }
            }
        }catch(DmlException e){
            Set<String> errmsgList = new Set<String>();
            for (Integer i = 0; i < e.getNumDml(); i++) {
                // Process exception here
                errmsgList.add(e.getDmlMessage(i)); 
            }

            String errMsg = String.join(new List<String>(errmsgList), '\n');
            listNew[0].addError(errMsg);
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('OpportunityHelper','Opportunity', 'UpdateWeeklyUpdateHistory', 'OpportunityTrigger',  e);
        }
    }

    public static void updateChildOppWithFlag(List<Opportunity> oppList){
        List<Opportunity> childOppwithFlag = new List<Opportunity>();
        for(Opportunity opp : oppList){
            if(opp.Allow_Child_Opp_Stage_Update__c = true){
                childOppwithFlag.add(new Opportunity(Id = opp.Id, Allow_Child_Opp_Stage_Update__c = false));
            }
        }
        
        if(!childOppwithFlag.isEmpty()){
            TriggerBypassUtility.opportunityTriggerBypass = true;
            try{
                update childOppwithFlag;
            }catch(Exception e){
                ExceptionUtility.createExceptionLog('OpportunityHelper','Opportunity', 'updateChildOppWithFlag', 'OpportunityTrigger',  e);
            }
            
            TriggerBypassUtility.opportunityTriggerBypass = false;
        }
    }

    public static Map<Id, Set<String>> getOppContactRoles(Set<Id> parentOppIdSet){
        Map<Id, Set<String>> oppContactRoleMap = new Map<Id, Set<String>>();
        for(OpportunityContactRole oppContactRole : [SELECT Id, OpportunityId, Role FROM OpportunityContactRole WHERE OpportunityId IN :parentOppIdSet AND ContactId != NULL AND Role != NULL ]){
            //store opportunity with contact role
            if(!oppContactRoleMap.containsKey(oppContactRole.OpportunityId)){
                oppContactRoleMap.put(oppContactRole.OpportunityId, new Set<String>{oppContactRole.Role});
            } else{
                oppContactRoleMap.get(oppContactRole.OpportunityId).add(oppContactRole.Role);
            }
        }
        return oppContactRoleMap;
    }

    public static Map<Id, Set<String>> getAccContactRelationRoles(List<AccountContactRelation> accContactList){
        Map<Id, Set<String>> accRoleMap = new Map<Id, Set<String>>();
        for(AccountContactRelation accContact : accContactList){
            //store accounts with PIC contact
            if(!accRoleMap.containsKey(accContact.AccountId)){
                accRoleMap.put(accContact.AccountId, new Set<String>{accContact.Contact.Decision_Making_Role__c});
            } else{
                accRoleMap.get(accContact.AccountId).add(accContact.Contact.Decision_Making_Role__c);
            }
        }
        return accRoleMap;
    }
	
	public static void convertToUSD(List<Opportunity> listNew, Map<Id, Opportunity> oldMap) {
        List<Opportunity> opportunityToProcess = new List<Opportunity>();
        for(Opportunity opp : listNew){
            Decimal oldValue = (oldMap != null && oldMap.containsKey(opp.Id)) ? oldMap.get(opp.Id).Addressable_Merchant_Revenue_Monthly__c : null;
            System.debug('ConvertToUSD'+ oldValue);
            if (oldValue == null || opp.Addressable_Merchant_Revenue_Monthly_USD__c == null || opp.Addressable_Merchant_Revenue_Monthly__c != oldValue) {
                opportunityToProcess.add(opp);
            }
        }

        if (opportunityToProcess.size() > 0) {
            Map<String, Decimal> conversionRateMap = getConversionRateMap();  
            for (Opportunity opp : opportunityToProcess) {
                if(opp.Addressable_Merchant_Revenue_Monthly__c != null && opp.CurrencyIsoCode != 'USD' && conversionRateMap.containsKey(opp.CurrencyIsoCode)){
                    opp.Addressable_Merchant_Revenue_Monthly_USD__c = opp.Addressable_Merchant_Revenue_Monthly__c / conversionRateMap.get(opp.CurrencyIsoCode);
                    System.debug('Convert Value:' + opp.Addressable_Merchant_Revenue_Monthly_USD__c);
                }
                else if(opp.CurrencyIsoCode == 'USD'){
                    opp.Addressable_Merchant_Revenue_Monthly_USD__c = opp.Addressable_Merchant_Revenue_Monthly__c;
                }
            }
        }
    }
    
    public static void setBDProspectingStage(List<Opportunity> listNew, Map<Id, Opportunity> oldMap){
        try{
            Id idRTParent = getParentRecordTypeId();
            Set<Id> accountSet = new Set<Id>();
            Set<Id> parentOppIdSet = new Set<Id>();
            Map<Id, Set<String>> accRoleMap = new Map<Id, Set<String>>();
            Map<Id, Set<String>> oppContactRoleMap = new Map<Id, Set<String>>();
            Map<Id, List<Xendit_Opportunity_Product__c>> oppProductMap = new Map<Id, List<Xendit_Opportunity_Product__c>>();

            for(Opportunity opp : listNew){
                if(opp.RecordTypeId == idRTParent && opp.AccountId != null){
                    accountSet.add(opp.AccountId);
                    if((oldMap != null && oldMap.containsKey(opp.Id)) || opp.Update_BD_Stage_From_Account__c){ //if update
                        parentOppIdSet.add(opp.Id);
                    }
                }
            }

            //get contact related with account
            List<AccountContactRelation> accContactList = [SELECT Id, AccountId, ContactId, Contact.Decision_Making_Role__c FROM AccountContactRelation WHERE AccountId IN :accountSet];
            if(accContactList != null && !accContactList.isEmpty()){
                //store accounts with PIC contact
                accRoleMap = getAccContactRelationRoles(accContactList);
            }

            //get contact related with opportunity
            if(!parentOppIdSet.isEmpty()){
                oppContactRoleMap = getOppContactRoles(parentOppIdSet);

                for(Xendit_Opportunity_Product__c xOpp : [SELECT Grand_Parent_Opportunity_ID__c, Id FROM Xendit_Opportunity_Product__c WHERE Grand_Parent_Opportunity_ID__c IN :parentOppIdSet]){
                    if(!oppProductMap.containsKey(xOpp.Grand_Parent_Opportunity_ID__c)){
                        oppProductMap.put(xOpp.Grand_Parent_Opportunity_ID__c, new List<Xendit_Opportunity_Product__c>{xOpp});
                    }else{
                        oppProductMap.get(xOpp.Grand_Parent_Opportunity_ID__c).add(xOpp);
                    }
                }
            }

            //get account details
            Map<Id, Account> accountDetailsMap = new Map<Id, Account>([SELECT Id, Website, Segment__c, Number_of_Employees_Lead_Qual__c, Expected_Transaction_Volume__c, Estimated_Transactions_Handle_Each_Month__c, Average_Transaction_Size_Lead_Qual__c 
                                                FROM Account WHERE Id IN :accountSet ]);

            for(Opportunity opp : listNew){
                if(opp.RecordTypeId == idRTParent && opp.StageName == 'Qualification' && opp.BD_Prospecting_Stage__c != '100%'){
                    Account acc = (accountDetailsMap != null && accountDetailsMap.containsKey(opp.AccountId)) ? accountDetailsMap.get(opp.AccountId) : null;
                    Boolean QualStage = (opp.StageName == 'Qualification');
                    Boolean hasAccPICContact = accRoleMap.containsKey(opp.AccountId) &&
                                                (accRoleMap.get(opp.AccountId).contains('PIC') || accRoleMap.get(opp.AccountId).contains('Founder / Owner / Director') || accRoleMap.get(opp.AccountId).contains('Founder, Owner, Director'));
                    Boolean hasOppPICContact = (oldMap != null || opp.Update_BD_Stage_From_Account__c) && oppContactRoleMap.containsKey(opp.Id) && 
                                                (oppContactRoleMap.get(opp.Id).contains('PIC') || oppContactRoleMap.get(opp.Id).contains('Founder / Owner / Director') || oppContactRoleMap.get(opp.Id).contains('Founder, Owner, Director'));
                    Boolean completedResearchFields = acc != null && !String.isEmpty(acc.Website) && !String.isEmpty(acc.Segment__c) && !String.isEmpty(acc.Number_of_Employees_Lead_Qual__c) && 
                                                ( !String.isEmpty(acc.Expected_Transaction_Volume__c) || !String.isEmpty(acc.Estimated_Transactions_Handle_Each_Month__c) || !String.isEmpty(acc.Average_Transaction_Size_Lead_Qual__c)) && 
                                                (hasAccPICContact || hasOppPICContact);
                    Boolean completedQualFields = (oldMap != null || opp.Update_BD_Stage_From_Account__c) && oppProductMap.containsKey(opp.Id) && opp.Xst_Txn_Act_Date__c != null && !String.isEmpty(opp.Pains_Priorities_and_Needs__c) && !String.isEmpty(opp.Next_Step_Blockers__c);
                    
                    if(oldMap == null){
                        //25% - Creation of S1 Oppty
                        opp.BD_Prospecting_Stage__c = '25%';
                    }
                    if(completedResearchFields){
                        //50% - Research - website, segment, employee size and estimated monthly volume filled, PIC Contact
                        opp.BD_Prospecting_Stage__c = '50%';
                    }
                    if(completedResearchFields && completedQualFields){
                        // 75% - BDR has done qualification but discovery with Sales has not happened yet, but customer has agreed for the meeting already
                        // BDR has completed, 1st Txn Date, Added at least 1 product?, Pain prioties and needs, next steps and blockers, website, segment, employee size and estimated monthly volume filled, PIC Contact
                        opp.BD_Prospecting_Stage__c = '75%';
                    }
                    //100% - Meeting with Sales has happened : auto updated once opportunity has moved to stage 2 by sales --> in Opportunity Flow Before Save
                }

                if(opp.Update_BD_Stage_From_Account__c){
                    opp.Update_BD_Stage_From_Account__c = false;
                }
            }
        }catch(DmlException e){
            Set<String> errmsgList = new Set<String>();
            for (Integer i = 0; i < e.getNumDml(); i++) {
                // Process exception here
                errmsgList.add(e.getDmlMessage(i)); 
            }

            String errMsg = String.join(new List<String>(errmsgList), '\n');
            listNew[0].addError(errMsg);
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('OpportunityHelper','Opportunity', 'setBDProspectingStage', 'OpportunityTrigger',  e);
        }
    }

    /*
    Method Name: checkParentOpportunityApproval
    Description: function to check if eligible to update parent opp owner based on opp approval status
    */
    public static void checkParentOpportunityPricingApproval(List<Opportunity> listNew, Map<Id, Opportunity> mapOld, Boolean isBefore){
        system.debug('go to checkParentOpportunityPricingApproval');
        String parentRecType = getParentRecordTypeId();
        String pricingApprovalRecType = XenditOppApproval_TriggerHandler.getPricingApprRecordTypeId();
        List<Opportunity> parentOppList = new List<Opportunity>();
        List<Opportunity_Approval__c> updateOppApprList = new List<Opportunity_Approval__c>();
        Map<Id, Set<Id>> oppApprovalMap = new Map<Id, Set<Id>>();
        Set<Id> parentOppIdSet = new Set<Id>();
        for(Opportunity opp : listNew){
            Opportunity oldOpp = mapOld.get(opp.Id);
            if(opp.RecordTypeId == parentRecType && opp.OwnerId != oldOpp.OwnerId){
                parentOppList.add(opp);
                parentOppIdSet.add(opp.Id);
            }
        }

        if(!parentOppIdSet.isEmpty()){
            String strApproved = System.Label.OPP_APPROVAL_STATUS_APPROVED;
            for(Opportunity_Approval__c appr : [SELECT Id, Opportunity__c, Status__c FROM Opportunity_Approval__c WHERE Opportunity__c IN :parentOppIdSet AND RecordTypeId =: pricingApprovalRecType AND Status__c != :strApproved]){
                if(!oppApprovalMap.containsKey(appr.Opportunity__c)){
                    oppApprovalMap.put(appr.Opportunity__c, new Set<Id>{appr.Id});
                }else{
                    oppApprovalMap.get(appr.Opportunity__c).add(appr.Id);
                }
            }

            for(Opportunity opp : parentOppList){
                if(oppApprovalMap.containsKey(opp.Id)){
                    for(Id apprId : oppApprovalMap.get(opp.Id)){
                        Boolean isApprovalLocked = Approval.isLocked(apprId);
                        if(isApprovalLocked){
                            if(isBefore){
                                opp.addError('You cannot update opportunity owner because there is ongoing pricing approval process');
                            }
                        }else{
                            updateOppApprList.add(new Opportunity_Approval__c(Id = apprId, Opportunity_Owner_Update__c = true));
                        }
                    }
                }
            }

            if(!updateOppApprList.isEmpty() && !isBefore){
                try{
                    update updateOppApprList;
                }catch(DmlException e){
                    Set<String> errmsgList = new Set<String>();
                    for (Integer i = 0; i < e.getNumDml(); i++) {
                        // Process exception here
                        errmsgList.add(e.getDmlMessage(i)); 
                    }
        
                    String errMsg = String.join(new List<String>(errmsgList), '\n');
                    listNew[0].addError(errMsg);
                }catch(Exception e){
                    ExceptionUtility.createExceptionLog('OpportunityHelper','Opportunity', 'checkParentOpportunityPricingApproval', 'OpportunityTrigger',  e);
                }
            }
        }
    }

    /*
    MethodName: UpdateOppStageWithContactRole
    Description: function to update contact role's campaign member status everytime opp stage is moving forward
    */
    public static void UpdateOppStageWithContactRole(List<Opportunity> listNew, Map<Id, Opportunity> mapOld){
        try{
            system.debug('UpdateOppStageWithContactRole start');
            Set<Id> updatedOppIdSet = new Set<Id>();
            String parentRecTypeId = getParentRecordTypeId();
            Map<String, Integer> mapStageOrder = getStageMap();
            for(Opportunity opp : listNew){
                if(opp.RecordTypeId == parentRecTypeId && mapOld.get(opp.Id).StageName != opp.StageName && mapStageOrder.get(opp.StageName) > mapStageOrder.get(mapOld.get(opp.Id).StageName) && opp.StageName != 'Closed Lost'){
                    updatedOppIdSet.add(opp.Id);
                }
            }

            if(!updatedOppIdSet.isEmpty()){
                updateCampaignMemberStatus(updatedOppIdSet);
                // if( Limits.getQueueableJobs() == 1 ){
                //     updateCampaignMemberStatus(updatedOppIdSet);
                // }
                // else{
                //      System.enqueueJob(new UpdateCampaignMemberStatusQueueable(updatedOppIdSet));
                // }                
            }else{
                system.debug('updatedOppIdSet empty');
            }
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('OpportunityHelper','Opportunity', 'UpdateOppStageWithContactRole', 'OpportunityTrigger',  e);
        }
    }
    /*
    Method Name: updateCampaignMemberStatus
    Description: function to update campaign member status to Converted
    */
    public static void updateCampaignMemberStatus(Set<Id> oppIdSet){
        try{
            system.debug('updateCampaignMemberStatus start');
            Set<Id> contactIdSet = new Set<Id>();
            Set<Id> campaignIdSet = new Set<Id>();
            Map<Id, Set<Id>> oppContactIdMap = new Map<Id, Set<Id>>();
            Map<Id, List<String>> respondedCampaignStatusMap = new Map<Id, List<String>>();
            List<CampaignMember> updateCampaignMemberList = new List<CampaignMember>();
            String autoUpdateCampaignMemberStatus = System.Label.AUTO_CREATE_OPP_CAMPAIGN_MEMBER_STATUS;
            for(OpportunityContactRole ocr : [SELECT ContactId, OpportunityId FROM OpportunityContactRole WHERE ContactId != NULL AND OpportunityId IN :oppIdSet]){
                contactIdSet.add(ocr.ContactId);
                if(!oppContactIdMap.containsKey(ocr.OpportunityId)){
                    oppContactIdMap.put(ocr.OpportunityId, new Set<Id>{ocr.ContactId});
                }else{
                    oppContactIdMap.get(ocr.OpportunityId).add(ocr.ContactId);
                }
            }

            if(!contactIdSet.isEmpty()){
                system.debug('contactIdSet not empty');

                //comment out start - because only update stage moving forward to Stage Advanced when the Status value is Tactic Engaged
                // List<CampaignMember> campaignMemberList = [SELECT Id, CampaignId, Campaign.Objective__c, ContactId, Status FROM CampaignMember WHERE CampaignId != NULL AND Campaign.Objective__c = 'Pipe Progression' AND Campaign.IsActive = TRUE AND ContactId IN :contactIdSet];
                // for(CampaignMember cm : campaignMemberList){
                //     campaignIdSet.add(cm.CampaignId);
                // }

                // if(!campaignIdSet.isEmpty()){
                //     system.debug('campaignIdSet not empty');
                //     Map<Id, String> defaultCampaignRespondedStatusMap = getPipeProgCampaignRespondedStatus(campaignIdSet);
                //     for(CampaignMemberStatus cms: [SELECT Id, CampaignId, HasResponded, Label FROM CampaignMemberStatus WHERE CampaignId IN :campaignIdSet]){
                //         if(cms.HasResponded && cms.Label != autoUpdateCampaignMemberStatus){ //exclude Tactic Engaged from Responded
                //             if(!respondedCampaignStatusMap.containsKey(cms.CampaignId)){
                //                 respondedCampaignStatusMap.put(cms.CampaignId, new List<String>{cms.Label});
                //             }else{
                //                 respondedCampaignStatusMap.get(cms.CampaignId).add(cms.Label);
                //             }
                //         }
                //     }

                //     for(CampaignMember cm : campaignMemberList){
                //         if(cm.Status == autoUpdateCampaignMemberStatus && respondedCampaignStatusMap.containsKey(cm.CampaignId)){
                //             List<String> getRespondedStatuses = respondedCampaignStatusMap.get(cm.CampaignId);
                //             String hasRespondedStatus = getRespondedStatuses[0];
                //             // if(getRespondedStatuses.contains(autoUpdateCampaignMemberStatus)){
                //             //     hasRespondedStatus = autoUpdateCampaignMemberStatus;
                //             // }else 
                //             if(respondedCampaignStatusMap.get(cm.CampaignId).size() > 1 && defaultCampaignRespondedStatusMap.containsKey(cm.CampaignId) && respondedCampaignStatusMap.get(cm.CampaignId).contains(defaultCampaignRespondedStatusMap.get(cm.CampaignId))){
                //                 //get value from custom metadata Responded status
                //                 hasRespondedStatus = defaultCampaignRespondedStatusMap.get(cm.CampaignId);
                //             }

                //             system.debug('hasRespondedStatus : ' + hasRespondedStatus);
                //             if(!getRespondedStatuses.contains(cm.Status)){
                //                 updateCampaignMemberList.add(new CampaignMember(Id = cm.Id, Status = hasRespondedStatus));
                //             }
                //         }
                //     }

                //     if(!updateCampaignMemberList.isEmpty()){
                //         update updateCampaignMemberList;                    
                //     }
                // }
                //comment out end

                //add Stage Advanced logic here
                CreateCampaignInfluenceForStageAdvance(oppContactIdMap);
            }
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('OpportunityHelper','Opportunity', 'updateCampaignMemberStatus', 'OpportunityTrigger',  e);
        }
    }

    // public static Map<Id, String> getPipeProgCampaignRespondedStatus(Set<Id> campaignId){
    //     Map<Id, String> returnValMap = new Map<Id, String>();
    //     List<Default_Campaign_Member_Status__mdt> defaultStatusMdt = [SELECT Id, Campaign_Hierarchy__c, Responded_Status__c, Objective__c, Offer_Type__c, Tactics_Type__c FROM Default_Campaign_Member_Status__mdt WHERE Responded_Status__c != NULL];
    //     for(Campaign c : [SELECT Id, Objective__c, Offer_Type__c, Tactics_Type__c, RecordType.DeveloperName FROM Campaign WHERE Id IN :campaignId]){
    //         for(Default_Campaign_Member_Status__mdt statusMdt : defaultStatusMdt){
    //             String recTypeName = c.RecordType.DeveloperName;
    //             Boolean isValid = (recTypeName == 'Master_Campaign' && statusMdt.Campaign_Hierarchy__c == 'Master' && statusMdt.Objective__c == c.Objective__c) ||
    //                               (recTypeName == 'Program_Campaign' && statusMdt.Campaign_Hierarchy__c == 'Program' && statusMdt.Objective__c == c.Objective__c && statusMdt.Offer_Type__c == c.Offer_Type__c) ||
    //                               (recTypeName == 'Tactic_Campaign' && statusMdt.Campaign_Hierarchy__c == 'Tactic' && statusMdt.Tactics_Type__c == c.Tactics_Type__c);
    //             if(isValid){
    //                 returnValMap.put(c.Id, statusMdt.Responded_Status__c);
    //                 break;
    //             }
    //         }
    //     }
    //     return returnValMap;
    // }

    public static void CreateCampaignInfluenceForStageAdvance(Map<Id, Set<Id>> oppContactIdMap){
        String defaultCampInflModelLabel = System.Label.CAMPAIGN_INFLUENCE_MODEL_DEFAULT;
        CampaignInfluenceModel defaultModel = [SELECT Id FROM CampaignInfluenceModel WHERE MasterLabel = :defaultCampInflModelLabel LIMIT 1];
        for(Id oppId : oppContactIdMap.keySet()){
            Set<Id> contactIdSet = oppContactIdMap.get(oppId);
            CreateLeadOppCampInfluenceBatch cx = new CreateLeadOppCampInfluenceBatch(null, contactIdSet, oppId, defaultModel.Id, 'STAGE_ADVANCED_OPP');
            Database.executeBatch(cx, 200); 
        }
    }

    /*
    Name : UpdateCampaignMemberStatusClosedWon
    Description : update camp member status when opportunity is CW
    */
    public static void UpdateCampaignMemberStatusClosedWon(List<Opportunity> listNew, Map<Id, Opportunity> oldMap){
        try{
            Set<Id> updateOpportunityIdSet = new Set<Id>();
            Map<String, Map<Id, Set<Id>>> updateCampaignContactObjectiveMap = new Map<String, Map<Id, Set<Id>>>();
            List<String> objectiveList = new List<String>{'New active merchant acquired','Products Activated / Cross-sell','Upsell'};
            for(Opportunity o : listNew){
                Opportunity oldOpp = oldMap.get(o.Id);
                if(oldOpp.StageName != o.StageName && o.StageName == 'Closed Won'){ // if updated to CW
                    updateOpportunityIdSet.add(o.Id);
                }
            }

            if(!updateOpportunityIdSet.isEmpty()){
                //get related campaign influence
                for(CampaignInfluence ci : [SELECT CampaignId, Campaign.Objective__c, ContactId FROM CampaignInfluence WHERE Campaign.Objective__c != NULL AND OpportunityId IN :updateOpportunityIdSet]){
                    Map<Id, Set<Id>> campaignContactMap = new Map<Id, Set<Id>>();
                    if(!updateCampaignContactObjectiveMap.containsKey(ci.Campaign.Objective__c)){
                        campaignContactMap.put(ci.CampaignId, new Set<Id>{ci.ContactId});
                    }else{
                        campaignContactMap = updateCampaignContactObjectiveMap.get(ci.Campaign.Objective__c);
                        Set<Id> contactIds = campaignContactMap.get(ci.CampaignId);
                        contactIds.add(ci.ContactId);
                        campaignContactMap.put(ci.CampaignId, contactIds);
                    }
                    updateCampaignContactObjectiveMap.put(ci.Campaign.Objective__c, campaignContactMap);
                }

                if(!updateCampaignContactObjectiveMap.isEmpty()){
                    for(String obj : updateCampaignContactObjectiveMap.keySet()){
                        if(objectiveList.contains(obj)){
                            Map<Id, Set<Id>> campaignContactMap = updateCampaignContactObjectiveMap.get(obj);
                            Set<Id> contIdSet = new Set<Id>();
                            for(Id campaignId : campaignContactMap.keySet()){
                                contIdSet.addAll(campaignContactMap.get(campaignId));
                            }
                            AutoUpdateCampaignMemberStatusBatch cx = new AutoUpdateCampaignMemberStatusBatch(campaignContactMap.keySet(), null, contIdSet, obj);
                            Database.executeBatch(cx, 200);
                        }
                    }
                }
                
            }
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('OpportunityHelper','Opportunity', 'UpdateCampaignMemberStatusClosedWon', 'OpportunityTrigger',  e);
        }
    }

    /*
    Name : updateOpportunityStageAndBDProspecting
    Description : update oppty stage back to Qualification when assigned to BDR
    */
    public static void updateOpportunityStageAndBDProspecting(List<Opportunity> listNew, Map<Id, Opportunity> oldMap){
        try{
            List<Opportunity> opportunityToUpdate = new List<Opportunity>();
            Set<Id> updatedOwnerIds = new Set<Id>();
        
            // Retrieve the new Opportunity Owner roles for all updated Opportunities
            for (Opportunity opp : listNew) {
                if (opp.OwnerId != oldMap.get(opp.Id).OwnerId) {
                    updatedOwnerIds.add(opp.OwnerId);
                    updatedOwnerIds.add(oldMap.get(opp.Id).OwnerId);
                    opportunityToUpdate.add(opp);
                }
            }
            
            if(opportunityToUpdate.size()> 0){
                Map<Id, User> userRoleMap = new Map<Id, User>([SELECT id, UserRole.Name, LastName FROM User WHERE Id IN :updatedOwnerIds]);
                for (Opportunity opp : opportunityToUpdate) {
                    Opportunity oldOpp = oldMap.get(opp.Id);
                    User oldOwner = userRoleMap.get(oldOpp.OwnerId);
                    User newOwner = userRoleMap.get(opp.OwnerId);
                    Boolean isBDR = (newOwner.UserRole.Name.Contains('BDR'));
                    if (isBDR && (opp.Pipeline_Source__c == 'Undeclared Interest' || oldOwner.LastName == 'Self Serve') && (opp.StageName == 'Contracting'|| opp.stageName == 'Integration')) {
                        opp.Probability__c = '0%';
                    	opp.BD_Prospecting_Stage__c = '25%';
                        opp.StageName = 'Qualification';
                        opp.BD_Owner__c = opp.OwnerId;
                        opp.Stage_2_Flag__c = null;
                        opp.Stage_2_Date__c = null;
                    }
                }
            }
        }catch(Exception e){
            ExceptionUtility.createExceptionLog('OpportunityHelper','Opportunity', 'updateOpportunityStageAndBDProspecting', 'OpportunityTrigger',  e);
        }
    }
	
    public static void updateUpsellApproval(List<Opportunity> listNew, Map<Id, Opportunity> oldMap){
        List<Opportunity> lsParentOpp = new List<Opportunity>();
        for (Opportunity opp : listNew) {
            if (oldMap != null && (opp.Pricing_Approval__c != oldMap.get(opp.Id).Pricing_Approval__c || (opp.Type != oldMap.get(opp.Id).Type && opp.Type != 'Upsell')) && opp.Pricing_Approval__c != 'No Approval Required' && opp.Pricing_Approval__c  != null) {
                System.debug('***upsell from parent 1');
                opp.Upsell_Approval__c = 'No Approval Required';
            }else if(oldMap != null && opp.Pricing_Approval__c == 'No Approval Required' && opp.Type != oldMap.get(opp.Id).Type && opp.Type == 'Upsell' && !opp.Created_via_Campaign__c){
                System.debug('***upsell from parent 2');
                opp.Upsell_Approval__c = 'Approval Required';
            }else if(opp.Created_via_Campaign__c && opp.Type == 'Upsell' && opp.Upsell_Approval__c == null){
                System.debug('***upsell from parent 3');
                opp.Upsell_Approval__c = 'No Approval Required';
            }
        }
    }

    public static void getUpsellRevenueGoalValue(List<Opportunity> listNew, Map<Id, Opportunity> oldMap, String triggeringObject){
        Id parentRecordTypeId = getParentRecordTypeId();
        Set<Id> opportunityIds = new Set<Id>();
        List<Opportunity> opportunityToProcess = new List<Opportunity>();
        for (Opportunity opp : listNew) {
            Opportunity oldOpp = oldMap != null && !oldMap.isEmpty() ? oldMap.get(opp.Id) : null;
            //Only process record with specific field changes
            if (opp.Created_via_Campaign__c && opp.Type == 'Upsell' && opp.StageName == 'Contracting' && (oldOpp == null || opp.StageName != oldOpp.StageName) && opp.RecordTypeId == parentRecordTypeId) {
                OpportunityIds.add(opp.Id);
                opportunityToProcess.add(opp);
            } else if (opp.Type == 'Upsell' && opp.StageName == 'Contracting' && !opp.Created_via_Campaign__c) {
                system.debug('***2');
                opp.Upsell_Opportunity_Revenue_Goal__c = opp.Addressable_Merchant_Revenue_Monthly_USD__c != null ? opp.Addressable_Merchant_Revenue_Monthly_USD__c  / 4 : null;
            }
        }
        system.debug('***OppIds: ' +opportunityIds);
        if (opportunityIds.size() > 0) {
            //Get list of products under child oppty, group it by parent opportunity id
            Set<String> bizProdIdChannels = new Set<String>();
            Map<String, List<Xendit_Opportunity_Product__c>> oppProductMap = new Map<String, List<Xendit_Opportunity_Product__c>>();
            for (Xendit_Opportunity_Product__c xop : [SELECT Id, Name, BizIDPrdChannel__c, Opportunity__c, Opportunity__r.AccountId, Opportunity__r.Parent_Opportunity__c FROM Xendit_Opportunity_Product__c WHERE Opportunity__r.Parent_Opportunity__c IN :opportunityIds]) {
                bizProdIdChannels.add(xop.BizIDPrdChannel__c);
                if(oppProductMap.containsKey(xop.Opportunity__r.Parent_Opportunity__c)) {
                    List<Xendit_Opportunity_Product__c> prodList = oppProductMap.get(xop.Opportunity__r.Parent_Opportunity__c);
                    prodList.add(xop);
                    oppProductMap.put(xop.Opportunity__r.Parent_Opportunity__c, prodList);
                } else {
                    oppProductMap.put(xop.Opportunity__r.Parent_Opportunity__c, new List<Xendit_Opportunity_Product__c> { xop });
                }
            }
            system.debug('***bizProdIdChannels: ' +bizProdIdChannels);
            system.debug('***oppProductMap: ' +oppProductMap);
            //Continue logic if products found
            if (bizProdIdChannels.size() > 0) {
                //Get list of transaction for each products
                Map<String, Transaction__c> mapMonthlyTransactionByBizProdId = new Map<String, Transaction__c>();
                Map<String, Transaction__c> mapWeeklyTransactionByBizProdId = new Map<String, Transaction__c>();
                for (Transaction__c tc : [SELECT Id, BizIDPrdChannel__c, Revenue_USD__c, Date__c, Aggregated_Type__c FROM Transaction__c WHERE ((Date__c = LAST_N_MONTHS:2 AND Aggregated_Type__c = 'Monthly') OR (Aggregated_Type__c = 'Weekly' AND Date__c = LAST_WEEK)) AND BizIDPrdChannel__c IN :bizProdIdChannels ORDER BY BizIDPrdChannel__c, Date__c]) {
                    if (tc.Aggregated_Type__c == 'Monthly') {
                        String tnxMonth = String.valueOf(tc.Date__c.month());
                        String mapKey = tc.BizIDPrdChannel__c + '_' + tc.Aggregated_Type__c + '_' + tnxMonth;
                        mapMonthlyTransactionByBizProdId.put(mapKey, tc);
                    } else if (tc.Aggregated_Type__c == 'Weekly') {
                        String mapKey = tc.BizIDPrdChannel__c + '_' + tc.Aggregated_Type__c;
                        mapWeeklyTransactionByBizProdId.put(mapKey, tc);
                    }
                }
                system.debug('***mapWeeklyTransactionByBizProdId: ' +mapWeeklyTransactionByBizProdId);
                system.debug('***mapMonthlyTransactionByBizProdId: ' +mapMonthlyTransactionByBizProdId);
                //Group transaction by opportunity
                Map<String, Decimal> mapOpportunityMonthlyRevenue = new Map<String, Decimal>();
                Map<String, Decimal> mapOpportunityWeeklyRevenue = new Map<String, Decimal>();
                Set<String> opportunityToExclude = new Set<String>();
                for (List<Xendit_Opportunity_Product__c> xopList : oppProductMap.values()) {
                    for (Xendit_Opportunity_Product__c xop : xopList) {
                        String tnxMonth1 = String.valueOf(Date.Today().addMonths(-1).month());
                        String tnxMonth2 = String.valueOf(Date.Today().addMonths(-2).month());
                        String mapKeyMonth1 = xop.BizIDPrdChannel__c + '_Monthly_' + tnxMonth1;
                        String mapKeyMonth2 = xop.BizIDPrdChannel__c + '_Monthly_' + tnxMonth2;

                        //check if opportunity has 2 months full txn
                        Boolean upsellCW = false;
                        if (mapMonthlyTransactionByBizProdId != null && !mapMonthlyTransactionByBizProdId.isEmpty() && mapMonthlyTransactionByBizProdId.get(mapKeyMonth2) != null) {
                            upsellCW = true;
                        } else {
                            opportunityToExclude.add(xop.Opportunity__r.Parent_Opportunity__c);
                        }

                        if (upsellCW) {
                            //Last month revenue
                            if (mapMonthlyTransactionByBizProdId.get(mapKeyMonth1) != null) {
                                String opportunityMonthKey = xop.Opportunity__r.Parent_Opportunity__c + '_1';
                                if (mapOpportunityMonthlyRevenue.containsKey(opportunityMonthKey)) {
                                    Decimal tempRev = mapOpportunityMonthlyRevenue.get(opportunityMonthKey) + mapMonthlyTransactionByBizProdId.get(mapKeyMonth1).Revenue_USD__c;
                                    mapOpportunityMonthlyRevenue.put(opportunityMonthKey, tempRev);
                                } else {
                                    mapOpportunityMonthlyRevenue.put(opportunityMonthKey, mapMonthlyTransactionByBizProdId.get(mapKeyMonth1).Revenue_USD__c);
                                }
                            }

                            //Last 2 months revenue
                            if (mapMonthlyTransactionByBizProdId.get(mapKeyMonth2) != null) {
                                String opportunityMonthKey = xop.Opportunity__r.Parent_Opportunity__c + '_2';
                                if (mapOpportunityMonthlyRevenue.containsKey(opportunityMonthKey)) {
                                    Decimal tempRev = mapOpportunityMonthlyRevenue.get(opportunityMonthKey) + mapMonthlyTransactionByBizProdId.get(mapKeyMonth2).Revenue_USD__c;
                                    mapOpportunityMonthlyRevenue.put(opportunityMonthKey, tempRev);
                                } else {
                                    mapOpportunityMonthlyRevenue.put(opportunityMonthKey, mapMonthlyTransactionByBizProdId.get(mapKeyMonth2).Revenue_USD__c);
                                }
                            }
                            system.debug('***mapWeeklyTransactionByBizProdId'+ mapWeeklyTransactionByBizProdId);
                            //Last week revenue
                            String mapKeyWeek = xop.BizIDPrdChannel__c + '_Weekly';
                            if (mapWeeklyTransactionByBizProdId != null && mapWeeklyTransactionByBizProdId.get(mapKeyWeek) != null) {
                                String opportunityWeeklyKey = xop.Opportunity__r.Parent_Opportunity__c + '_1';
                                mapOpportunityWeeklyRevenue.put(opportunityWeeklyKey, mapWeeklyTransactionByBizProdId.get(mapKeyWeek).Revenue_USD__c);
                            }
                        }
                    }
                }
                
                List<Opportunity> opportunityToUpdate = new List<Opportunity>();
                for (Opportunity opp : opportunityToProcess) {
                    String mapKey1 = opp.Id + '_1';
                    String mapKey2 = opp.Id + '_2';
                    if (mapOpportunityMonthlyRevenue != null && !mapOpportunityMonthlyRevenue.isEmpty() && mapOpportunityMonthlyRevenue.get(mapKey1) != null && mapOpportunityMonthlyRevenue.get(mapKey2) != null) {
                        //MoM Growth = (Total Revenue USD last month - Total Revenue USD last 2 months) / Total Revenue USD last 2 months
                        Double momGrowth = (mapOpportunityMonthlyRevenue.get(mapKey1) - mapOpportunityMonthlyRevenue.get(mapKey2)) / mapOpportunityMonthlyRevenue.get(mapKey2);
                        Double baseValue = 1.0 + momGrowth;
                        Double exponent = 1.0 / 4.0;

                        //Weekly Growth =(1+ {MoM Growth})^(1/4)-1
                        Double weeklyGrowth = Math.pow(baseValue, exponent) - 1.0;
                        system.debug('***MoM Growth: '+ momGrowth);
                        system.debug('***Weekly Growth: '+ weeklyGrowth);

                        //Calculate CW criteria = {Last Week Revenue} * (Weekly Growth + 1)
                        Double upsellCWCriteria = null;
                        system.debug('***Check: '+ mapOpportunityWeeklyRevenue);
                        if (mapOpportunityWeeklyRevenue != null && mapOpportunityWeeklyRevenue.get(opp.Id + '_1') != null) {
                            upsellCWCriteria = mapOpportunityWeeklyRevenue.get(opp.Id + '_1') * (weeklyGrowth + 1);
                            system.debug('***CW Criteria: '+ upsellCWCriteria);

                            if (triggeringObject == 'Opportunity') {
                                opp.Upsell_Opportunity_Revenue_Goal__c = upsellCWCriteria;
                            } else if (triggeringObject == 'Campaign') {
                                Opportunity oppUpdt = new Opportunity();
                                oppUpdt.Id = opp.Id;
                                oppUpdt.Upsell_Opportunity_Revenue_Goal__c = upsellCWCriteria;
                                opportunityToUpdate.add(oppUpdt);
                            }
                        }
                    }
                }

                //Only do DML if method triggered outside opportunity trigger
                if (opportunityToUpdate.size() > 0) {
                    TriggerBypassUtility.opportunityTriggerBypass = true;
                    update opportunityToUpdate;
                }
            }
        }
    }

    public static void getHIRO(List<Opportunity> listNew, Map<Id, Opportunity> oldMap){
        Id idRTParent = getParentRecordTypeId();
        List<Opportunity> filteredOpportunities = new List<Opportunity>();
        for (Opportunity opp : listNew) {
            Opportunity oldOpp = oldMap != null && !oldMap.isEmpty() ? oldMap.get(opp.Id) : null;
            if ((opp.HIRO_Stage__c == null || opp.HIRO_Stage__c == '') && opp.StageName != oldOpp.StageName && opp.RecordTypeId == idRTParent) {
                filteredOpportunities.add(opp);
            }
        }

        if (filteredOpportunities.size() > 0) {
            Map<String, HIRO_Percentage__c> hiroMap = new Map<String, HIRO_Percentage__c>();
            for (HIRO_Percentage__c hiro : [SELECT External_Id__c, HIRO_Percentage__c, HIRO__c FROM HIRO_Percentage__c WHERE Date__c = THIS_MONTH]) {
                hiroMap.put(hiro.External_Id__c, hiro);
            }

            for (Opportunity opp : filteredOpportunities) {
                String mapKey = opp.Pipeline_Source__c + '_' + opp.StageName;
                if (hiroMap.get(mapKey) != null && hiroMap.get(mapKey).HIRO__c) {
                    opp.HIRO_Stage__c = opp.StageName;
                    opp.Marked_As_HIRO_Before__c = hiroMap.get(mapKey).HIRO__c;
                    if (opp.StageName == 'Qualification') {
                        opp.HIRO_Stage_Date__c = opp.Qualification_Date__c;
                    } if (opp.StageName == 'Discovery') {
                        opp.HIRO_Stage_Date__c = opp.Discovery_Date__c;
                    } if (opp.StageName == 'Evaluation') {
                        opp.HIRO_Stage_Date__c = opp.Evaluation_Date__c;
                    } if (opp.StageName == 'Negotiation') {
                        opp.HIRO_Stage_Date__c = opp.Negotiation_Date__c;
                    } if (opp.StageName == 'Contracting') {
                        opp.HIRO_Stage_Date__c = opp.Onboarding_Contracting_Date__c;
                    } if (opp.StageName == 'Integration') {
                        opp.HIRO_Stage_Date__c = opp.Integration_Date__c;
                    } if (opp.StageName == 'Activation') {
                        opp.HIRO_Stage_Date__c = opp.Activation_Date__c;
                    }
                } else if (hiroMap.get(mapKey) != null && !hiroMap.get(mapKey).HIRO__c) {
                    opp.HIRO_Stage__c = null;
                    opp.HIRO_Stage_Date__c = null;
                }
            }
        }
    }
}