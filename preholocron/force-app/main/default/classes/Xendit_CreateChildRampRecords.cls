/**
 * @description       : 
 * @group             : 
 * @last modified on  : 07-11-2023
 * @last modified by  : rizki.asriningtyas@xendit.co
**/
public class Xendit_CreateChildRampRecords {
    
    /**********************************************************************************************************************
    * Query Parent Opportunities and its Xendit products
    * Query Parent Opportunity Ramp records
    * For each Xendit product - create Ramp records same as its parent
    * Delete existing ramp records for xendit products
    * Update Transaction date in parent ramp if it is changed
    *********************************************************************************************************************/
    
    public static void createRampRecords(set<id>parentids) {
        list<Opportunity_Ramp__c> rampList=new list<Opportunity_Ramp__c>();
        list<Opportunity_Ramp__c> updateRampList=new list<Opportunity_Ramp__c>();
        set<id>productIds=new set<id>();
        map<id,Opportunity> parentOppMap=new map<id,opportunity>();
        map<id,map<decimal,Opportunity_Ramp__c>> parentRampMap=new  map<id,map<decimal,Opportunity_Ramp__c>>();
        try{     
            for(Opportunity parentRec:[SELECT Id,Estimated_Monthly_Revenue__c,CurrencyIsoCode,Estimated_Monthly_Potential_TPV__c,
                                       Xst_Txn_Act_Date__c,Parent_Opportunity__c, Type FROM Opportunity where id =:parentids])
            {
                
                parentOppMap.put(parentRec.id,parentRec);
            }
            
            Map<String, Decimal> conversionRateMap = OpportunityHelper.getConversionRateMap();  

            list<Xendit_Opportunity_Product__c> xenditProducts=new list<Xendit_Opportunity_Product__c>();
            xenditProducts=[select id,TPV__c,Total_Revenue__c,Grand_Parent_Opportunity_ID__c,Opportunity__r.CurrencyIsoCode, CurrencyIsoCode from Xendit_Opportunity_Product__c where Grand_Parent_Opportunity_ID__c=:parentids];
            system.debug('$$$$'+xenditProducts);
            
            for(Opportunity_Ramp__c ramp:[select id,Opportunity__c,Transaction_Date__c,Month__c,Ramp_Percentage__c,Adjusted_Percentage__c 
                                          from Opportunity_Ramp__c where Opportunity__c=:parentids])
            {
                
                map<decimal,Opportunity_Ramp__c> tempMap=new map<decimal,Opportunity_Ramp__c>();
                if(parentRampMap.containsKey(ramp.Opportunity__c))
                    tempMap=parentRampMap.get(ramp.Opportunity__c);
                tempMap.put(ramp.month__c,ramp);
                parentRampMap.put(ramp.Opportunity__c,tempMap);
                
                opportunity parentrec=parentOppMap.get(ramp.Opportunity__c);
                if(ramp.month__c==1 && ramp.Transaction_Date__c!=parentRec.Xst_Txn_Act_Date__c){
                    ramp.Transaction_Date__c=parentRec.Xst_Txn_Act_Date__c;
                    updateRampList.add(ramp);
                }
            } 
            for(Xendit_Opportunity_Product__c child:xenditProducts){
                system.debug('$$$'+child.id);
                system.debug('$$$'+child.Grand_Parent_Opportunity_ID__c);
                map<decimal,Opportunity_Ramp__c> tempMap=parentRampMap.get(child.Grand_Parent_Opportunity_ID__c);
                opportunity parentrec=parentOppMap.get(child.Grand_Parent_Opportunity_ID__c);
                productIds.add(child.id);
                if(child.TPV__c==null)child.TPV__c=0;
                if(child.Total_Revenue__c==null)child.Total_Revenue__c=0;
                if(tempMap!=null && tempMap.keyset()!=null)
                {
                    system.debug('KEYSET SIZE : ' + tempMap.keyset().size());
                    for(integer i=1;i<=tempMap.keyset().size();i++){
                        Opportunity_Ramp__c rampRec=new Opportunity_Ramp__c();
                        rampRec.Month__c=i;
                        rampRec.recordtypeid=Schema.SObjectType.Opportunity_Ramp__c.getRecordTypeInfosByDeveloperName().get('Child_Ramp').getRecordTypeId();
                        rampRec.Transaction_Date__c=tempMap.get(i).Transaction_Date__c;
                        rampRec.Xendit_Opportunity_Product__c=child.id;
                        rampRec.CurrencyIsoCode=child.Opportunity__r.CurrencyIsoCode;
                        if (parentRec.Type == 'Upsell') {
                            // Set Adjusted Percentage and Ramp Percentage to 100% for Upsell Opportunities
                            rampRec.Adjusted_Percentage__c = 100;
                            rampRec.Ramp_Percentage__c = 100;
                        } else {
                            rampRec.Ramp_Percentage__c=tempMap.get(i).Ramp_Percentage__c;
                            rampRec.Adjusted_Percentage__c=tempMap.get(i).Adjusted_Percentage__c;
                        }
                        if(i!=1){
                            rampRec.Estimated_TPV__c= Utility.valueConversion(conversionRateMap,child.TPV__c, child.CurrencyIsoCode,rampRec.CurrencyIsoCode)*(ramprec.Adjusted_Percentage__c/100);
                            rampRec.Estimated_Revenue__c= Utility.valueConversion(conversionRateMap,child.Total_Revenue__c, child.CurrencyIsoCode,rampRec.CurrencyIsoCode)*(ramprec.Adjusted_Percentage__c/100);
                        }else{
                            decimal totalNumberOfDays=date.daysInMonth(parentRec.Xst_Txn_Act_Date__c.year(), parentRec.Xst_Txn_Act_Date__c.month());
                            decimal noOfDaysLeft=(totalNumberOfDays-parentRec.Xst_Txn_Act_Date__c.day())+1;
                            decimal value1=noOfDaysLeft;
                            decimal value2=totalNumberOfDays;
                            decimal value=value1 / value2;
                            rampRec.Estimated_TPV__c=(value*Utility.valueConversion(conversionRateMap,child.TPV__c, child.CurrencyIsoCode,rampRec.CurrencyIsoCode)*(ramprec.Adjusted_Percentage__c/100)).setScale(2);
                            rampRec.Estimated_Revenue__c=(value*Utility.valueConversion(conversionRateMap,child.Total_Revenue__c, child.CurrencyIsoCode,rampRec.CurrencyIsoCode)*(ramprec.Adjusted_Percentage__c/100)).setScale(2);
                        }
                        rampList.add(rampRec);
                        system.debug('$$$$Ramp'+rampRec);
                    }
                }
            } 
            
            list<Opportunity_Ramp__c> existingRamps=[select id from Opportunity_Ramp__c where Xendit_Opportunity_Product__c=:productIds];
            if(!existingRamps.isEmpty()) delete existingRamps;
            if(!updateRampList.isEmpty()) database.update(updateRampList,false);
            if(!rampList.isEmpty()) insert rampList;
        }
        catch(Exception ex){ 
            system.debug('$$$'+ex.getMessage()+'\n'+ex.getLineNumber()+'\n'+ex.getCause());
        }
    }
    
}