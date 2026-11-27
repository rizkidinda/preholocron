/** 
 * Utility class related to Revenue Calculation
*/
public class RevenueClass {

    public final static String FORMULA1 = 'Fixed fee per transaction'; 
    public final static String FORMULA2 = 'Rate % per TPV'; 
    public final static String FORMULA3 = 'Fixed fee per transaction + Fixed % on TPV';
    public final static String FORMULA4 = 'Fixed % on XE exchange rate'; 
    public final static String FORMULA5 = 'Fixed fee per Active Subacc + Fixed % on TPV OR Fixed fee per transaction (whichever is lower)';
    public final static String FORMULA6 = 'Fixed fee per event'; 
    public final static String FORMULA7 = 'Fixed fee per transaction + Fixed (%) on TPV';
    public final static String FORMULA8 = 'Manual Input';
    public final static String FORMULA9 = 'FX Product';
    public final static String FORMULA10 = 'VAS Product';
    
    /** return a map for Product Family to Formula Calculation */
    public static Map<String, String> getMapFamily2Formula()
    {
        Map<String, String> mapData = new Map<String, String>();
        mapData.put('ACH Direct Debit', '');
        //mapData.put('Cards Authentication', '');
        //mapData.put('Cards Authorization', '');
        //mapData.put('Cards Fraud Detection', '');
        mapData.put('Cards Payment', FORMULA3);
        mapData.put('Cybersource', FORMULA6);
        mapData.put('Disbursements', FORMULA1);
        mapData.put('Direct Debit', FORMULA3);
        mapData.put('Escrow', FORMULA1);
        mapData.put('eWallets', FORMULA3);
        mapData.put('Iluma Products', FORMULA6);
        mapData.put('ID IM Remittance Disbursement', FORMULA1);
        mapData.put('Paylater', FORMULA3);
        mapData.put('QR', FORMULA2);
        mapData.put('Retail Outlets', FORMULA1);
        mapData.put('Over the Counter (OTC)', FORMULA1);
        //mapData.put('Remittance Disbursements (MI+MO)', '');
        //mapData.put('Remittance Disbursements (MO)', '');
        mapData.put('Virtual Account', FORMULA1);
        //mapData.put('xenCap Early Settlement', '');
        mapData.put('xenPlatform', FORMULA5);
        mapData.put('XRS Collection Fee', FORMULA1);
        mapData.put('XPS Disbursements', FORMULA1);
        mapData.put('XRS Forex', FORMULA4);
        mapData.put('XRS Service Fee', FORMULA2);
        mapData.put('Unsupported Product - PG', FORMULA7);
        mapData.put('Unsupported Product - Non PG/VAS', FORMULA8);
        mapData.put('Cross Border PG FX', FORMULA9);
        mapData.put('Remittance FX', FORMULA9);
        mapData.put('VAS Product', FORMULA10);

                    
        return mapData;
    }
    
    // get revenue calculation name from Product Family
    public static String getRevenueFormula(String strFamily)
    {
        Map<String, String> mapName = RevenueClass.getMapFamily2Formula();
        if (mapName.containsKey(strFamily)) {
            system.debug('DEBUG: found it ' + mapName.get(strFamily));
            return mapName.get(strFamily);
        }
        system.debug('DEBUG: not found family ' + strFamily);
        return '';
    }
}