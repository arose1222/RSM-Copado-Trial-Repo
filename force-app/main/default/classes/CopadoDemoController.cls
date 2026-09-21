public with sharing class CopadoDemoController {
    @AuraEnabled(cacheable=true)
    public static String getMessage() {
        return 'Hello from Copado Demo Apex!';
    }
}