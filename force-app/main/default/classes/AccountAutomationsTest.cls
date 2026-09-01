@IsTest
private class AccountAutomationsTest {

    // ── setDefaultDescription ──────────────────────────────────────────────

    @IsTest
    static void setDefaultDescription_nullDescription_setsDefault() {
        Account a = new Account(Name = 'Test Account', Description = null);

        Test.startTest();
        Account result = AccountAutomations.setDefaultDescription(a);
        Test.stopTest();

        Assert.areEqual('Default description', result.Description,
            'Description should be set to the default value when null.');
    }

    @IsTest
    static void setDefaultDescription_existingDescription_keepsOriginal() {
        Account a = new Account(Name = 'Test Account', Description = 'My custom description');

        Test.startTest();
        Account result = AccountAutomations.setDefaultDescription(a);
        Test.stopTest();

        Assert.areEqual('My custom description', result.Description,
            'Description should remain unchanged when already populated.');
    }

    // ── setDefaultBillingAddress ───────────────────────────────────────────

    @IsTest
    static void setDefaultBillingAddress_always_setsAddress() {
        Account a = new Account(Name = 'Test Account');

        Test.startTest();
        Account result = AccountAutomations.setDefaultBillingAddress(a);
        Test.stopTest();

        Assert.areEqual('Basauri, 6', result.BillingStreet,
            'BillingStreet should be set to the default value.');
        Assert.areEqual('Madrid', result.BillingState,
            'BillingState should be set to the default value.');
        Assert.areEqual('28023', result.BillingPostalCode,
            'BillingPostalCode should be set to the default value.');
    }

    // ── setDefaultShippingAddress ──────────────────────────────────────────

    @IsTest
    static void setDefaultShippingAddress_always_setsAddress() {
        Account a = new Account(Name = 'Test Account');

        Test.startTest();
        Account result = AccountAutomations.setDefaultShippingAddress(a);
        Test.stopTest();

        Assert.areEqual('Basauri, 6', result.ShippingStreet,
            'ShippingStreet should be set to the default value.');
        Assert.areEqual('Madrid', result.ShippingState,
            'ShippingState should be set to the default value.');
        Assert.areEqual('28023', result.ShippingPostalCode,
            'ShippingPostalCode should be set to the default value.');
    }

    // ── setDefaultPhone ────────────────────────────────────────────────────

    @IsTest
    static void setDefaultPhone_always_setsPhone() {
        Account a = new Account(Name = 'Test Account');

        Test.startTest();
        Account result = AccountAutomations.setDefaultPhone(a);
        Test.stopTest();

        Assert.areEqual('688456789', result.Phone,
            'Phone should be set to the default value.');
    }

    // ── setDefaultURL ──────────────────────────────────────────────────────

    @IsTest
    static void setDefaultURL_always_setsWebsite() {
        Account a = new Account(Name = 'Test Account');

        Test.startTest();
        Account result = AccountAutomations.setDefaultURL(a);
        Test.stopTest();

        Assert.areEqual('www.copa.do', result.Website,
            'Website should be set to the default value.');
    }
}