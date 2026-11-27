/**
 * @description       : 
 * @group             : 
 * @last modified on  : 07-11-2023
 * @last modified by  : rizki.asriningtyas@xendit.co
**/
public class Xendit_CreateParentRampRecords {
    
    /**********************************************************************************************************************
    * Query Parent Opportunities
    * Query Segment Metadata and add it in map 
    * For each Parent Opportunity - create Ramp records as per its Segment
    *********************************************************************************************************************/
    
    public static void createRampOnOppInsert(set<id>parentIds) {
        try{
            list<Opportunity_Ramp__c> rampList=new list<Opportunity_Ramp__c>();
            set<string> accountSegments=new set<string>();
            list<Opportunity> oppList=new list<Opportunity>();
            map<string,map<String,decimal>> segmentRampMap=new  map<string,map<String,decimal>>();
            oppList=[select Id,Estimated_Monthly_Revenue__c,CurrencyIsoCode,Estimated_Monthly_Potential_TPV__c,
                     Xst_Txn_Act_Date__c,Parent_Opportunity__c,Account.Segment__c, Type FROM Opportunity where id =:parentIds AND Xst_Txn_Act_Date__c!=null];
            
            for(Opportunity opp:oppList)
            {
                if(opp.Account.Segment__c!=null)
                    accountSegments.add(opp.Account.Segment__c);
            }
            accountSegments.add('Individual');
            
            for(Segment_Based_Ramp__mdt rec: [SELECT MasterLabel,nth_Month__c,ramp_factor__c, Min_Diff_Days__c, Max_Diff_Days__c FROM Segment_Based_Ramp__mdt
                                              WHERE MasterLabel =:accountSegments AND Min_Diff_Days__c != NULL AND Max_Diff_Days__c != NULL])
            {
                map<String,decimal> tempMap=new map<String,decimal>();
                if(segmentRampMap.containsKey(rec.MasterLabel))
                    tempMap=segmentRampMap.get(rec.MasterLabel);
                String key = Integer.valueOf(rec.nth_Month__c) + '_' + Integer.valueOf(rec.Min_Diff_Days__c) + '_' + Integer.valueOf(rec.Max_Diff_Days__c);
                tempMap.put(key,rec.ramp_factor__c); //e.g. (1_1_7) => 35%
                segmentRampMap.put(rec.MasterLabel,tempMap);
            }
            
            for(Opportunity record:oppList)
            {
                map<String,decimal> segmentTempMap=new map<String,decimal>();
                map<Integer, Decimal> filteredSegmentTempMap = new Map<Integer, Decimal>();
                string segment=record.Account.Segment__c!=null?record.Account.Segment__c:'Individual';
                if(segmentRampMap.containsKey(segment))
                {
                    segmentTempMap=segmentRampMap.get(segment); //get map between key and percentage
                    for(String key : segmentTempMap.keySet()){
                        List<String> monthMinMaxValues = key.split('_');
                        Integer monthVal = monthMinMaxValues[0] != null && monthMinMaxValues[0].isNumeric() ? Integer.valueOf(monthMinMaxValues[0]) : 1;
                        Integer minDays = monthMinMaxValues[1] != null && monthMinMaxValues[1].isNumeric() ? Integer.valueOf(monthMinMaxValues[1]) : 31;
                        Integer maxDays = monthMinMaxValues[2] != null && monthMinMaxValues[2].isNumeric() ? Integer.valueOf(monthMinMaxValues[2]) : 31;
                        Integer diffDaysInMonth = record.Xst_Txn_Act_Date__c != null ? (Date.daysInMonth(record.Xst_Txn_Act_Date__c.year(), record.Xst_Txn_Act_Date__c.month()) - record.Xst_Txn_Act_Date__c.day()) : 31;
                        if(minDays <= diffDaysInMonth && maxDays >= diffDaysInMonth){
                            filteredSegmentTempMap.put(monthVal, segmentTempMap.get(key));
                        }
                    }
                    integer loopsize=filteredSegmentTempMap.keySet().size(); //number of months from metadata
                    system.debug('loopsize : ' + loopsize);
                    decimal rampPerc=0;
                    boolean setNextYear=false;
                    for(integer i=1;i<=loopsize;i++){
                        if(filteredSegmentTempMap.containsKey(i)){
                            rampPerc=filteredSegmentTempMap.get(i);
                        }
                            
                        Opportunity_Ramp__c rampRec=new Opportunity_Ramp__c();
                        date setMonth=record.Xst_Txn_Act_Date__c.addMonths(i-1);
                        date setYear=record.Xst_Txn_Act_Date__c;
                        if(setNextYear || record.Xst_Txn_Act_Date__c.month()==12) setYear=record.Xst_Txn_Act_Date__c.addYears(1);
                        if(setMonth.month()==12)setNextYear=true; 
                        if(i!=1){   
                            ramprec.Transaction_Date__c=Date.newInstance(setYear.year(), setMonth.month(), 01);
                        }
                        else{
                            ramprec.Transaction_Date__c=record.Xst_Txn_Act_Date__c;
                        }
                        ramprec.month__c=i;
                        rampRec.recordtypeid=Schema.SObjectType.Opportunity_Ramp__c.getRecordTypeInfosByDeveloperName().get('Parent_Ramp').getRecordTypeId();
                        ramprec.Opportunity__c=record.id;

                        // Check if the Opportunity type is "Upsell" and set Ramp_Percentage__c and Adjusted_Percentage__c to 100%.
                        if (record.Type == 'Upsell') {
                            rampRec.Ramp_Percentage__c = 100;
                            rampRec.Adjusted_Percentage__c = 100;
                        }else{
                            ramprec.Ramp_Percentage__c=rampPerc;
                            ramprec.Adjusted_Percentage__c=rampPerc;
                        }
                        rampList.add(ramprec); 
                    }

                    if(loopsize != null && loopsize > 0 && rampList.size() > 0){
                        Opportunity_Ramp__c lastOppRamp = rampList[loopsize - 1];
                        List<Opportunity_Ramp__c> addOppRampList = addSameYearRamp(lastOppRamp);
                        if(!addOppRampList.isEmpty()){
                            rampList.addAll(addOppRampList);
                        }
                    }
                }
            }
            
            if(!rampList.isEmpty())
                insert rampList;
            
        }catch(exception e){
            system.debug('$$$ error create ramp list : '+e.getmessage());
        }
    }

    public static List<Opportunity_Ramp__c> addSameYearRamp(Opportunity_Ramp__c lastOppRamp){
        List<Opportunity_Ramp__c> returnValList = new List<Opportunity_Ramp__c>();
        if(lastOppRamp.Transaction_Date__c != null && lastOppRamp.Transaction_Date__c.month() < 12 && lastOppRamp.Adjusted_Percentage__c == 100){
            //get month difference in the same year
            Integer diffMonth = 12 - lastOppRamp.Transaction_Date__c.month();
            for(Integer i = 1 ; i <= diffMonth ; i++){
                Opportunity_Ramp__c rampRec=new Opportunity_Ramp__c();
                ramprec.Opportunity__c=lastOppRamp.Opportunity__c;
                ramprec.Ramp_Percentage__c=100;
                ramprec.Adjusted_Percentage__c=100;
                ramprec.Transaction_Date__c=Date.newInstance(lastOppRamp.Transaction_Date__c.year(), lastOppRamp.Transaction_Date__c.month() + i, 01);
                ramprec.Month__c=lastOppRamp.Month__c + i;
                returnValList.add(ramprec);
            }
        }
        return returnValList;
    }
    
}