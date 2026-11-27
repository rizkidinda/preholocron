/**
 * @description       : 
 * @group             : 
 * @last modified on  : 15-12-2023
 * @last modified by  : arief.tjiptorahardja@mii.co.id
**/
public without sharing class HIRO_MonthlyCalculationSch implements Schedulable {
    public void execute (SchedulableContext SC){
        HIRO_MonthlyCalculationBatch batchUpdate = new HIRO_MonthlyCalculationBatch();
        Database.executeBatch(batchUpdate, 200);
    }
}