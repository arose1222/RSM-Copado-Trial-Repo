@isTest
public class CaseControllerTest
{
	static testMethod void createFromEmptyCase()
	{
		Case sCase = new Case();
		ApexPages.StandardController sc = new ApexPages.StandardController(sCase);
		CaseController controller = new CaseController(sc);
		controller.flushProduct();
        controller.getServiceCenter();
        controller.setServiceCenter();
        controller.getProdFamilyOptions();
        controller.getProdModelOptions();
		controller.questionsToAsk = true;
		PageReference testSave = controller.saveSR();
		System.assertEquals(testSave, null);
		controller.questionsLookedAt();
		PageReference testSaveTwo = controller.saveSR();
	}

	//static testMethod void createFromNullCase()
	//{
	//	ApexPages.StandardController sc = new ApexPages.StandardController(null);
	//	CaseController controller = new CaseController(sc);
	//}
	static testMethod void createFromExistingCaseEmptyQuestions()
	{
		Product2 sProduct = (Product2)TestDataFactory.createsObject('Product2', false);
		sProduct.ProductCode = '321321322';
		List<RecordType> recordTypesForProduct = [Select Id, DeveloperName From RecordType Where sObjectType = 'Product2' AND DeveloperName = 'Software'];
		if(recordTypesForProduct.size() > 0)
		{
			sProduct.RecordTypeId = recordTypesForProduct.get(0).Id;
		}
		insert sProduct;

		Case sCase = (Case)TestDataFactory.createsObject('Case', false);
		sCase.Product__c = sProduct.Id;
		sCase.Lot_Number__c ='123121';
		insert sCase;
        ProblemCode__c pc = new ProblemCode__c();
        pc.Name = 'TEst';
        pc.Description__c ='test';
        pc.Problem_Code__c='Leaking';
        pc.QA_Review__c = false;
        pc.Life_Support__c ='N';
        pc.Complaint_Category__c= 6.0;
        insert pc;
        
        Survey__c surObj = new Survey__c(Adverse_Event__c=true, Category__c=1, Problem__c='TestProb', Name='TestSurvey');
        insert surObj;
        
        Question__c quesObj = new Question__c(Default_Response__c='TestReponse',Number__c=1,Survey__c=surObj.Id,Text__c='Test Survey');
        insert quesObj;
        
       	Response__c resObj = new Response__c(Case__c = sCase.Id, Question__c = quesObj.Id,Response__c ='Test Response', Name = 'Test');
        insert resObj;

        ApexPages.StandardController sc = new ApexPages.StandardController(sCase);
		CaseController controller = new CaseController(sc);
        controller.getProblemCodesPicklistValues();
		ApexPages.currentPage().getParameters().put('selectedProductId', sProduct.Id);
		controller.updatePicklistsFromProductId();
		ApexPages.currentPage().getParameters().put('selectedProductCode', sProduct.ProductCode);
        controller.editMode = true;
        controller.questionResponseJSON = JSON.serialize(new Map<String, Object>{
            quesObj.Id => new Map<String, Object>{
                'responseId' => resObj.Id,
                'responseValue' => 'Answer without ID'
            },
            quesObj.Id => new Map<String, Object>{
                'responseId' => null,
                'responseValue' => 'Answer with ID'
            }
        });
		controller.updatePicklistsFromProductCode();
        controller.getAdverseEventPicklistValues();
		controller.saveSR();
        controller.problemCodeSelected();
        controller.setStatus();
        controller.getCreateMode();
        controller.getEditMode();
        controller.updateFamily();
        controller.updateModel();
        controller.setCreateMode();
        controller.routeToStandardPage();
        
        ApexPages.currentPage().getParameters().put('selectedProductCode', '11111');
		controller.updatePicklistsFromProductCode();
	}
	static testMethod void createNewCaseEmptyQuestions()
	{
		Product2 sProduct = (Product2)TestDataFactory.createsObject('Product2', false);
		sProduct.ProductCode = '321321321';
		List<RecordType> recordTypesForProduct = [Select Id, DeveloperName From RecordType Where sObjectType = 'Product2' AND DeveloperName = 'Software'];
		if(recordTypesForProduct.size() > 0)
		{
			sProduct.RecordTypeId = recordTypesForProduct.get(0).Id;
		}
		insert sProduct;
		ProblemCode__c pc = new ProblemCode__c();
        pc.Name = 'TEst';
        pc.Description__c ='test';
        pc.Problem_Code__c='Leaking';
        pc.QA_Review__c = false;
        pc.Life_Support__c ='N';
        pc.Complaint_Category__c= 6.0;
        insert pc;
		Case sCase = (Case)TestDataFactory.createsObject('Case', false);
        
		ApexPages.StandardController sc = new ApexPages.StandardController(sCase);
		CaseController controller = new CaseController(sc);
		controller.getProblemCodesPicklistValues();
		ApexPages.currentPage().getParameters().put('selectedProductId', sProduct.Id);
		controller.updatePicklistsFromProductId();
		ApexPages.currentPage().getParameters().put('selectedProductCode', sProduct.ProductCode);
		controller.updatePicklistsFromProductCode();
		controller.getAdverseEventPicklistValues();
		controller.saveSR();
        controller.editSR();
        controller.getQuestionsForAdverseEvent();
        
	}
	static testMethod void createFromId()
	{
		Product2 sProduct = (Product2)TestDataFactory.createsObject('Product2', false);
		insert sProduct;

		Case sCase = (Case)TestDataFactory.createsObject('Case', false);
		sCase.Product__c = sProduct.Id;
		sCase.Lot_Number__c = '1232123';
		insert sCase;
		CaseController controller = new CaseController(sCase.Id);
		controller.cancelUpdate();
	}
	//static testMethod void createFromExistingCaseWithQuestions()
	//{

	//}
	static testMethod void removeSpartPart()
	{
		Case sCase = new Case();
		ApexPages.StandardController sc = new ApexPages.StandardController(sCase);
		CaseController controller = new CaseController(sc);
		Product2 sProduct = (Product2)TestDataFactory.createsObject('Product2', false);
		insert sProduct;
		ApexPages.currentPage().getParameters().put('selectedProductId', sProduct.Id);
		controller.updateSparePartsList();
		controller.removeSparePart();
	}
    
    // ASC Case test coverage
    static testMethod void viewASCCases(){
        Product2 sProduct = (Product2)TestDataFactory.createsObject('Product2', false);
		sProduct.ProductCode = '321321388';
		List<RecordType> recordTypesForProduct = [Select Id, DeveloperName From RecordType Where sObjectType = 'Product2' AND DeveloperName = 'Software'];
		if(recordTypesForProduct.size() > 0)
		{
			sProduct.RecordTypeId = recordTypesForProduct.get(0).Id;
		}
		insert sProduct;
		//Id ASCRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('ASC').getRecordTypeId(); 
		Id ASCRecordTypeId = [select Id, DeveloperName From RecordType Where sObjectType = 'Case' AND DeveloperName = 'ASC'].Id;
		Case sCase = (Case)TestDataFactory.createsObject('Case', false);
		sCase.Product__c = sProduct.Id;
        sCase.recordtypeID = ASCRecordTypeId;
        sCase.Lot_Number__c = '123212';
		insert sCase;
        //PageReference pageRef = new PageReference('CaseController');
        //pageRef.getParameters().put('id',sCase.id);
        //pageRef.getParameters().put('retURL','/500/o'+sCase.Id);
       // pageRef.getParameters().put('action','Send_To_Other_Party_For_Signatures');
       // Test.setCurrentPage(pageRef);
		ApexPages.StandardController sc = new ApexPages.StandardController(sCase);        
		CaseController controller = new CaseController(sc);        
		controller.routeToStandardPage();
    }
    
    static testMethod void editASCCases(){
        Product2 sProduct = (Product2)TestDataFactory.createsObject('Product2', false);
        sProduct.ProductCode = '321321388';
        List<RecordType> recordTypesForProduct = [Select Id, DeveloperName From RecordType Where sObjectType = 'Product2' AND DeveloperName = 'Software'];
        if(recordTypesForProduct.size() > 0)
        {
            sProduct.RecordTypeId = recordTypesForProduct.get(0).Id;
        }
        insert sProduct;
        //Id ASCRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('ASC').getRecordTypeId(); 
        Id ASCRecordTypeId = [select Id, DeveloperName From RecordType Where sObjectType = 'Case' AND DeveloperName = 'ASC'].Id;
        Case sCase = (Case)TestDataFactory.createsObject('Case', false);
        sCase.Product__c = sProduct.Id;
        sCase.recordtypeID = ASCRecordTypeId;
        sCase.Lot_Number__c = '123212';
        insert sCase;
        PageReference pageRef = new PageReference('CaseController');
        pageRef.getParameters().put('id',sCase.id);
        pageRef.getParameters().put('retURL','/500/o'+sCase.Id);      
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(sCase);        
        CaseController controller = new CaseController(sc);        
        controller.routeToStandardPage();
        controller.updatePicklistsFromProductId();
        controller.updatePicklistsFromProductCode();
        controller.setStatus();
        controller.getCreateMode();
        controller.getEditMode();
        controller.setCreateMode();
        controller.routeToStandardPage();
    }
    
    
    static testMethod void updateSoftwareProduct()
	{
        Id softwareProductRecordTypeId = [select Id, DeveloperName From RecordType Where sObjectType = 'Product2' AND DeveloperName = 'Software'].Id;
		Case sCase = new Case();
		ApexPages.StandardController sc = new ApexPages.StandardController(sCase);
		CaseController controller = new CaseController(sc);
		Product2 sProduct = (Product2)TestDataFactory.createsObject('Product2', false);
        sProduct.recordtypeID = softwareProductRecordTypeId;
		insert sProduct;
        
        Sotware_Version__c SW = new Sotware_Version__c();
        SW.Name = 'TestSoftware';
        SW.Product__c = sProduct.id;
        SW.Active__c = true;
        insert SW;
        
        
		ApexPages.currentPage().getParameters().put('selectedProductId', sProduct.Id);
		controller.updateSparePartsList();
		controller.removeSparePart();
	}
    static testMethod void creatExternalUserAndCase()
	{	Id RSMRecordTypeId = [select Id From RecordType Where sObjectType = 'Case' AND DeveloperName = 'RSM_Default'].Id;
     	Id accSCRecordTypeId = [select Id From RecordType Where sObjectType = 'Account' AND DeveloperName = 'Service_Centre'].Id;
        Id contTechRecordTypeId = [select Id From RecordType Where sObjectType = 'Contact' AND DeveloperName = 'Technician'].Id;
     	Account acc = (Account)TestDataFactory.createsObject('Account', false);
  		acc.RecordTypeId=accSCRecordTypeId;
     	acc.Name='Test Account';
     	acc.Active__c = TRUE;
     	insert acc;
     	Contact cont = (Contact)TestDataFactory.createsObject('Contact', false);
  		cont.RecordTypeId=contTechRecordTypeId;
     	cont.LastName = 'test';
     	cont.AccountId =acc.Id;
     	cont.FirstName = 'First Name';
     	insert cont;
     	Product2 sProduct = (Product2)TestDataFactory.createsObject('Product2', false);
        sProduct.ProductCode = '321321388';
        List<RecordType> recordTypesForProduct = [Select Id, DeveloperName From RecordType Where sObjectType = 'Product2' AND DeveloperName = 'Standard'];
        if(recordTypesForProduct.size() > 0)
        {
            sProduct.RecordTypeId = recordTypesForProduct.get(0).Id;
        }
        insert sProduct;
     	Id profId =[Select Id From Profile Where Name='RSM - Non ResMed RSM User' LIMIT 1].Id;
        User userObj = prepareUser('', profId, 'Community Test', 'User');
     	userObj.ContactId = cont.Id;
     	insert userObj;
		Case sCase = (Case)TestDataFactory.createsObject('Case', false);
        sCase.RecordTypeId = RSMRecordTypeId;
     	sCase.OwnerId = userObj.Id;
     	sCase.Product__c = sProduct.Id;
     	sCase.Lot_Number__c = '123212';
     	insert sCase;
	}
    private static User prepareUser(String roleId, String profId, String firstName, String lastName) {  

        String orgId = UserInfo.getOrganizationId();  
        String dateString =   
        String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');  
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));  
        String uniqueName = orgId + dateString + randomInt;  
        User tempUser = new User(  
            FirstName = firstName,  
            LastName = lastName,  
            email = uniqueName + '@sfdc' + orgId + '.org',  
            Username = uniqueName + '@sfdc' + orgId + '.org',  
            EmailEncodingKey = 'ISO-8859-1',  
            Alias = uniqueName.substring(18, 23),  
            TimeZoneSidKey = 'America/Los_Angeles',  
            LocaleSidKey = 'en_US',  
            LanguageLocaleKey = 'en_US',  
            ProfileId = profId
        );    
        if( String.isBlank(roleId) == false ){
            tempUser.UserRoleId = roleId;
        }
        return tempUser;  
    }
    
    static testMethod void createFromExistingCaseWithResponseOnly()
	{
		Product2 sProduct = (Product2)TestDataFactory.createsObject('Product2', false);
		sProduct.ProductCode = '321321321';
		List<RecordType> recordTypesForProduct = [Select Id, DeveloperName From RecordType Where sObjectType = 'Product2' AND DeveloperName = 'Software'];
		if(recordTypesForProduct.size() > 0)
		{
			sProduct.RecordTypeId = recordTypesForProduct.get(0).Id;
		}
		insert sProduct;

		Case sCase = (Case)TestDataFactory.createsObject('Case', false);
		sCase.Product__c = sProduct.Id;
		sCase.Lot_Number__c ='123121';
		insert sCase;
        
        Survey__c surObj = new Survey__c(Adverse_Event__c=true, Category__c=1, Problem__c='TestProb', Name='TestSurvey');
        insert surObj;
        
        Question__c quesObj = new Question__c(Default_Response__c='TestReponse',Number__c=1,Survey__c=surObj.Id,Text__c='Test Survey');
        insert quesObj;
        
       	Response__c resObj = new Response__c(Case__c = sCase.Id, Question__c = quesObj.Id,Response__c ='Test Response', Name = 'Test');
        insert resObj;

        ApexPages.StandardController sc = new ApexPages.StandardController(sCase);
		CaseController controller = new CaseController(sc);
        controller.editMode = true;
        controller.questionResponseJSON = JSON.serialize(new Map<String, Object>{
            quesObj.Id => new Map<String, Object>{
                'responseId' => resObj.Id,
                'responseValue' => 'Answer without ID'
            },
            quesObj.Id => new Map<String, Object>{
                'responseId' => resObj.Id,
                'responseValue' => 'Answer with ID'
            }
        });
		controller.saveSR();
	}
    
}