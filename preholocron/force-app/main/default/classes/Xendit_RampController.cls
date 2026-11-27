/**
 * @description       : 
 * @group             : 
 * @last modified on  : 07-11-2023
 * @last modified by  : rizki.asriningtyas@xendit.co
**/
public class Xendit_RampController {
    
    @AuraEnabled
    public static displayData setupData(string recordId) {
        try{
            displayData data =new displayData();
            decimal rampPerc=0;
            list<Opportunity_Ramp__c> rampList=new list<Opportunity_Ramp__c>();
            map<Integer,Opportunity_Ramp__c> rampMap=new map<Integer,Opportunity_Ramp__c>();
            map<Integer,decimal> segmentRampMap=new map<Integer,decimal>();
            List<Segment_Based_Ramp__mdt> segmentRampAllIntervalList=new List<Segment_Based_Ramp__mdt>();
            integer loopsize=5;
            
            Opportunity record = [SELECT Id,Estimated_Monthly_Revenue__c,CurrencyIsoCode,Estimated_Monthly_Potential_TPV__c, Is_Override_Default_Ramp__c,
                                  Xst_Txn_Act_Date__c,Parent_Opportunity__c,Account.Segment__c, Type FROM Opportunity where id =:recordId];
            
            string segment=record.Account.Segment__c!=null?record.Account.Segment__c:'Individual';
            Integer diffDaysInMonth = record.Xst_Txn_Act_Date__c != null ? (Date.daysInMonth(record.Xst_Txn_Act_Date__c.year(), record.Xst_Txn_Act_Date__c.month()) - record.Xst_Txn_Act_Date__c.day()) : 31;
            for(Segment_Based_Ramp__mdt rec: [SELECT MasterLabel,nth_Month__c,ramp_factor__c, Min_Diff_Days__c, Max_Diff_Days__c FROM Segment_Based_Ramp__mdt
                                              WHERE MasterLabel =:segment AND Min_Diff_Days__c != NULL AND Max_Diff_Days__c != NULL])
            {
                if(rec.Min_Diff_Days__c <= diffDaysInMonth && rec.Max_Diff_Days__c >= diffDaysInMonth){
                    segmentRampMap.put(Integer.valueOf(rec.nth_Month__c),rec.ramp_factor__c);
                }   
                segmentRampAllIntervalList.add(rec);
            }
            loopsize=segmentRampMap.keySet().size();
            
            for(Opportunity_Ramp__c ramp:[select id,Opportunity__c,Transaction_Date__c,Month__c,Ramp_Percentage__c,Adjusted_Percentage__c 
                                          from Opportunity_Ramp__c where Opportunity__c=:recordId])
            {
                // Check if the Opportunity is of type Upsell and update the percentages
                if (record.Type == 'Upsell') {
                    ramp.Ramp_Percentage__c = 100;
                    ramp.Adjusted_Percentage__c = 100;
                }
                rampMap.put(Integer.valueOf(ramp.month__c),ramp);
                data.allOppRamps.add(ramp);
            }
            
            if(rampMap!=null && rampMap.keyset().size()>0) 
                loopsize=rampMap.keyset().size();
            
            system.debug('$$$$'+rampMap);
            data.opp=record;
            boolean setNextYear=false;
            
            for(integer i=1;i<=loopsize;i++){
                Opportunity_Ramp__c rampRec=new Opportunity_Ramp__c();
                if(rampMap.containsKey(i)){
                    rampRec=rampMap.get(i);
                    rampList.add(ramprec); 
                }
            }
            
            data.oppRampList=rampList;
            data.rampListSize=rampList.size();
            data.defaultAllIntervalList = segmentRampAllIntervalList;
            system.debug('$$$'+data);
            return data;
        }catch(exception e){
            system.debug('$$$'+e.getmessage());
        }
        return null;
    }
    
    public class displayData
    {
        @AuraEnabled
        public opportunity opp {get;set;}
        @AuraEnabled
        public string resultMessage {get;set;}
        @AuraEnabled
        public boolean isChangedDate {get;set;}
        @AuraEnabled
        public integer rampListSize {get;set;}
        @AuraEnabled
        public list<Opportunity_Ramp__c> oppRampList {get;set;}
        @AuraEnabled
        public list<Opportunity_Ramp__c> deleteRampList {get;set;}
        @AuraEnabled
        public List<Segment_Based_Ramp__mdt> defaultAllIntervalList {get;set;}
        @AuraEnabled
        public List<Opportunity_Ramp__c> allOppRamps {get;set;}
        public displayData() {
            oppRampList=new list<Opportunity_Ramp__c>();
            deleteRampList=new list<Opportunity_Ramp__c>();
            isChangedDate=false;
            resultMessage='';
            defaultAllIntervalList = new List<Segment_Based_Ramp__mdt>();
            allOppRamps = new List<Opportunity_Ramp__c>();
        }
    }
    @AuraEnabled
    public static displayData updateData(displayData data) {
        try{
            list<Opportunity_Ramp__c>upsertList=new list<Opportunity_Ramp__c>();
            list<Opportunity_Ramp__c>autoRampList=new list<Opportunity_Ramp__c>();
            list<Opportunity_Ramp__c>deleteList=new list<Opportunity_Ramp__c>();
            list<Opportunity_Ramp__c>oppRampList=data.oppRampList;
            map<id,Opportunity> childMap=new map<id,opportunity>(); 
            map<integer,Opportunity_Ramp__c> parentRampMap=new map<integer,Opportunity_Ramp__c>(); 
            set<decimal> monthsIncluded=new set<decimal>();
            boolean error=false;
            boolean refresh=false;

            //remove exst opp ramp
            if(data.allOppRamps != null && !data.allOppRamps.isEmpty()){
                List<Id> removeRampIds = new List<Id>();
                if(data.deleteRampList != null && !data.deleteRampList.isEmpty()){
                    for(Opportunity_Ramp__c ormp : data.deleteRampList){
                        removeRampIds.add(ormp.Id);
                    }
                }

                if(data.oppRampList != null && !data.oppRampList.isEmpty()){
                    for(Opportunity_Ramp__c ormp : data.oppRampList){
                        if(ormp.Id != null){
                            removeRampIds.add(ormp.Id);
                        }
                    }
                }

                for (Integer i = (data.allOppRamps.size()-1) ; i>= 0 ; i--){
                    String p = data.allOppRamps[i].Id;
                    if(removeRampIds.contains(p)){
                        data.allOppRamps.remove(i);
                    }
                } 

                if(data.allOppRamps != null && !data.allOppRamps.isEmpty()){
                    data.deleteRampList.addAll(data.allOppRamps);
                }
            }
            

            if(!data.deleteRampList.isEmpty()){
                delete data.deleteRampList;
                data.deleteRampList=new list<Opportunity_Ramp__c>();
                refresh=true;
            } 
            
            if(!oppRampList.isEmpty()){
                for(Opportunity_Ramp__c rec:oppRampList){
                    if(rec.Adjusted_Percentage__c!=null){
                        parentRampMap.put(integer.valueof(rec.Month__c),rec);
                        upsertList.add(rec);
                    }
                }

                //automation to create opp ramp with percentage of 100% for the next month in the same year
                Set<Integer> monthSet = parentRampMap.keySet();
                if(monthSet != null && !monthSet.isEmpty()){
                    List<Integer> monthList = new List<Integer>(monthSet);
                    monthList.sort();
                    Opportunity_Ramp__c lastOppRamp = parentRampMap.get(monthList[monthList.size() - 1]);
                    List<Opportunity_Ramp__c> addOppRampList = Xendit_CreateParentRampRecords.addSameYearRamp(lastOppRamp);
                    if(!addOppRampList.isEmpty()){
                        upsertList.addAll(addOppRampList);
                    }
                }
                system.debug('$$$'+upsertList);
                
                if(!upsertList.isEmpty()){
                    upsert upsertList;
                    data.oppRampList=upsertList;
                    data.rampListSize=upsertList.size();
                    //update Transaction date
                    if(data.isChangedDate){
                        data.opp.Allow_Transaction_Date_Edit__c=true;
                        TriggerBypassUtility.opportunityTriggerBypass = true;
                        update data.opp;
                        TriggerBypassUtility.opportunityTriggerBypass = false;
                    }
                    //setup Refresh Ramp
                    data.opp.Refresh_Ramp__c=true;
                    data.opp.Allow_Transaction_Date_Edit__c=false;
                    update data.opp;
                    data.resultMessage='Ramp Records got successfully updated';      
                }
            }else if(refresh){
                data.opp.Refresh_Ramp__c=true;
                update data.opp;
            }
            return data; 
        }catch(DmlException e){
            Set<String> errmsgList = new Set<String>();
            for (Integer i = 0; i < e.getNumDml(); i++) {
                // Process exception here
                errmsgList.add(e.getDmlMessage(i)); 
            }

            String errMsg = String.join(new List<String>(errmsgList), '\n');
            data.resultMessage='Following Error Occured:' + '\n' + errMsg + '\n' + 'Please update and try again.';
            return data;
        }catch(exception e){
            list<string> error=e.getMessage().split(':');
            data.resultMessage='Following Error Occured:';
            for(string err:error){
                data.resultMessage=data.resultMessage+'\n'+ err;    
            }
            data.resultMessage=data.resultMessage+'\n'+'Please update and try again.';     
            system.debug('$$$$'+data.resultMessage);
            return data;
        }
    }
    
    
    @AuraEnabled
    public static displayData deleteRampRecord(integer index, displayData data) {
        try{
            Opportunity_Ramp__c delRamp=data.oppRampList[index];
            if(delRamp.id!=null)
                data.deleteRampList.add(delRamp);
            data.oppRampList.remove(index);
            data=refreshOppList(data);
            data.rampListSize= data.oppRampList.size();
            data.resultMessage='success'; 
        }catch(exception e){
            system.debug('$$$$'+e.getMessage());
            data.resultMessage='error';
        }
        return data;
    }
    @AuraEnabled
    public static displayData addRampRecord(displayData data,string recordId) {
        try{
            Opportunity_Ramp__c rampRec=new Opportunity_Ramp__c();
            ramprec.Opportunity__c=recordId;
            ramprec.Ramp_Percentage__c=100;
            data.oppRampList.add(ramprec);
            data.resultMessage='success';
            data=refreshOppList(data);
            data.rampListSize= data.oppRampList.size();
        }catch(exception e){
            system.debug('$$$$'+e.getMessage());
            data.resultMessage='error';
        }
        return data;
    }
    
    
    @AuraEnabled
    public static displayData refreshRampRecord(displayData data) {
        try{
            data=refreshDefaultRampOppList(data);
            data.rampListSize= data.oppRampList.size();
            data.isChangedDate=true;
            data.resultMessage='success'; 
        }catch(exception e){
            system.debug('$$$$'+e.getMessage());
            data.resultMessage='error';
        }
        return data;
    }

    public static displayData refreshDefaultRampOppList(displayData data){
        
        //get custom metadata
        Integer diffDaysInMonth = data.opp.Xst_Txn_Act_Date__c != null ? (Date.daysInMonth(data.opp.Xst_Txn_Act_Date__c.year(), data.opp.Xst_Txn_Act_Date__c.month()) - data.opp.Xst_Txn_Act_Date__c.day()) : 31;
        List<Segment_Based_Ramp__mdt> defaultAllIntervalRamp = data.defaultAllIntervalList;
        if(defaultAllIntervalRamp != null && !defaultAllIntervalRamp.isEmpty()){
            map<Integer, Decimal> filteredSegmentTempMap = new Map<Integer, Decimal>();
            for(Segment_Based_Ramp__mdt defaultRamp: defaultAllIntervalRamp){
                Integer monthVal = defaultRamp.nth_Month__c != null ? Integer.valueOf(defaultRamp.nth_Month__c) : 1;
                Integer minDays = defaultRamp.Min_Diff_Days__c != null ? Integer.valueOf(defaultRamp.Min_Diff_Days__c) : 31;
                Integer maxDays = defaultRamp.Max_Diff_Days__c != null ? Integer.valueOf(defaultRamp.Max_Diff_Days__c) : 31;
                if(minDays <= diffDaysInMonth && maxDays >= diffDaysInMonth){
                    filteredSegmentTempMap.put(monthVal, defaultRamp.ramp_factor__c);
                }
            }

            if(!filteredSegmentTempMap.isEmpty()){
                List<Opportunity_Ramp__c> newOppRampList = new List<Opportunity_Ramp__c>();
                for(Integer i = 0;  i < filteredSegmentTempMap.size(); i++){
                    Opportunity_Ramp__c tempRamp = new Opportunity_Ramp__c();
                    tempRamp.Opportunity__c = data.opp.Id;
                    // Check if the Opportunity is of type Upsell and update the percentages
                    if (data.opp.Type == 'Upsell') {
                        tempRamp.Ramp_Percentage__c = 100;
                        tempRamp.Adjusted_Percentage__c = 100;
                    }else{
                        tempRamp.Ramp_Percentage__c = filteredSegmentTempMap.get(i+1);
                        tempRamp.Adjusted_Percentage__c= filteredSegmentTempMap.get(i+1);
                    }
                    tempRamp.Month__c= i+1;
                    newOppRampList.add(tempRamp);
                }

                if(!newOppRampList.isEmpty()){
                    data.oppRampList = newOppRampList;
                    refreshOppList(data);
                }
            }
        }
        return data;
    }
    
    public static displayData refreshOppList(displayData data){
        boolean setNextYear=false;
        for(integer i=0;i<data.oppRampList.size();i++){
            data.oppRampList[i].Month__c=i+1;
            if(i!=0){
                date setMonth=data.opp.Xst_Txn_Act_Date__c.addMonths(i);
                date setYear=data.opp.Xst_Txn_Act_Date__c;
                if(setNextYear || data.opp.Xst_Txn_Act_Date__c.month()==12)setYear=data.opp.Xst_Txn_Act_Date__c.addYears(1);
                if(setMonth.month()==12)setNextYear=true; 
                if(setNextYear && setMonth.year() > data.opp.Xst_Txn_Act_Date__c.year()) setYear = setMonth;
                data.oppRampList[i].Transaction_Date__c=Date.newInstance(setYear.year(), setMonth.month(), 01);
            }
            else{
                data.oppRampList[i].Transaction_Date__c=data.opp.Xst_Txn_Act_Date__c;
            }
        }
        return data;
    }
}