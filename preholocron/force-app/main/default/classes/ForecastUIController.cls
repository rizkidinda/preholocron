public without sharing class ForecastUIController {
    @AuraEnabled
    public static String setupData(Id AccountId){
        try{
            String returnStr = null;
            Double estAnnualTPV = 0;
            String accType = '';
            String strHistory = '';
            Map<Integer,ForecastDetailsWrapper> forecastMonthMap = new Map<Integer,ForecastDetailsWrapper>();
            totalWrapper lastYearForecastTotal = new totalWrapper();

            List<ForecastDetailsWrapper> allForecastList = new List<ForecastDetailsWrapper>();
            Forecasting_Engine__c lastYearForecast = null;
            Integer lastYear = Date.today().year() - 1;

            if(!String.isBlank(AccountId)){
                List<Account> getCurrAccount = [SELECT Type FROM Account WHERE Id = :AccountId];
                if(getCurrAccount!= null && !getCurrAccount.isEmpty()) accType = getCurrAccount[0].Type;
                strHistory = getHistoryRecords(AccountId);
            }
            
            if(accType == 'XP MASTER' || accType == 'REGULAR'){
                //to get main account data
                List<Forecasting_Engine__c> forecastAccList = [SELECT Id, Month__c, Final_Forecast_TPV_USD_Formula__c, Sales_Input_TPV_USD__c, Display_TPV_USD_Formula__c, Sales_Team_Approved_TPV__c, Take_Rate__c, Avg_Basket_Size__c, No_of_Transactions__c, Final_Forecast_Revenue_USD__c, Actual_TPV_USD__c, Commited_Value__c, Is_Sales_Input_TPV_Populated__c 
                                                            FROM Forecasting_Engine__c 
                                                            WHERE Account__c = :AccountId AND Month__c = THIS_YEAR ORDER BY Month__c ASC];

                for(Forecasting_Engine__c fc : forecastAccList){
                    //populate ForecastDetailsWrapper
                    ForecastDetailsWrapper fcw = new ForecastDetailsWrapper();
                    fcw = addForecastDetails(fc);

                    forecastMonthMap.put(fcw.month, fcw);
                }

                /*NEW START*/
                //get total from main + sub account data (if Any)
                for(AggregateResult arr : [SELECT Month__c, SUM(Final_Forecast_TPV_USD_Formula__c) totalFinalorecastTPV, SUM(Sales_Team_Approved_TPV__c) totalSalesTeamApprovedTPV, SUM(Sales_Input_TPV_USD__c) totalSalesInputTPV, SUM(Display_TPV_USD_Formula__c) totalDisplayTPV, SUM(No_of_Transactions__c) totalTransactions, SUM(Final_Forecast_Revenue_USD__c) totalFinalForecastRev, SUM(Actual_TPV_USD__c) totalActualTPV, SUM(Is_Sales_Input_TPV_Populated__c) totalPopulatedSalesTPV
                                            FROM Forecasting_Engine__c 
                                            WHERE (Account__c = :AccountId OR Account__r.ParentId = :AccountId OR Account__r.Parent.ParentId = :AccountId OR Account__r.Parent.Parent.ParentId =: AccountId OR Account__r.Parent.Parent.Parent.ParentId = :AccountId OR Account__r.Parent.Parent.Parent.Parent.ParentId = :AccountId) AND (Month__c = THIS_YEAR OR (CALENDAR_MONTH(Month__c) = 12 AND CALENDAR_YEAR(Month__c) = :lastYear)) GROUP BY Month__c ORDER BY Month__c ASC]){
                    
                    //sum display TPV for estimated annual TPV related to the Account Id + child
                    estAnnualTPV = (Decimal)arr.get('totalDisplayTPV') != null ? estAnnualTPV + (Decimal)arr.get('totalDisplayTPV') : estAnnualTPV;
                    Date strMonth = (Date)arr.get('Month__c');
                    system.debug('strMonth :' + strMonth);
                    Integer mo = strMonth.month();
                    totalWrapper tempTotalObj = new totalWrapper();
                    tempTotalObj.totalForecastTPV = (Decimal)arr.get('totalFinalorecastTPV') != null ? (Decimal)arr.get('totalFinalorecastTPV') : null;
                    tempTotalObj.totalSalesTeamApprovedTPV = (Decimal)arr.get('totalSalesTeamApprovedTPV') != null ? (Decimal)arr.get('totalSalesTeamApprovedTPV') : null;
                    tempTotalObj.totalPopulatedSalesTPV = (Decimal)arr.get('totalPopulatedSalesTPV') != null ? (Decimal)arr.get('totalPopulatedSalesTPV') : null;
                    tempTotalObj.totalActualTPV = (Decimal)arr.get('totalActualTPV') != null ? (Decimal)arr.get('totalActualTPV') : null;
                    tempTotalObj.totalDisplayTPV = (Decimal)arr.get('totalDisplayTPV') != null ? (Decimal)arr.get('totalDisplayTPV') : null;
                    tempTotalObj.totalTransactions = (Decimal)arr.get('totalTransactions') != null ? (Decimal)arr.get('totalTransactions') : null;

                    if(strMonth != null && strMonth.year() == Date.today().year()){
                        ForecastDetailsWrapper wrapper = new ForecastDetailsWrapper();
                        if(forecastMonthMap.containsKey(mo)){
                            wrapper = forecastMonthMap.get(mo);
                        }
                        wrapper.allTotalWrapper = tempTotalObj;
                        forecastMonthMap.put(mo, wrapper);
                    }else if(strMonth != null && mo == 12 && strMonth.year() == lastYear){
                        lastYearForecastTotal = tempTotalObj;
                    }
                    
                }
                /*NEW END*/

                for(Integer i = 1 ; i <= 12 ; i++){
                    ForecastDetailsWrapper stdForecastDetail = new ForecastDetailsWrapper();
                    if(forecastMonthMap.containsKey(i)){
                        ForecastDetailsWrapper getForecastDetailWrapper = forecastMonthMap.get(i);
                        totalWrapper currentTotalWrapper = getForecastDetailWrapper.allTotalWrapper;
                        totalWrapper previousMonthForecastTotal = null;
                        if(i == 1){
                            previousMonthForecastTotal = lastYearForecastTotal;
                        }else{
                            previousMonthForecastTotal = forecastMonthMap.containsKey(i-1) ? forecastMonthMap.get(i-1).allTotalWrapper : null;
                        }
                        getForecastDetailWrapper.MoMTPVGrowth = previousMonthForecastTotal != null && previousMonthForecastTotal.totalSalesTeamApprovedTPV != null && previousMonthForecastTotal.totalSalesTeamApprovedTPV > 0 && currentTotalWrapper.totalSalesTeamApprovedTPV != null && currentTotalWrapper.totalSalesTeamApprovedTPV > 0 ? (currentTotalWrapper.totalSalesTeamApprovedTPV - previousMonthForecastTotal.totalSalesTeamApprovedTPV) / previousMonthForecastTotal.totalSalesTeamApprovedTPV : null;
                        getForecastDetailWrapper.MoMTxnGrowth = previousMonthForecastTotal != null && previousMonthForecastTotal.totalTransactions != null && previousMonthForecastTotal.totalTransactions > 0 && currentTotalWrapper.totalTransactions != null && currentTotalWrapper.totalTransactions > 0 ? (currentTotalWrapper.totalTransactions - previousMonthForecastTotal.totalTransactions) / previousMonthForecastTotal.totalTransactions : null;
                        allForecastList.add(getForecastDetailWrapper);
                    }else{
                        allForecastList.add(stdForecastDetail);
                    }
                }
            }

            returnWrapper r = new returnWrapper();
            r.estAnnualTPV = estAnnualTPV;
            r.accType = accType;
            r.strHistory = strHistory;
            r.forecastDetails = allForecastList;

            return JSON.serialize(r);
        }catch(Exception e){
            system.debug('$$$'+e.getmessage());
            return null;
        }
        
    }

    @AuraEnabled
    public static String setupSubAccountData(Id AccountId){
        try{
            String returnStr = null;
            Map<String,ForecastDetailsWrapper> forecastMonthMap = new Map<String,ForecastDetailsWrapper>();
            List<SubAccDetailsWrapper> subAccWrapperList = new List<SubAccDetailsWrapper>();
            Integer lastYear = Date.today().year() - 1;

            Map<Id,Account> subAccMap = new Map<Id, Account>([SELECT Id, Name, Brand__c FROM Account WHERE ParentId = :AccountId]);
            if(subAccMap.size() > 0){
                List<Forecasting_Engine__c> forecastAccList = [SELECT Id, Account__c, Month__c, Final_Forecast_TPV_USD_Formula__c, Sales_Input_TPV_USD__c, Display_TPV_USD_Formula__c, Sales_Team_Approved_TPV__c, Take_Rate__c, Avg_Basket_Size__c, No_of_Transactions__c, Final_Forecast_Revenue_USD__c, Actual_TPV_USD__c, Commited_Value__c, Is_Sales_Input_TPV_Populated__c 
                                                        FROM Forecasting_Engine__c 
                                                        WHERE Account__c IN :subAccMap.keySet() AND Month__c = THIS_YEAR ORDER BY Month__c ASC];
                
                for(Forecasting_Engine__c fc : forecastAccList){
                    //populate ForecastDetailsWrapper
                    ForecastDetailsWrapper fcw = new ForecastDetailsWrapper();
                    fcw = addForecastDetails(fc);

                    String strKey = fc.Account__c + ':::' + fcw.month;
                    forecastMonthMap.put(strKey, fcw);
                }

                for(Id accId : subAccMap.keySet()){
                    List<ForecastDetailsWrapper> subAccForecastList = new List<ForecastDetailsWrapper>();
                    Boolean isForecastExist = false;
                    Double totalTPVDisplay = 0;
                    for(Integer i = 1 ; i <= 12 ; i++){
                        ForecastDetailsWrapper stdForecastDetail = new ForecastDetailsWrapper();
                        String strKey = accId + ':::' + i;
                        if(forecastMonthMap.containsKey(strKey)){
                            ForecastDetailsWrapper getForecastDetailWrapper = forecastMonthMap.get(strKey);
                            isForecastExist = true;
                            subAccForecastList.add(getForecastDetailWrapper);

                            if(getForecastDetailWrapper.tempTPVDisplay != null && getForecastDetailWrapper.tempTPVDisplay > 0){
                                totalTPVDisplay += getForecastDetailWrapper.tempTPVDisplay;
                            } 
                        }else{
                            Forecasting_Engine__c tempForecastObj = new Forecasting_Engine__c(Month__c = Date.newInstance(Date.today().year(), i, 1), Account__c = accId, Forecast_Organic_TPV_USD__c = 0, Commited_Value__c = false);
                            stdForecastDetail.month = i;
                            stdForecastDetail.forecastDetail = tempForecastObj;
                            stdForecastDetail.tempTPVDisplay = 0;
                            stdForecastDetail.helpText = 'Actual TPV : \n' + 'Default System Forecast :\n' + 'Sales Team Input : ';
                            subAccForecastList.add(stdForecastDetail);
                        }
                    }

                    //if(isForecastExist){
                        SubAccDetailsWrapper tempSubAccWrap = new SubAccDetailsWrapper();
                        tempSubAccWrap.subAccAnnualTPVDisplay = totalTPVDisplay;
                        tempSubAccWrap.subAccObj = subAccMap.get(accId);
                        tempSubAccWrap.subAccForecastDetails = subAccForecastList;
                        subAccWrapperList.add(tempSubAccWrap);
                    //}
                }
            }
            if(!subAccWrapperList.isEmpty()){
                subAccWrapperList.sort();
                return JSON.serialize(subAccWrapperList);
            }else{
                return null;
            }
        }catch(Exception e){
            system.debug('$$$'+e.getmessage());
            return null;
        }
        
    }

    @AuraEnabled
    public static String saveForecastData(String forecastList, String subAccForecastList){
        try{
            String val = 'pass';
            Map<Id, Forecasting_Engine__c> updateForecastMap = new Map<Id, Forecasting_Engine__c>();
            List<Forecasting_Engine__c> insertForecastList = new List<Forecasting_Engine__c>();

            //check sub acc list
            List<ForecastDetailsWrapper> subAccFcObjList = new List<ForecastDetailsWrapper>();
            if(String.isNotBlank(subAccForecastList)){
                subAccFcObjList = (List<ForecastDetailsWrapper>) JSON.deserialize(subAccForecastList, List<ForecastDetailsWrapper>.class);
            }

            if(String.isNotBlank(forecastList)){
                List<ForecastDetailsWrapper> parsedWrap = (List<ForecastDetailsWrapper>) JSON.deserialize(forecastList, List<ForecastDetailsWrapper>.class);
                if(!subAccFcObjList.isEmpty()){
                    parsedWrap.addAll(subAccFcObjList);
                }

                for(ForecastDetailsWrapper wrap : parsedWrap){
                 if(wrap.forecastDetail != null && wrap.tempSalesInput){
                    if(wrap.forecastDetail.Id != null){
                        updateForecastMap.put(wrap.forecastDetail.Id, new Forecasting_Engine__c(Id = wrap.forecastDetail.Id, Sales_Input_TPV_USD__c = (!String.isBlank(String.valueOf(wrap.tempTPVDisplay)) && wrap.tempTPVDisplay != null) ? wrap.tempTPVDisplay : null, Latest_Sales_Team_Input_By__c = UserInfo.getUserId(), Latest_Sales_Team_Input_Date__c = Date.today()));
                    }else if(wrap.month != null && wrap.forecastDetail.Account__c != null){
                        Forecasting_Engine__c fctemp = new Forecasting_Engine__c(Month__c = Date.newInstance(Date.today().year(),wrap.month, 1), Account__c = wrap.forecastDetail.Account__c, Sales_Input_TPV_USD__c = (!String.isBlank(String.valueOf(wrap.tempTPVDisplay)) && wrap.tempTPVDisplay != null) ? wrap.tempTPVDisplay : null, Latest_Sales_Team_Input_By__c = UserInfo.getUserId(), Latest_Sales_Team_Input_Date__c = Date.today());
                        insertForecastList.add(fctemp);
                    }
                 }  
                }

                if(!updateForecastMap.isEmpty()){
                    update updateForecastMap.values();
                }

                if(!insertForecastList.isEmpty()){
                    insert insertForecastList;
                }
            }else{
                val = 'empty';
            }
            return val;
        }catch(Exception e){
            system.debug('$$$'+e.getmessage());
            ExceptionUtility.createExceptionLog('ForecastUIController','Forecasting_Engine__c', 'saveForecastData', 'Save ForecastUIController',  e);
            return null;
        }
    }

    @AuraEnabled
    public static String commitForecastData(String forecastList, String subAccForecastList, Integer currMonthInt){
        try{
            String val = 'pass';
            Map<Id, Forecasting_Engine__c> updateForecastMap = new Map<Id, Forecasting_Engine__c>();
            List<Forecasting_Engine__c> insertForecastList = new List<Forecasting_Engine__c>();

            //check sub acc list
            List<ForecastDetailsWrapper> subAccFcObjList = new List<ForecastDetailsWrapper>();
            if(String.isNotBlank(subAccForecastList)){
                subAccFcObjList = (List<ForecastDetailsWrapper>) JSON.deserialize(subAccForecastList, List<ForecastDetailsWrapper>.class);
            }

            if(String.isNotBlank(forecastList)){
                List<ForecastDetailsWrapper> parsedWrap = (List<ForecastDetailsWrapper>) JSON.deserialize(forecastList, List<ForecastDetailsWrapper>.class);
                if(!subAccFcObjList.isEmpty()){
                    parsedWrap.addAll(subAccFcObjList);
                }

                for(ForecastDetailsWrapper wrap : parsedWrap){
                    Integer forecastMonth = wrap.month;
                    //Integer currMonth = date.today().month();
                    if(wrap.forecastDetail != null && forecastMonth == currMonthInt){ //only commit current month's forecast
                        if(wrap.forecastDetail.Id != null){
                            updateForecastMap.put(wrap.forecastDetail.Id, new Forecasting_Engine__c(Id = wrap.forecastDetail.Id, Commited_Value__c = true));
                        }else if(!String.isBlank(wrap.forecastDetail.Account__c)){
                            Forecasting_Engine__c fctemp = new Forecasting_Engine__c(Month__c = Date.newInstance(Date.today().year(),wrap.month, 1), Account__c = wrap.forecastDetail.Account__c, Sales_Input_TPV_USD__c = (!String.isBlank(String.valueOf(wrap.tempTPVDisplay)) && wrap.tempTPVDisplay != null) ? wrap.tempTPVDisplay : null, Commited_Value__c = true, 
                                                            Latest_Sales_Team_Input_By__c = (!String.isBlank(String.valueOf(wrap.tempTPVDisplay)) && wrap.tempTPVDisplay != null && wrap.tempTPVDisplay > 0) ? UserInfo.getUserId() : null, 
                                                            Latest_Sales_Team_Input_Date__c = (!String.isBlank(String.valueOf(wrap.tempTPVDisplay)) && wrap.tempTPVDisplay != null && wrap.tempTPVDisplay > 0) ? Date.today() : null);
                            insertForecastList.add(fctemp);
                        }
                        
                    }   
                }

                if(!updateForecastMap.isEmpty()){
                    update updateForecastMap.values();
                }

                if(!insertForecastList.isEmpty()){
                    insert insertForecastList;
                }
            }else{
                val = 'empty';
            }
            return val;
        }catch(Exception e){
            system.debug('$$$'+e.getmessage());
            ExceptionUtility.createExceptionLog('ForecastUIController','Forecasting_Engine__c', 'commitForecastData', 'Save ForecastUIController',  e);
            return null;
        }
    }

    @AuraEnabled
    public static String getHistoryRecords(Id AccountId){
        try {
            String type='Forecasting_Engine__c';
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            Schema.SObjectType leadSchema = schemaMap.get(type);
            Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
            Map<Integer,String> monthNameMap=new Map<Integer, String>{1 =>'January', 2=>'February', 3=>'March', 4=>'April', 5=>'May',
                                                                    6=>'June', 7=>'July', 8=>'August', 9=>'September',10=>'October',
                                                                    11=>'November', 12=>'December'};
            
            String msg = '';
            List<String> msgList = new List<String>();
            for(Forecasting_Engine__History fe : [SELECT Id, Field, OldValue, NewValue, CreatedDate, Createdby.Name, Parent.Month__c, Parent.Account__r.Name FROM Forecasting_Engine__History WHERE Parent.Account__c =:AccountId OR Parent.Account__r.ParentId =: AccountId ORDER BY CreatedDate DESC LIMIT 5]){
                String fieldLabel = fieldMap.containsKey(fe.Field) ? fieldMap.get(fe.Field).getDescribe().getLabel() : '';
                if(!String.isBlank(fieldLabel) && fe.Parent.Month__c != null){
                    String tempMsg = fe.Createdby.Name + ' has updated ' + fieldLabel + ' for Account ' + fe.Parent.Account__r.Name + ' on Month ' + monthNameMap.get(fe.Parent.Month__c.month()) + ' from ' + fe.OldValue + ' to ' + fe.NewValue + ' on ' + fe.CreatedDate.format(); 
                    msgList.add(tempMsg);
                }
            }

            if(!msgList.isEmpty()){
                msg = String.join(msgList,'<br/>');
            }
            return msg;
        } catch (Exception e) {
            system.debug('$$$'+e.getmessage());
            return null;
        }
    }

    private static ForecastDetailsWrapper addForecastDetails(Forecasting_Engine__c currentForecast){

        ForecastDetailsWrapper fcw = new ForecastDetailsWrapper();
        fcw.month = currentForecast.Month__c != null ? currentForecast.Month__c.month() : 0;
        fcw.forecastDetail = currentForecast;

        /***
        1. if Month < Current Month, show Actual TPV
        2. Otherwise
        a. if Sales Input TPV (USD) is blank, then show the Final Forecast TPV (USD)
        b. If Sales Input TPV (USD) is no blank, show Sales Input TPV (USD)
        ***/
        if(fcw.month > 0){ //only if month exist
            if(fcw.month < date.today().month()){
                fcw.tempTPVDisplay = currentForecast.Actual_TPV_USD__c;
            }else{
                fcw.tempTPVDisplay = currentForecast.Sales_Input_TPV_USD__c == null ? currentForecast.Sales_Team_Approved_TPV__c : currentForecast.Sales_Input_TPV_USD__c;
            }
        }

        String actualTPV = currentForecast.Actual_TPV_USD__c != null ? String.valueOf(currentForecast.Actual_TPV_USD__c.format()) : '';
        String finalForecastTPV = currentForecast.Final_Forecast_TPV_USD_Formula__c != null ? String.valueOf(currentForecast.Final_Forecast_TPV_USD_Formula__c.format()) : '';
        String salesInputTPV = currentForecast.Sales_Input_TPV_USD__c != null ? String.valueOf(currentForecast.Sales_Input_TPV_USD__c.format()) : '';
        fcw.helpText = 'Actual TPV : ' + actualTPV + '\n' + 'Default System Forecast : ' +  finalForecastTPV + '\n' + 'Sales Team Input : ' + salesInputTPV;

        return fcw;
    }

    public class returnWrapper{
        @AuraEnabled public Double estAnnualTPV {get;set;}
        @AuraEnabled public String accType {get;set;}
        @AuraEnabled public String strHistory {get;set;}
        @AuraEnabled public List<ForecastDetailsWrapper> forecastDetails {get;set;}
        
        public returnWrapper(){
            estAnnualTPV = 0;
            accType = '';
            strHistory = '';
            forecastDetails = new List<ForecastDetailsWrapper>();
        }
    }

    public class ForecastDetailsWrapper
    {
        @AuraEnabled public Integer month {get;set;}
        @AuraEnabled public Forecasting_Engine__c forecastDetail {get;set;}
        @AuraEnabled public Double MoMTPVGrowth {get;set;}
        @AuraEnabled public Double MoMTxnGrowth {get;set;}
        @AuraEnabled public Boolean tempSalesInput {get;set;} //var to put input value from user
        @AuraEnabled public Double tempTPVDisplay {get;set;} //var to put display value based on logic
        @AuraEnabled public String helpText {get;set;}
        @AuraEnabled public totalWrapper allTotalWrapper {get;set;}
        
        public ForecastDetailsWrapper() {
            month = 0;
            forecastDetail = new Forecasting_Engine__c();
            MoMTPVGrowth = null;
            MoMTxnGrowth = null;
            tempSalesInput = false;
            tempTPVDisplay = null;
            helpText = '';
            allTotalWrapper = new totalWrapper();
        }
    }

    public class totalWrapper
    {
        @AuraEnabled public Double totalForecastTPV {get;set;}
        @AuraEnabled public Double totalSalesTeamApprovedTPV {get;set;}
        @AuraEnabled public Double totalPopulatedSalesTPV{get;set;}
        @AuraEnabled public Double totalActualTPV {get;set;}
        @AuraEnabled public Double totalDisplayTPV {get;set;}
        @AuraEnabled public Double totalTransactions {get;set;}

        public totalWrapper(){
            totalForecastTPV = null;
            totalSalesTeamApprovedTPV = null;
            totalPopulatedSalesTPV = null;
            totalActualTPV = null;
            totalDisplayTPV = null;
            totalTransactions = null;
        }
    }

    public class SubAccDetailsWrapper implements Comparable
    {
        @AuraEnabled public Account subAccObj {get;set;}
        @AuraEnabled public Double subAccAnnualTPVDisplay {get;set;}
        @AuraEnabled public List<ForecastDetailsWrapper> subAccForecastDetails {get;set;}

        public SubAccDetailsWrapper(){
            subAccObj = new Account();
            subAccAnnualTPVDisplay = null;
            subAccForecastDetails = new List<ForecastDetailsWrapper>();
        }

        public Integer compareTo(Object compareTo) 
        {
            SubAccDetailsWrapper SubAccDetailsWrapper = (SubAccDetailsWrapper) compareTo;
            if (subAccAnnualTPVDisplay == SubAccDetailsWrapper.subAccAnnualTPVDisplay) return 0;
            if (subAccAnnualTPVDisplay < SubAccDetailsWrapper.subAccAnnualTPVDisplay) return 1;
            return -1;        
        }
    }
}