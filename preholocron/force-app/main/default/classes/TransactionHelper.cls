/** helper related to Transaction object */
public class TransactionHelper {

    // update some fields before save (for update)
    public static void updateFieldsBeforeSave(Transaction__c[] listNew, Transaction__c[] listOld) 
    {
        
        for(Transaction__c T: listNew)
        {
            T.BizIDPrd__c = T.BizIDPrdChannel__c;
        }
    }
    

    // check total transaction and update respective opportunity stage
    public static void CheckOpportunityStage(Transaction__c[] listNew, Transaction__c[] listOld)
    {
        try{
            Set<String> stBizCode = new Set<String>();
            Set<String> stChannel = new Set<String>();
            Set<String> stOppIds = new Set<String>();
            List<Opportunity> lsUpdatedOpp = new List<Opportunity>();
            List<Xendit_Opportunity_Product__c> updateOppProductList = new List<Xendit_Opportunity_Product__c>(); //to update Opp Product
            Map<Id, Transaction__c> mapOld = new Map<Id, Transaction__c>();
            Set<Id> oppClosedWonExceptionId = new Set<Id>();
            Set<Id> xOPPIsVASProduct = new Set<Id>();
            Set<String> oppTypeException = new Set<String>{'Upsell','Renegotiation'};
            if (listOld != null) {
                for(Transaction__c T: listOld) {
                    mapOld.put(T.Id, T);
                }
            }
            for(Transaction__c T: listNew) {
                if (T.BizIDPrdChannel__c != null && (listOld == null || (T.Transaction_Count__c != mapOld.get(T.Id).Transaction_Count__c))) { 
                    stBizCode.add(T.BizIDPrdChannel__c);
                }
            }
            system.debug('DEBUG: biz code ' + stBizCode);
            
            // search
            Map<String, Integer> mapCount = new Map<String, Integer>();
            Map<String, Decimal> mapRevenue = new Map<String, Decimal>();
            Map<String, String> mapBizOpp = new Map<String, String>(); // opp id -> bizcode
            
            Integer intTmp;
            String strTmp;
            if (stBizCode.size() > 0) 
            {
                //get custom metadata for Segment CW Txn Count
                List<Segment_Based_CW_Txn_Count__mdt> segmentCWTxnCountList = [SELECT Id, DeveloperName, Txn_Count__c, API_Call__c FROM Segment_Based_CW_Txn_Count__mdt];

                // get Opp Product
                for(Xendit_Opportunity_Product__c X: [SELECT Opportunity__c, BizIDPrdChannel__c, Opportunity__r.Parent_Opportunity__c, Product__r.Exclude_Auto_Closed_Won__c,Product__r.Is_VAS_Product__c
                                                    FROM Xendit_Opportunity_Product__c
                                                    WHERE Opportunity__r.Account.Business_ID__c != null AND
                                                    Product__r.Name != null AND
                                                    BizIDPrdChannel__c IN :stBizCode
                                                        AND Opportunity__r.StageName NOT IN ('Closed Lost', 'Closed Won') ])
                {
                    if (X.Opportunity__c != null) {
                        //mapBizOpp.put(X.Opportunity__c , X.BizIDPrdChannel__c);
                        stOppIds.add(X.Opportunity__c);
                        if(X.Product__r.Exclude_Auto_Closed_Won__c == TRUE){ //prevent opportunity to auto Closed Won if Product Exclude Auto Closed Won = TRUE
                            oppClosedWonExceptionId.add(X.Opportunity__c);
                        }
                        if(X.Product__r.Is_VAS_Product__c){
                            xOPPIsVASProduct.add(X.Opportunity__c); //add vas logic
                        }
                    }
                    
                }
                system.debug('DEBUG: mapBizOPp ' + mapBizOpp);
                system.debug('DEBUG: xOPPIsVASProduct ' + xOPPIsVASProduct);

                
                // get all bizcode in an opportunity
                Map<Id, Set<String>> mapOppBizCode = new Map<Id, Set<String>>();

                //map between Opp <> [code <> xendit opp product]
                Map<Id, Map<String,Xendit_Opportunity_Product__c>> bizCodeOppProdMap = new Map<Id, Map<String,Xendit_Opportunity_Product__c>>();
                stBizCode = new Set<String>(); // reset
                Set<String> stTmp = new Set<String>();
                
                //get all Opportunity Product under related Opportunity
                for(Xendit_Opportunity_Product__c X: [SELECT Opportunity__c, BizIDPrdChannel__c, Opportunity__r.Parent_Opportunity__c, Is_Transacting_gt_5_Txn__c, Product__r.Is_VAS_Product__c
                                                    FROM Xendit_Opportunity_Product__c
                                                        WHERE Opportunity__c IN :stOppIds
                                                        AND Opportunity__r.StageName NOT IN ('Closed Lost', 'Closed Won') ])
                {
                    if (X.BizIDPrdChannel__c != null) 
                    {
                        // add to list code
                        stBizCode.add(X.BizIDPrdChannel__c);
                        stTmp = new Set<String>();
                        if (mapOppBizCode.get(X.Opportunity__c) != null) {
                            stTmp = mapOppBizCode.get(X.Opportunity__c);
                        }
                        stTmp.add(X.BizIDPrdChannel__c);

                        //map opp id <> set code
                        mapOppBizCode.put(X.Opportunity__c, stTmp);

                        //map Opp <> [code <> xendit opp product]
                        Map<String,Xendit_Opportunity_Product__c> xopMap = new Map<String,Xendit_Opportunity_Product__c>{X.BizIDPrdChannel__c => X};
                        if(!bizCodeOppProdMap.containsKey(X.Opportunity__c)){
                            bizCodeOppProdMap.put(X.Opportunity__c, xopMap);
                        }else{ 
                            bizCodeOppProdMap.get(X.Opportunity__c).put(X.BizIDPrdChannel__c, X);
                        }
                    }
                }
                
                // get total transaction add vas logic
                for(AggregateResult ar: [SELECT BizIDPrd__c, SUM(Transaction_Count__c) totalCount
                                        FROM Transaction__c WHERE BizIDPrd__c IN :stBizCode AND Aggregated_Type__c = 'Weekly'
                                        GROUP BY BizIDPrd__c ])
                {
                    intTmp = Integer.valueOf(ar.get('totalCount'));   
                    if (mapCount.get(String.valueOf(ar.get('BizIDPrd__c'))) != null) {
                        intTmp += mapCount.get(String.valueOf(ar.get('BizIDPrd__c')));
                    }
                    mapCount.put(String.valueOf(ar.get('BizIDPrd__c')), intTmp);
                }

                // get total revenue
                Decimal revenueTmp = 0;
                for(AggregateResult ar: [SELECT BizIDPrd__c, SUM(Revenue_USD__c) totalRevenue 
                                        FROM Transaction__c WHERE BizIDPrd__c IN :stBizCode AND Aggregated_Type__c = 'Weekly' AND Date__c = THIS_WEEK
                                        GROUP BY BizIDPrd__c ])
                {
                    system.debug('***Check Weekly Revenue: '+ ar);
                    revenueTmp = Decimal.valueOf(String.valueOf(ar.get('totalRevenue')));
                    if (mapRevenue.get(String.valueOf(ar.get('BizIDPrd__c'))) != null) {
                        revenueTmp += mapRevenue.get(String.valueOf(ar.get('BizIDPrd__c')));
                    }
                    mapRevenue.put(String.valueOf(ar.get('BizIDPrd__c')), revenueTmp);
                }
                system.debug('***This week revenue: '+ ((String)JSON.serialize(mapRevenue)));
                system.debug('DEBUG: mapOpp ' + mapOppBizCode);
                // select opportunity
                for(Opportunity O: [SELECT Id, Name, StageName, Type, Is_Transacting__c, Parent_Opportunity__r.Ready_to_Closed_Won__c, Account.Segment__c, Parent_Opportunity__r.Upsell_Opportunity_Revenue_Goal__c, Parent_Opportunity__r.StageName, Parent_Opportunity__r.Type FROM Opportunity 
                                    WHERE StageName NOT IN ('Closed Lost', 'Closed Won') 
                                    AND Type != 'Winback/Churn Recovery'
                                    AND Id IN :stOppIds ])
                {
                    intTmp = 0;
                    revenueTmp = 0;
                    // loop for each biz code to store all transaction count under each opportunity
                    if (mapOppBizCode.get(O.Id) != null) {

                        //set related xendit opp product transaction >= 5 to TRUE
                        for(String sCode: mapOppBizCode.get(O.Id)) {
                            if (mapCount.get(sCode) != null) {
                                intTmp += mapCount.get(sCode);
                            }
                            if (mapRevenue.get(sCode) != null) {
                                revenueTmp += mapRevenue.get(sCode);
                            }
                        }  
                        
                        if (intTmp > 0 && O.Parent_Opportunity__r.Type != 'Upsell') {
                            O.StageName = 'Activation';
                        }

                        //add vas logic
                        Boolean autoCWFromSegment;
                        if(xOPPIsVASProduct.contains(O.Id)){
                            autoCWFromSegment = isSegmentCW(segmentCWTxnCountList, O.Account.Segment__c, intTmp, 'isVAS');
                            system.debug('DEBUG: autoCWFromSegment IsVAS ' + autoCWFromSegment);
                            
                        }else{
                            autoCWFromSegment = isSegmentCW(segmentCWTxnCountList, O.Account.Segment__c, intTmp, 'isPG');
                            system.debug('DEBUG: autoCWFromSegment isPG ' + autoCWFromSegment);
                        }

                        if (autoCWFromSegment && !oppClosedWonExceptionId.contains(O.Id) && (!oppTypeException.contains(O.Type) || (autoCWFromSegment && !oppClosedWonExceptionId.contains(O.Id) && O.Parent_Opportunity__r.Type == 'Upsell' && (O.Parent_Opportunity__r.Upsell_Opportunity_Revenue_Goal__c == null || O.Parent_Opportunity__r.Upsell_Opportunity_Revenue_Goal__c == 0) && O.Parent_Opportunity__r.StageName == 'Contracting'))) {
                            if(O.Parent_Opportunity__r.Ready_to_Closed_Won__c){
                                O.StageName = 'Closed Won';
                            }else{
                                O.Is_Transacting__c = true;
                            }
                        } else if (O.Parent_Opportunity__r.Type == 'Upsell' && O.Parent_Opportunity__r.Upsell_Opportunity_Revenue_Goal__c != null && O.Parent_Opportunity__r.Upsell_Opportunity_Revenue_Goal__c != 0 && O.Parent_Opportunity__r.StageName == 'Contracting') {
                            if (revenueTmp >= O.Parent_Opportunity__r.Upsell_Opportunity_Revenue_Goal__c) {
                                O.StageName = 'Closed Won';
                            }
                        }

                        //validate all opp products under the opportunity
                        // if(bizCodeOppProdMap.containsKey(O.Id)){
                        //     Map<String, Xendit_Opportunity_Product__c> bizCodeXOPMap = bizCodeOppProdMap.get(O.Id);
                        //     Integer countValidTxn = 0;
                        //     //loop through all opp products based on biz code
                        //     for(String strCode : bizCodeXOPMap.keySet()){
                        //         Xendit_Opportunity_Product__c getXOP = bizCodeXOPMap.get(strCode);
                        //         Boolean transactionMoreThan5 =  mapOppBizCode.containsKey(O.Id) && mapOppBizCode.get(O.Id).contains(strCode) && 
                        //                                         mapCount.containsKey(strCode) && mapCount.get(strCode) >= 5;
                                
                        //         //populate Is Transacting (>=5) in Opp Product
                        //         Xendit_Opportunity_Product__c xop = new Xendit_Opportunity_Product__c(Id = getXOP.Id, Is_Transacting_gt_5_Txn__c = transactionMoreThan5);
                        //         if(transactionMoreThan5){
                        //             updateOppProductList.add(xop);
                        //             countValidTxn++;
                        //         } 
                        //     }

                        //     //update opp to CW
                        //     if(countValidTxn == bizCodeXOPMap.size() && !oppClosedWonExceptionId.contains(O.Id) && !oppTypeException.contains(O.Type)){
                        //         if(O.Parent_Opportunity__r.Ready_to_Closed_Won__c){
                        //             O.StageName = 'Closed Won';
                        //         }else{
                        //             O.Is_Transacting__c = true;
                        //         }
                        //     }
                            
                        // }
                        
                        lsUpdatedOpp.add(O);
                    }
                    
                }
            }
            
            if (lsUpdatedOpp.size() > 0) {
                update(lsUpdatedOpp);
            }

            if(!updateOppProductList.isEmpty()){
                update updateOppProductList;
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
            ExceptionUtility.createExceptionLog('TransactionHelper','Transaction__c', 'CheckOpportunityStage', 'TransactionTrigger',  e);
        } 
    }

    public static Boolean isSegmentCW(List<Segment_Based_CW_Txn_Count__mdt> mdtList, String segment, Integer txnCount, String categoryProduct){
        String tempSegment = !String.isBlank(segment) ? segment : 'Individual';
        Integer tempTxnCount = txnCount != null ? txnCount : 0;
        Boolean returnVal = false;
        for(Segment_Based_CW_Txn_Count__mdt mdt : mdtList){
            if(mdt.DeveloperName == tempSegment){
                if(categoryProduct == 'isVAS'){
                    returnVal = (tempTxnCount >= mdt.API_Call__c);
                }else{
                    returnVal = (tempTxnCount >= mdt.Txn_Count__c);
                }
                break;
            }
        }
        return returnVal;
    }
    
}