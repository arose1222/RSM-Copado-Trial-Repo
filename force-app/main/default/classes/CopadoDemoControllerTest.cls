@IsTest
private class CopadoDemoControllerTest {
    @IsTest
    static void testGetMessage() {
        Test.startTest();
        String result = CopadoDemoController.getMessage();
        Test.stopTest();

        System.assertEquals('Hello from Copado Demo Apex!', result);
    }
}