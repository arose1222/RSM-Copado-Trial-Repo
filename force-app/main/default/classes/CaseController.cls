/**
 * Name             : CaseController
 * Description      : CaseController
 * Change History   :
 * <Version>    <Date of Change>    <Author Name>                   <Describe the changes made>
 * ----------------------------------------------------------------------------------------------------------------------------------------------------
 * v2.0          08-06-2026        Annapurna Muvvala                Patient Tier Type, Inspection & Main PCB Replacement Changes are added as part of CPS -2514.
 *                                                                                                                    
 */
public with sharing class CaseController
{
    // Initialise instance variable to hold/load data for this session
    private Case sCase;
    //private String id;
    private Apexpages.Standardcontroller controller;
    
    public String questionResponseJSON { get; set; }
	public String developerName {get; set;}
    public String selectedFamily {get; set;}
    public String selectedModel {get; set;}
    public String selectedProductType {get;set;}
    public String selectedSoftwareVersionId { get; set;}
    public String selectedAdverseEvent { get; set;}
    public String inputId {get; set;}
    public String changeOwnerUrl { get; set;}

    private ID softwareRecordTypeId;
    
    public String selectFamily { get; set; }//EUTSV-3344,SAVE Disable and family picklist issue
	public String selectModel { get; set; }//EUTSV-3344,SAVE Disable and family picklist issue

    public Product2 selectedProduct { get; set;}
    public Boolean productsAreEmpty {get; set;}
    public Boolean problemCodesAreEmpty { get; set;}
    public Boolean questionsToAsk {get; set;}
    public Boolean enableAdverseEventSelection {get; set;}
    public Boolean productIsSoftware { get; set;}
    public Boolean selectedProductSerialized { get; set;}
    public Boolean isClosed { get; set;}
    @TestVisible private Boolean editMode = false; //made it as @testvisible for test class code coverage
    private Boolean createMode = false;
    private Boolean didWeShowQuestions { get; set; }
    public  Boolean hideServiceCenter = true;
    

    public List<Question__c> questions {get; set;}
    public List<Response__c> responses {get; set;}
    public List<Spare_Part__c> spareParts {get; set;}
    public List<Integer> serialNum {get; set;}//Changes by Anusha to accomodate Old Raw SN# and New Raw SN# changes EUTSV-3875
    public List<Spare_Part__c> sparePartsList {get; set;}
    public List<Sotware_Version__c> softwareVersions {get; set;}
    public List<SelectOption> softwareVersionOptions { get; set;}
    //public List<Product2> filteredProducts { get; set;}
    public List<ProblemCode__c> problemCodes { get; set;}
    public Map<String,ProblemCode__c> problemCodeMap {get; set;} //EUTSV-3752, Incorrect Escalate to QA - Mislabel
    private List<RecordType> recordTypesForProduct;
    public Map<String,List<String>> productDependentMapWithString { get; set;}
    public String jsonString { get; set;}
    public Map<ID, List<SelectOption>> productIdToSoftwareVersionOptions {get; set;}
    public Map<ID, Boolean> renderSoftwareVersionForProduct { get; set;}

    private static final String SOFTWARE_RECORD_TYPE = 'Software';
    public String sparePartLookupType { get { return 'SPARE_PART_LOOKUP_TYPE';}}
    public String productLookupType { get { return 'PRODUCT_LOOKUP_TYPE';}}
    
   public Boolean getServiceCenter(){
       List<User> uObjlist = [Select id,Profile.UserLicense.Name from User where Id=: UserInfo.getUserId() LIMIT 1];
       if(!uObjlist.isEmpty()){
           User uobj = uObjlist.get(0);
           if(uobj.Profile.UserLicense.Name == 'Customer Community Plus'){
               hideServiceCenter = false;
              
           }
       }
       system.debug('hideServiceCenter'+hideServiceCenter);
       return hideServiceCenter;
   }
    
    public void setServiceCenter(){      
        if(test.isRunningTest()){
            hideServiceCenter = True;
        }
    }
   
   private void updateStringsFromSelectedProduct()
    {
        // work around required due to portal users
        selectedFamily = selectedProduct.Family;
        selectedModel = selectedProduct.Model__c;
        sCase.ProductCode__c = selectedProduct.ProductCode;
    }
    public void flushProduct()
    {
        selectedProduct = new Product2();
        selectedProductType = null;
        sCase.Product__c = null;
        sCase.ProductCode__c = null;
    }
    public CaseController (Apexpages.Standardcontroller controller)
    {
        
        didWeShowQuestions = false;
        enableAdverseEventSelection = true;
        if(!test.isRunningTest()){
            controller.addFields(new List<String>{'RecordTypeId'});
        }
        this.controller = controller;
        productDependentMapWithString = GetDependentOptionsString('Product2', 'Family', 'Model__c');
        jsonString = JSON.serialize(productDependentMapWithString);
        sCase = (Case) this.controller.getRecord();
        system.debug('sCase.RecordTypeId' + sCase.RecordTypeId);
        if (sCase == null)
        {
            sCase = new Case();
            
        }
        if(String.isEmpty(sCase.Id))
        {
            createMode = true;
            questions = new List<Question__c>();
            responses = new List<Response__c>();
            questionsToAsk = false;
            selectedProduct = new Product2();
            updateStringsFromSelectedProduct();
            setUpSoftwarePicklists(selectedProduct);
            serialNum = new List<Integer>{1};//Changes by Anusha to accomodate Old Raw SN# and New Raw SN# changes -EUTSV-3875
                System.debug('In create mode'+sCase);
        }
        else
        {
            initialiseRelatedObjects(sCase.Id);
            changeOwnerUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + sCase.Id + '/a?retURL=' + sCase.Id;
        }
        String deviceContactId = ApexPages.currentPage().getParameters().get('device_contact_id');
        if(String.isNotEmpty(deviceContactId))
        {
            sCase.Device_Contact__c = deviceContactId;
        }
        String queryParam = ApexPages.currentPage().getParameters().get('developerName');
        if (queryParam != null && queryParam != '') {
            this.developerName = queryParam;
        }
    }
    /**
     *  Contructors for Service Request Controller
     */
    public CaseController (String id)
    {
        didWeShowQuestions = false;
        enableAdverseEventSelection = true;
        questionsToAsk = false;
        if (id != null)
        {
            sCase = getServiceRequestById(id);
        }
    }
    private Boolean isThisProductSoftware(Product2 theProductToCheck)
    {
        if(recordTypesForProduct == null || recordTypesForProduct.isEmpty())
        {
            recordTypesForProduct = [Select Id, DeveloperName From RecordType Where sObjectType = 'Product2'];
        }
        for(RecordType sRecordType : recordTypesForProduct)
        {
            if(sRecordType.DeveloperName == SOFTWARE_RECORD_TYPE)
            {
                softwareRecordTypeId = sRecordType.Id;
            }
        }
        return (theProductToCheck.RecordTypeId == softwareRecordTypeId);
    }
    private void initialiseRelatedObjects(ID caseId)
    {
        system.debug('caseId in 154:'+caseId);
        selectedProduct = [SELECT Id, RecordTypeId, Name, Family, Model__c,Product_Type__c, Life_Threatening__c, Description, ProductCode,GTS_Product_Identifier__c FROM Product2
                           WHERE Id IN (SELECT Product__c FROM Case WHERE Case.Id = :caseId)];
        
        setUpSoftwarePicklists(selectedProduct);
        updateStringsFromSelectedProduct();
        getQuestionsAndResponsesInit(caseId);
        serialNum = new List<Integer>{1};//Changes by Anusha to accomodate Old Raw SN# and New Raw SN# changes -EUTSV-3875
        spareParts = [SELECT Id, Software_Version__c, Case__c, Control_Number__c,Lot_Number__c, Product__c, Product__r.ProductCode, Product__r.Name,New_Raw_Serial_Number__c,Old_Raw_Serial_Number__c,
                     Product__r.Product_Type__c, Product__r.Life_Threatening__c, Product__r.Family, Product__r.Model__c,GTS_Warranty_Status__c,Product__r.GTS_Product_Identifier__c FROM Spare_Part__c WHERE Case__c = :caseId];
        List<ID> sparePartProductIds = new List<ID>();
        sparePartsList = [SELECT Id, Software_Version__c, Case__c, Control_Number__c,Lot_Number__c, Product__c, Product__r.ProductCode, Product__r.Name,New_Raw_Serial_Number__c,Old_Raw_Serial_Number__c, 
                     Product__r.Product_Type__c, Product__r.Life_Threatening__c, Product__r.Family, Product__r.Model__c,GTS_Warranty_Status__c,Product__r.GTS_Product_Identifier__c FROM Spare_Part__c WHERE Case__c = :caseId];
        for(Spare_Part__c sSparePart : spareParts)
        {
            //sparePartProductIds.add(sSparePart.Product__c);
            getSpartPartSoftwareVersionOptions(sSparePart.Product__r);
        }    
        
    }

    /* SECTION END: Product Lookup Variable Declarations */

    /**
     * Returns an instance of Service Request based on the parameter Id
     * @Param String Id
     * @Return ServiceRequest__c serviceRequest
     */
    public Case getServiceRequestById (String caseId)
    {
        List<Case> cases = [SELECT Id, CaseNumber FROM Case WHERE Id = :caseId ];
        return cases[0];
    }

    public void setStatus()
    {
        if(sCase.Status == 'Closed')
        {
            isClosed = true;
        }
        else
        {
            isClosed = false;
        }
    }

    public Boolean getCreateMode ()
    {
        return createMode;
    }

    public Boolean getEditMode ()
    {
        return editMode;
    }
	public PageReference saveSR() {
        Map<String,String> quesResponseValueMap = new Map<String,String>();
        Map<String,String> responseIdAndValueMap = new Map<String,String>();
        
        if (String.isNotBlank(questionResponseJSON)) {
        Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(questionResponseJSON);
        
        	for (String questionId : dataMap.keySet()) {
            	Map<String, Object> responseData = (Map<String, Object>) dataMap.get(questionId);
            	String responseId = (String) responseData.get('responseId'); // Might be null
            	String responseValue = (String) responseData.get('responseValue');
                if(responseId != null){
                    responseIdAndValueMap.put(responseId,responseValue);
                }else{
					quesResponseValueMap.put(questionId,responseValue);    
                }
        	}
    	}
        Profile prof = [select id,Name from Profile where id=:Userinfo.getProfileid()];
        sCase = (Case) this.controller.getRecord();
        List<Spare_Part__c> Listofspareparts = new List<Spare_Part__c>();
        if (createMode)
        {
            if(questionsToAsk && didWeShowQuestions == false)
            {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Please read through the adverse event questions in the questions tab.');
                Apexpages.addMessage(myMsg);
                return null;
            }
            try
            {
                /*
                * Contact may have been created on the fly and may not have
                * been associated with the chosen account, so associate it
                * now if possible
                */
                Boolean personAccount = false;
                if(String.isNotEmpty(sCase.AccountId))
                {
                    List<Account> sAccount = [SELECT Id, IsPersonAccount FROM Account WHERE Id =: sCase.AccountId LIMIT 1];
                    if(sAccount.size() > 0)
                    {
                        personAccount = sAccount.get(0).IsPersonAccount;
                    }
                }
                if(personAccount)
                {
                    // do nothing, it is the contact
                }
                else
                {
                    ID contactId = sCase.Device_Contact__c;
                    List<Contact> conts = [SELECT Id, AccountId FROM Contact WHERE Id = :contactId LIMIT 1];
                    if (conts != null && conts.size() > 0)
                    {
                        if (conts[0].AccountId == null) {
                            conts[0].AccountId = sCase.AccountId;
                        }
                        upsert conts[0];
                    }
                }
            }
            catch (Exception e)
            {
                Apexpages.addMessages(e);
                return null;
            }
        }

        if (createMode || editMode)
        {
            sCase.Product__c = selectedProduct.Id;

            /*Start - Added as part of CPS -2514 by Annapurna*/
            
            String pcbValue = getMainPCBReplacedValue();
                        
            sCase.GTS_Main_PCB_Replaced__c = pcbValue;
            
            String leakTestValue = getLeakTestValue();
            
            sCase.Leak_Test__c = leakTestValue;
            
            String inspectionOnlyValue = getInspectionOnlyValue();
            
            sCase.Inspection_Only__c = inspectionOnlyValue;
            

            if(selectedProduct != null && selectedProduct.GTS_Product_Identifier__c != 'Astral') {
            
                sCase.Patient_Tier_Type__c = null;
                sCase.Leak_Test__c = null;
                sCase.Inspection_Only__c = null;
               

            }

            
            if(String.isNotEmpty(selectedAdverseEvent))
            {
                sCase.Adverse_Event_Occurred__c = selectedAdverseEvent;
                system.debug('selectedAdverseEvent'+selectedAdverseEvent);
            }
            
            if(selectedProduct != null && selectedProduct.GTS_Product_Identifier__c == 'Astral' &&
                   (String.isBlank(sCase.Patient_Tier_Type__c) || String.isBlank(sCase.Inspection_Only__c))) {
            
                    ApexPages.addMessage(
                        new ApexPages.Message(
                            ApexPages.Severity.ERROR,
                            'Patient Tier Type and Inspection Only fields are required for Astral product'
                        )
                    );
                    return null; // STOP SAVE
            }

            if(spareParts != null) {
                for(Spare_Part__c sp : spareParts) {

                    if(selectedProduct.GTS_Product_Identifier__c == 'Astral' && sp.Product__r.GTS_Product_Identifier__c == 'Astral Main PCB Spare Part' && 
                        ( String.isBlank(sp.Old_Raw_Serial_Number__c) || String.isBlank(sp.New_Raw_Serial_Number__c) )) {
                    
                            ApexPages.addMessage(
                                new ApexPages.Message(
                                    ApexPages.Severity.ERROR,
                                    'The Old Raw Serial Number and the New Raw Serial Number are required for Astral Main PCB spare part.'
                                )
                            );
                            return null; // STOP SAVE
                        }
                }
            }
            /*End - Added as part of CPS -2514 by Annapurna*/
            try
            {
                System.debug('*** CREATE MODE: Now upserting Service Request: ' + sCase);
                upsert sCase;
                if(String.isNotEmpty(sCase.Id))
                {	
                    if(responseIdAndValueMap != null && !responseIdAndValueMap.isEmpty()){
                        List<Response__c> resUpdList = new List<Response__c>();
                        system.debug('responseSize::'+responseIdAndValueMap.size());
                        for(String resId:responseIdAndValueMap.KeySet()){
                            Response__c res = new Response__c(Id = resId);
                            res.Response__c = responseIdAndValueMap.get(resId);
                            resUpdList.add(res);
                        }
                        if(!resUpdList.isEmpty())
                        update resUpdList;
                    }else if(quesResponseValueMap != null && !quesResponseValueMap.isEmpty()){
                    	List<Response__c> resInsertList = new List<Response__c>();
                        system.debug('responseSize::'+quesResponseValueMap.size());
                        for(String questionId:quesResponseValueMap.KeySet()){
                            Response__c res = new Response__c();
                            res.Case__c = sCase.Id;
                            res.Question__c = questionId;
                            res.Response__c = quesResponseValueMap.get(questionId);
                            resInsertList.add(res);
                        }
                        if(!resInsertList.isEmpty())
                        insert resInsertList;    
                    }
                    // Delete old responses
                	List<Response__c> oldResponses = [SELECT Id FROM Response__c WHERE Case__c = :sCase.Id 
                                                  	  AND question__r.survey__r.Problem__c != :sCase.Adverse_Event_Occurred__c];
                	if (!oldResponses.isEmpty()) {
                    	system.debug('oldResponses::'+oldResponses.size());
                    	delete oldResponses;
                	}
                    if(spareParts != null)
                    {
                        for(Spare_Part__c sSparePart : spareParts)
                        {
                            if(String.isEmpty(sSparePart.Case__c))
                            {
                                sSparePart.Case__c = sCase.Id;
                            }
                        }
                        upsert spareParts;
                    }
                    set<Id> spids = new set<Id>();
                    if(spareParts != null ){
                    for(Spare_Part__c sp: spareParts){
                        spids.add(sp.Id);
                    }
                  }
                    if(sparePartsList != null ){
                    for(Spare_Part__c spList:sparePartsList){
                        if(!spids.contains(spList.Id)){
                            Listofspareparts.add(spList);  
                        }
                    }
                      
                    Delete Listofspareparts;
                }
                }
            }
            catch (System.Dmlexception ex)
            {
                Apexpages.addMessages(ex);
                return null;
            }
        }
        
        createMode = false;
        editMode = false;
        
        /*Uncommented - Added as part of CPS -2514 by Annapurna*/
        PageReference caseViewTab = new ApexPages.Standardcontroller(sCase).view();
        caseViewTab.setRedirect(true);
        return caseViewTab;    
        //return null;
        
    }
    public Pagereference editSR ()
    {

        editMode = true;

        return null;
    }
    
    /**
     * Action method to cancel any updates on the record. This action is immediate
     * and does not regard any validations on the field constraints. The page either
     * redirects to the Service Request tab (when creating new record) or stays on
     * the current record in Read-Only mode - when the user clicked cancel button.
     */
    public Pagereference cancelUpdate ()
    {
        PageReference serviceRequestTab = null;

        editMode = false;
        createMode = false;

        /* If user cancels creation of new record, redirect to the Service Request tab; will stay on the same page if user was editing a current record */
        if (sCase.Id == null)
        {
            serviceRequestTab = this.controller.cancel();
            
            // create mode
            //Schema.DescribeSObjectResult sCase_desc = Case.SObjectType.getDescribe();
            //serviceRequestTab = new PageReference('/' + sCase_desc.getKeyPrefix());
            //serviceRequestTab.setRedirect(true);
        }
        else
        {
            
            serviceRequestTab = new ApexPages.Standardcontroller(sCase).view();
            serviceRequestTab.setRedirect(true);
        }
        return serviceRequestTab;
    }

    //public CS_Service_Centre_Ad
    //dress_Book__c getSvc_ctr_addr_book()
    //{
    //  return svc_ctr_addr_book;
    //}

    /**
     * Method initiated only when Printable View link is clicked.
     */
    public void removeSparePart()
    {
        String selectedProductId = Apexpages.currentPage().getParameters().get('selectedProductId');
        Integer index = -1;
        String selectedsparepartid;

        for(Integer i = 0; i < spareParts.size(); i++)
        {
            Spare_Part__c sSparePart = spareParts.get(i);
            if(sSparePart.Product__r.Id == selectedProductId)
            {
                selectedsparepartid = sSparePart.Id;
                index = i;
            }
        }
        if(index > -1)
        {
            spareParts.remove(index);
        }
    
        }
    public void updateSparePartsList()
    {
        String selectedProductId = Apexpages.currentPage().getParameters().get('selectedProductId');
        if(spareParts == null)
        {
            spareParts = new List<Spare_Part__c>();
        }
        Product2 sProduct = [SELECT Id, RecordTypeId, ProductCode, Name,Product_Type__c, Life_Threatening__c, Family, Model__c,GTS_Product_Identifier__c FROM Product2 WHERE Id = :selectedProductId LIMIT 1];
        if(sProduct != null && String.isNotEmpty(sProduct.Id))
        {
            getSpartPartSoftwareVersionOptions(sProduct);
            Spare_Part__c sSparePart = new Spare_Part__c();
            sSparePart.Product__r = sProduct;
            sSparePart.Product__c = sProduct.Id;
            spareParts.add(sSparePart);
        }
    }
    private void getSpartPartSoftwareVersionOptions(Product2 theProduct)
    {
        if(productIdToSoftwareVersionOptions == null)
        {
            productIdToSoftwareVersionOptions = new Map<ID, List<SelectOption>>();
        }
        if(renderSoftwareVersionForProduct == null)
        {
            renderSoftwareVersionForProduct = new Map<ID, Boolean>();
        }
        if(isThisProductSoftware(theProduct))
        {
            List<Sotware_Version__c> sparePartSoftwareVersions = [SELECT Id, Name FROM Sotware_Version__c WHERE Active__c = true
                                                                  AND Product__c = :theProduct.Id];
            if(sparePartSoftwareVersions.size() > 0)
            {
                List<SelectOption> sparePartSoftwareVersionOptions = new List<SelectOption>();
                for(Sotware_Version__c version : sparePartSoftwareVersions)
                {
                    sparePartSoftwareVersionOptions.add(new SelectOption(version.Id,version.Name));
                }
                productIdToSoftwareVersionOptions.put(theProduct.Id, sparePartSoftwareVersionOptions);
                renderSoftwareVersionForProduct.put(theProduct.Id, true);
            }
        }
        else
        {
            renderSoftwareVersionForProduct.put(theProduct.Id, false);
        }
    }
    public void updateFamily()
    {
        selectedFamily = Apexpages.currentPage().getParameters().get('family');
    }
    public void updateModel()
    {
        selectedModel = ApexPages.currentPage().getParameters().get('model');
    }
    public List<SelectOption> getProblemCodesPicklistValues()
    {
        List<SelectOption> options = new List<SelectOption>();
        if(String.isEmpty(selectedProduct.Id))
        {
            options.add(new SelectOption('','--Please select a product--'));
            problemCodesAreEmpty = true;
        }
        else
        {
            String lifeSupportCharacter = '';
            String bothChar = 'B';
            if(selectedProduct.Life_Threatening__c)
            {
                lifeSupportCharacter = 'Y';
            }
            else
            {
                lifeSupportCharacter = 'N';
            }
            List<ProblemCode__c> lstProblemCodes = ProblemCode__c.getAll().values();
            System.debug('lstProblemCodes-->'+lstProblemCodes);
            lstProblemCodes.sort();
            problemCodes = new List<ProblemCode__c>();
            problemCodeMap = new Map<String,ProblemCode__c>();
            List<String> lstProblemCodeStringValues = new List<String>();
            for(ProblemCode__c sProblemCode : lstProblemCodes)
            {
                if(sProblemCode.Life_Support__c == bothChar || sProblemCode.Life_Support__c == lifeSupportCharacter)
                {
                    lstProblemCodeStringValues.add(sProblemCode.Problem_Code__c);
                    problemCodes.add(sProblemCode);
                    //EUTSV-3752, Incorrect Escalate to QA - Mislabel
                    problemCodeMap.put(sProblemCode.Problem_Code__c, sProblemCode);
                }
            }
            lstProblemCodeStringValues.sort();
            if(problemCodes.size() > 0)
            {
                options.add(new SelectOption('','--Select a problem code--'));
                for(String problemCodeString : lstProblemCodeStringValues)
                {
                    options.add(new SelectOption(problemCodeString,problemCodeString));
                }
                problemCodesAreEmpty = false;
            }
            else
            {
                options.add(new SelectOption('','--No results found--'));
                problemCodesAreEmpty = true;
            }
        }
        return options;
    }
    public void setUpSoftwarePicklists(Product2 theProduct)
    {
        if(String.isNotEmpty(theProduct.Id) && isThisProductSoftware(theProduct))
        {
            softwareVersions = [SELECT Id, Name FROM Sotware_Version__c WHERE Active__c = true AND Product__c = :theProduct.Id];
            if(softwareVersions.size() > 0)
            {
                softwareVersionOptions = new List<SelectOption>();
            }
            for(Sotware_Version__c version : softwareVersions)
            {
                softwareVersionOptions.add(new SelectOption(version.Id,version.Name));
            }
            productIsSoftware = true;
        }
        else
        {
            productIsSoftware = false;
            softwareVersionOptions = new List<SelectOption>();
            softwareVersionOptions.add(new SelectOption('', '--None--'));
        }
    }
    
    public PageReference problemCodeSelected()
    {
        String selectedProblemCode = Apexpages.currentPage().getParameters().get('selectedProblemCode');
        String defaultedAdverseEvent;
        
        // CHG0051768
        Decimal complaintCategory = 1.0;
        String lifeSupport = 'Y';
        String problemCode = '';
        //EUTSV-3752, Incorrect Escalate to QA - Mislabel
        //Fetching Problem Code details form problemCodeMap
        if(!problemCodeMap.isEmpty() && problemCodeMap.containsKey(selectedProblemCode)){
            defaultedAdverseEvent   = problemCodeMap.get(selectedProblemCode).Adverse_Event__c;
            complaintCategory       = problemCodeMap.get(selectedProblemCode).Complaint_Category__c;
            lifeSupport             = problemCodeMap.get(selectedProblemCode).Life_Support__c;
            problemCode             = problemCodeMap.get(selectedProblemCode).Problem_Code__c;
        }
        /*for(ProblemCode__c sProblemCode : problemCodes)
        {
            if(sProblemCode.Problem_Code__c == selectedProblemCode)
            {
                defaultedAdverseEvent   = sProblemCode.Adverse_Event__c;
                complaintCategory       = sProblemCode.Complaint_Category__c;
                lifeSupport             = sProblemCode.Life_Support__c;
                problemCode             = sProblemCode.Problem_Code__c;
                break;
            }
        }*/
        if(String.isNotEmpty(defaultedAdverseEvent))
        {
            selectedAdverseEvent = defaultedAdverseEvent;
            //sCase.Adverse_Event_Occurred__c = defaultedAdverseEvent;
            enableAdverseEventSelection = false;
        }
        else
        {
            // CHG0051768 - JIRA RDR-173 
            if ((lifeSupport == 'Y' &&
                complaintCategory == 1.0) && 
               ((problemCode == 'Life-Device Inoperable') ||
                (problemCode == 'Life-Ventilation Stopped') ||
                (problemCode == 'Life-Alarm Raised') ||
                (problemCode == 'Life-Alarm Not Raised') ||
                (problemCode == 'Life-Battery Problem') ||
                (problemCode == 'Life-Power'))) {
                    selectedAdverseEvent = 'Non Injury'; // Complies with BR 9c/10g
                    enableAdverseEventSelection = false;
                }else if ((lifeSupport == 'Y' && // 
                complaintCategory == 1.0) && // Complies with BR 10f
               ((problemCode != 'Life-Device Inoperable') &&
                (problemCode != 'Life-Ventilation Stopped') &&
                (problemCode != 'Life-Alarm Raised') &&
                (problemCode != 'Life-Alarm Not Raised') &&
                (problemCode != 'Life-Battery Problem') &&
                (problemCode != 'Life-Power'))) {
                    selectedAdverseEvent = 'Injury'; // Complies with BR 9b/10f
                    enableAdverseEventSelection = false;
                } else {
                    selectedAdverseEvent = null;
                    enableAdverseEventSelection = true;
                }
        }
        getQuestionsAndResponsesInit(null);
        return null;
    }
    public List<SelectOption> getAdverseEventPicklistValues()
    {
        system.debug('EDITPIC::'+enableAdverseEventSelection);
        List<SelectOption> options = new List<SelectOption>();
        List<String> adverseEventValues = getAdverseEventValues();
        if(enableAdverseEventSelection == false)
        {
            options.add(new SelectOption(selectedAdverseEvent, selectedAdverseEvent));
        }
        else
        {
            for(String adverseEventValue : adverseEventValues)
            {
                options.add(new SelectOption(adverseEventValue, adverseEventValue));
            }
        }
        return options;
    }
    private static List<String> getAdverseEventValues()
    {
        Schema.DescribeFieldResult adverseEventFieldResult = Case.Adverse_Event_Occurred__c.getDescribe();
        List<Schema.PicklistEntry> adverseEventPicklistEntries = adverseEventFieldResult.getPicklistValues();
        List<String> adverseEventValues = new List<String>();
        for(PicklistEntry adverseEventPicklistEntry : adverseEventPicklistEntries)
        {
            String adverseEventValue = adverseEventPicklistEntry.getValue();
            adverseEventValues.add(adverseEventValue);
        }
        return adverseEventValues;
    }
    // User has selected a product code
    public PageReference updatePicklistsFromProductId()
    {
        String selectedProductId = Apexpages.currentPage().getParameters().get('selectedProductId');
        if(String.isNotEmpty(selectedProductId))
        {
            
            selectedProduct = [SELECT Id, RecordTypeId, Name, Family, Model__c,Product_Type__c,Life_Threatening__c, Description, ProductCode,GTS_Product_Identifier__c
                                FROM Product2 WHERE Id = :selectedProductId LIMIT 1];
            updateStringsFromSelectedProduct();
            setUpSoftwarePicklists(selectedProduct);
                    
           	sCase.Patient_Tier_Type__c = null;
            sCase.Leak_Test__c = null;
            sCase.Inspection_Only__c = null; /*Added as part of CPS -2514 by Annapurna*/

        }
        else
        {
            refreshProdTabProps();
            Apexpages.addMessage(
                new Apexpages.Message(Apexpages.Severity.ERROR, 'Product ID (' + selectedProduct.ProductCode + ') does not exist.')
            );
        }
        return null;
    }
    public PageReference updatePicklistsFromProductCode()
    {
        String selectedProductCode = Apexpages.currentPage().getParameters().get('selectedProductCode');
        if(String.isNotEmpty(selectedProductCode))
        {
            List<Product2> sProducts = [SELECT Id, RecordTypeId, Name, Family, Model__c,Product_Type__c,GTS_Product_Identifier__c, Life_Threatening__c, Description, ProductCode
                                FROM Product2 WHERE ProductCode = :selectedProductCode LIMIT 1];
            if(sProducts.size() == 1)
            {
                selectedProduct = sProducts.get(0);
                sCase.Patient_Tier_Type__c = null;
                sCase.Leak_Test__c = null;
                sCase.Inspection_Only__c = null; /*Added as part of CPS -2514 by Annapurna*/

                
                updateStringsFromSelectedProduct();
                setUpSoftwarePicklists(selectedProduct);
           

            }
            else
            {
                refreshProdTabProps();
                Apexpages.addMessage(
                    new Apexpages.Message(Apexpages.Severity.ERROR, 'Product ID (' + selectedProduct.ProductCode + ') does not exist.')
                );
            }
        }
        else
        {
            refreshProdTabProps();
            Apexpages.addMessage(
                new Apexpages.Message(Apexpages.Severity.ERROR, 'Product ID (' + selectedProduct.ProductCode + ') does not exist.')
            );
        }
        return null;
    }
    public void questionsLookedAt()
    {
        // only set if we have already loaded questions
        if(questionsToAsk)
        {
            didWeShowQuestions = true;
        }
    }
    public void getQuestionsForAdverseEvent()
    {
        getQuestionsAndResponsesInit(null);
    }
    public void getQuestionsAndResponsesInit(ID caseId)
    {	system.debug('caseId in init call'+caseId);
     	List<Question__c> quesList = new List<Question__c>();
    	List<Response__c> resList = new List<Response__c>();
        if(caseId != null){
			questions = TrackwiseUtil.getQuestionsForAdverseEvent(((Case)controller.getRecord()).Adverse_Event_Occurred__c);
            if(questions != null && !questions.isEmpty()){
                responses  = TrackwiseUtil.getResponsesForAdverseEventSel(caseId,((Case)controller.getRecord()).Adverse_Event_Occurred__c);
                questionsToAsk = true;
            }else{
                questions = new List<Question__c>();
                responses = new List<Response__c>();
                questionsToAsk = false;
            }
        }else{
            if(selectedAdverseEvent != null){
                questions = TrackwiseUtil.getQuestionsForAdverseEvent(selectedAdverseEvent);  
            }else{
                questions = TrackwiseUtil.getQuestionsForAdverseEvent(((Case)controller.getRecord()).Adverse_Event_Occurred__c);
            }
            if(questions != null && !questions.isEmpty()){
                responses = new List<Response__c>();
                for(Question__c question : questions)
                {
                    Response__c sResponse = new Response__c();
                    sResponse.Question__c = question.Id;
                    sResponse.Response__c = '';
                    sResponse.Case__c = ((Case)controller.getRecord()).Id;
                    responses.add(sResponse);
                }
                questionsToAsk = true;
            }else{
                questions.clear();
                responses.clear();
                questionsToAsk = false;
            }
        }
    }
    private void refreshProdTabProps ()
    {
        selectedProduct = new Product2();
        updateStringsFromSelectedProduct();
    }
    private static Map<String,List<String>> GetDependentOptionsString(String pObjName, String pControllingFieldName, String pDependentFieldName)
    {
        Map<String,List<String>> objResults = new Map<String,List<String>>();
        //get the string to sobject global map
        Map<String,Schema.SObjectType> objGlobalMap = Schema.getGlobalDescribe();
        if (!objGlobalMap.containsKey(pObjName))
            return objResults;
        //get the type being dealt with
        Schema.SObjectType pType = objGlobalMap.get(pObjName);
        Map<String, Schema.SObjectField> objFieldMap = pType.getDescribe().fields.getMap();
        //verify field names
        if (!objFieldMap.containsKey(pControllingFieldName) || !objFieldMap.containsKey(pDependentFieldName))
            return objResults;
        //get the control values
        List<Schema.PicklistEntry> ctrl_ple = objFieldMap.get(pControllingFieldName).getDescribe().getPicklistValues();
        //get the dependent values
        List<Schema.PicklistEntry> dep_ple = objFieldMap.get(pDependentFieldName).getDescribe().getPicklistValues();
        //iterate through the values and get the ones valid for the controlling field name
        Bitset objBitSet = new Bitset();
        //set up the results
        for(Integer pControllingIndex=0; pControllingIndex<ctrl_ple.size(); pControllingIndex++){
            //get the pointer to the entry
            Schema.PicklistEntry ctrl_entry = ctrl_ple[pControllingIndex];
            //get the label
            String pControllingLabel = ctrl_entry.getLabel();
            //create the entry with the label
            objResults.put(pControllingLabel,new List<String>());
        }
        //cater for null and empty
        objResults.put('--None--',new List<String>());
        objResults.get('--None--').add('--Select a family--');

    //  objResults.put(null,new List<String>());
        //objResults.get(null).add('--Select a family--');
        //check the dependent values
        for(Integer pDependentIndex=0; pDependentIndex<dep_ple.size(); pDependentIndex++){
            //get the pointer to the dependent index
            Schema.PicklistEntry dep_entry = dep_ple[pDependentIndex];
            //get the valid for
            String pEntryStructure = JSON.serialize(dep_entry);
            TPicklistEntry objDepPLE = (TPicklistEntry)JSON.deserialize(pEntryStructure, TPicklistEntry.class);
            //if valid for is empty, skip
            if (objDepPLE.validFor==null || objDepPLE.validFor==''){
                continue;
            }
            //iterate through the controlling values
            for(Integer pControllingIndex=0; pControllingIndex<ctrl_ple.size(); pControllingIndex++){
                if (objBitSet.testBit(objDepPLE.validFor,pControllingIndex)){
                    //get the label
                    String pControllingLabel = ctrl_ple[pControllingIndex].getLabel();
                    objResults.get(pControllingLabel).add(objDepPLE.label);
                }
            }
        }
        return objResults;
    }
    
    public Pagereference routeToStandardPage ()
    {        
        PageReference page = ApexPages.currentPage();
        Map<String,String> params = page.getParameters();
        sCase = (Case) this.controller.getRecord();
        String defaultRecordTypeId = '';
        
        String hostVal = ApexPages.currentPage().getHeaders().get('Host');
        String urlVal = Apexpages.currentPage().getUrl();
        String CurrentPageURL = 'https://' + hostVal + urlVal;
        
        if(String.isNotBlank(sCase.RecordTypeId)) {
            defaultRecordTypeId = sCase.RecordTypeId;
        } else if(String.isNotBlank(params.get('recordTypeId'))) {
            defaultRecordTypeId = params.get('recordTypeId');
        } else {
            List<Schema.RecordTypeInfo> recordTypeInfoList = Case.SObjectType.getDescribe().getRecordTypeInfos();
            for(RecordTypeInfo info: recordTypeInfoList) {
                //Check default record type
                if(info.isDefaultRecordTypeMapping()){
                    defaultRecordTypeId = info.getRecordTypeId();
                    break;
                }
            }
        }
        Profile prof = [select id,Name from Profile where id=:Userinfo.getProfileid()];
        Id ASCRecordTypeId = [select Id, DeveloperName From RecordType Where sObjectType = 'Case' AND DeveloperName = 'ASC'].Id;
   		//Id FSNCaseRecTypeId = [select Id, DeveloperName From RecordType Where sObjectType = 'Case' AND DeveloperName = 'FSN_Cases'].Id;
        if(createMode && !editMode){
            if( defaultRecordTypeId == ASCRecordTypeId ){      
                PageReference caseCreatePageClassic = new PageReference('/500/e?nooverride=1&RecordType='+defaultRecordTypeId);
                caseCreatePageClassic.setRedirect(true);
                return caseCreatePageClassic;
            }
        }
         
        else if(!createMode && !editMode && !params.containsKey('retURL') && !CurrentPageURL.contains('lightning.force.com')){
            if(defaultRecordTypeId == ASCRecordTypeId){                              
                sCase = (Case) this.controller.getRecord();
                system.debug('sCase id is :' +sCase.id);
                PageReference caseViewPageClassic = new PageReference('/'+sCase.id+'?nooverride=1');
                caseViewPageClassic.setRedirect(true);                
                return caseViewPageClassic; 
            }
        }
        else if(!createMode && !editMode && CurrentPageURL.contains('lightning.force.com') && (params.get('retURL')).containsIgnoreCase('actionName=view')){
            if(defaultRecordTypeId == ASCRecordTypeId){                              
                sCase = (Case) this.controller.getRecord();
                system.debug('sCase id is :' +sCase.id);
                PageReference caseViewPageLtng = new PageReference( '/'+'lightning/r/Case'+ '/'+sCase.id+'/'+'view?nooverride=1');
                caseViewPageLtng.setRedirect(true);                
                return caseViewPageLtng; 
            }
        }
    
        
             
        return null;
    }
    
    public void setCreateMode(){      
        if(test.isRunningTest()){
            createMode = True;
        }
    }
    //EUTSV-3344,SAVE Disable and family picklist issue
    public List<SelectOption> getProdFamilyOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--None--')); // optional default
        
        // Describe the field
        Schema.DescribeFieldResult fieldResult = Product2.Family.getDescribe();
        
        // Get picklist values
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry entry : picklistValues) {
            options.add(new SelectOption(entry.getValue(), entry.getLabel()));
        }
        
        return options;
    }
    //EUTSV-3344,SAVE Disable and family picklist issue
    public List<SelectOption> getProdModelOptions() {
    	List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--Select a family--')); // optional default
        
        // Describe the field
        Schema.DescribeFieldResult fieldResult = Product2.Model__c.getDescribe();
        
        // Get picklist values
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry entry : picklistValues) {
            options.add(new SelectOption(entry.getValue(), entry.getLabel()));
        }
        
        return options;    
    }
    
    /*Added as part of CPS -2514 by Annapurna*/
    public String getMainPCBReplacedValue() {

        if(selectedProduct == null || 
           selectedProduct.GTS_Product_Identifier__c != 'Astral') {
            return null;
        }
    
        String result = '';

        if(spareParts != null) {
            for(Spare_Part__c sp : spareParts) {
    
                if(sp.Product__r != null && selectedProduct.GTS_Product_Identifier__c == 'Astral' && 
                   sp.Product__r.GTS_Product_Identifier__c == 'Astral Main PCB Spare Part') {
                    result = 'Yes';
                    break;
                }
            }
        }
    
        return result;
    }
    
    public string getLeakTestValue(){
        String leakTestValue = '';
        
        if(sCase.Patient_Tier_Type__c == 'Tier 1 : Highest potential risk of harm' || sCase.Patient_Tier_Type__c == 'Tier 2 : Moderate potential risk of harm'){
            leakTestValue = 'Yes';
        }else{
            leakTestValue = 'No';
        }
        return leakTestValue;
    }
    
     public string getInspectionOnlyValue(){
        String inspectionValue = '';
        
        if(sCase.Patient_Tier_Type__c != 'Tier 1 : Highest potential risk of harm'){
            inspectionValue = 'No';
        }else{
            inspectionValue = sCase.Inspection_Only__c;
        }
        return inspectionValue;
    }
    
    public Boolean getShowInspectionOnly() {
       

    System.debug('Tier Value = ' + sCase);
        System.debug('Selected Product'+selectedProduct.GTS_Product_Identifier__c+sCase.Patient_Tier_Type__c);
    	return selectedProduct != null &&
           selectedProduct.GTS_Product_Identifier__c =='Astral'&&
           sCase.Patient_Tier_Type__c == 'Tier 1 : Highest potential risk of harm';
            
	}
    
    
   
    public PageReference handlePatientTierChange() {
    
        System.debug('Tier Selected = ' + sCase.Patient_Tier_Type__c);
    
        if(sCase.Patient_Tier_Type__c == 'Tier 1 : Highest potential risk of harm') {
    
            sCase.Inspection_Only__c = null;
        }
    
        return null;
    }


}