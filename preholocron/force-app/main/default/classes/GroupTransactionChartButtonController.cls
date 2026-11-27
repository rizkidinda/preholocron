public without sharing class GroupTransactionChartButtonController {
    @AuraEnabled
    public static String setupData(String AccountId, Boolean isMonthly, String reportName){
        try{
            String accountIdStr = String.escapeSingleQuotes(AccountId.substring(0,15));
            String result = null;

            List<Report> reportList = [select ID, DeveloperName from Report 
            where DeveloperName = : reportName];
            String reportId = (string)reportList.get(0).get('Id');

            Reports.ReportDescribeResult myReportResult = Reports.ReportManager.describeReport(reportId);
            Reports.ReportMetadata myReportMetaData = myReportResult.getReportMetadata();

            Reports.ReportFilter myFilters0 = myReportMetaData.getReportFilters()[0];
            Reports.ReportFilter myFilters1 = myReportMetaData.getReportFilters()[1];
            Reports.ReportFilter myFilters2 = myReportMetaData.getReportFilters()[2];
            Reports.ReportFilter myFilters3 = myReportMetaData.getReportFilters()[3];
            Reports.ReportFilter myFilters4 = myReportMetaData.getReportFilters()[4];
            Reports.ReportFilter myFilters5 = myReportMetaData.getReportFilters()[5];
            Reports.ReportFilter myFilters6 = myReportMetaData.getReportFilters()[6];
            myFilters0.setValue(accountIdStr);
            myFilters1.setValue(accountIdStr);
            myFilters2.setValue(accountIdStr);
            myFilters3.setValue(accountIdStr);
            myFilters4.setValue(accountIdStr);
            myFilters5.setValue(accountIdStr);
            if(isMonthly){
                myFilters6.setValue('Monthly');
            }

            Reports.ReportResults results = Reports.ReportManager.runReport(reportId, myReportMetaData, true);
            system.debug('results : ' + JSON.serialize(results));
            result = JSON.serialize(results);
            
            return result;
        }catch(Exception e){
            system.debug('$$$'+e.getmessage());
            return null;
        }
    }
    
    @AuraEnabled
    public static String setupReportURL(String reportName){
        String UrlReport;
        List<Report> reportList = [select ID, DeveloperName from Report where DeveloperName = : reportName];
            String reportId = (string)reportList.get(0).get('Id');
            String BaseURL = URL.getSalesforceBaseUrl().toExternalForm();
            UrlReport = BaseURL + '/lightning/r/Report/'+ reportId + '/view';
        return UrlReport;
    }
}