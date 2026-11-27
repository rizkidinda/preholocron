/**
 * @description       : 
 * @group             : 
 * @last modified on  : 30-10-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
@isTest
private class ForecastUIControllerTest {
    
    //create test data
    static void DataHelper(){
        Account acc1 = new Account();
        acc1.Name = 'Test Account1';
        acc1.Industry_Category__c = 'Financial Services';
        acc1.Child_Industry_v2__c = 'Bank';
        acc1.NumberOfEmployees = 100;
        acc1.Business_ID__c = 'TEST123';
        acc1.Type = 'XP MASTER';
        insert acc1;
        
        Account acc2 = new Account();
        acc2.Name = 'Test Account2';
        acc2.ParentId = acc1.Id;
        acc2.Industry_Category__c = 'Financial Services';
        acc2.Child_Industry_v2__c = 'Bank';
        acc2.NumberOfEmployees = 100;
        acc2.Business_ID__c = 'TEST234';
        acc2.Type = 'XP MANAGED';
        insert acc2;
        

        Date todayDate = Date.today();
        Integer currYear = todayDate.year();
        Date lastYearDate = Date.newInstance((currYear-1), 12, 1);

        List<Forecasting_Engine__c> fcList = new List<Forecasting_Engine__c>();

        Forecasting_Engine__c fc1 = new Forecasting_Engine__c();
        fc1.Account__c = acc1.Id;
        fc1.Month__c = lastYearDate;
        fc1.CurrencyIsoCode = 'USD';
        fc1.No_of_Transactions__c = 100;
        fcList.add(fc1);

        Forecasting_Engine__c fc2 = new Forecasting_Engine__c();
        fc2.Account__c = acc1.Id;
        fc2.Month__c = todayDate;
        fc2.CurrencyIsoCode = 'USD';
        fc2.No_of_Transactions__c = 200;
        fc2.Sales_Input_TPV_USD__c = 2500;
        fcList.add(fc2);
        
        Forecasting_Engine__c fc3 = new Forecasting_Engine__c();
        fc3.Account__c = acc2.Id;
        fc3.Month__c = lastYearDate;
        fc3.CurrencyIsoCode = 'USD';
        fc3.No_of_Transactions__c = 100;
        fcList.add(fc3);

        Forecasting_Engine__c fc4 = new Forecasting_Engine__c();
        fc4.Account__c = acc2.Id;
        fc4.Month__c = todayDate;
        fc4.CurrencyIsoCode = 'USD';
        fc4.No_of_Transactions__c = 200;
        fc4.Sales_Input_TPV_USD__c = 2500;
        fcList.add(fc4);
        insert fcList;
    }

    static testMethod void testSetupData(){
        Test.startTest();
        DataHelper();

        Account getAccount = [SELECT Id FROM Account WHERE Type = 'XP MASTER' LIMIT 1];
        String resultData = ForecastUIController.setupData(getAccount.Id);
        String resultSubData = ForecastUIController.setupSubAccountData(getAccount.Id);
        List<ForecastUIController.ForecastDetailsWrapper> subAccList = new List<ForecastUIController.ForecastDetailsWrapper>();
        ForecastUIController.returnWrapper parsedWrap = (ForecastUIController.returnWrapper) JSON.deserialize(resultData, ForecastUIController.returnWrapper.class);
        List<ForecastUIController.SubAccDetailsWrapper> parsedSubWrap = (List<ForecastUIController.SubAccDetailsWrapper>) JSON.deserialize(resultSubData, List<ForecastUIController.SubAccDetailsWrapper>.class);
        if(parsedSubWrap.size() > 0){
            for(integer i = 0 ; i < parsedSubWrap.size() ; i++){
                if(parsedSubWrap[i].subAccForecastDetails != null && parsedSubWrap[i].subAccForecastDetails.size() > 0){
                    for(integer j = 0 ; j < parsedSubWrap[i].subAccForecastDetails.size() ; j++){
                        subAccList.add(parsedSubWrap[i].subAccForecastDetails[j]);
                    }
                }
            }
        }
        String resultSave = ForecastUIController.saveForecastData(JSON.serialize(parsedWrap.forecastDetails), JSON.serialize(subAccList));
        String resultCommit = ForecastUIController.commitForecastData(JSON.serialize(parsedWrap.forecastDetails), JSON.serialize(subAccList), 2);

        Test.stopTest();
    }
}