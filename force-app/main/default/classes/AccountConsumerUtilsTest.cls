@isTest
private class AccountConsumerUtilsTest 
{
	public static Id BRPConsumerRecordTypeId = Query_GlobalHelper.GetRecordType('Account', AccountUtils.AccountRecordTypeEnum.BRP_Consumer.name());    	
   	public static Id MPARecordTypeId = Query_GlobalHelper.GetRecordType('Account', AccountUtils.AccountRecordTypeEnum.Marketing_Person_Account.name());

	@testSetup 
    static void TestData()
    {
        insert new List<Account>
        {
            new Account(FirstName = 'Consumer', LastName = 'EmptyConsumer', recordtypeId = BRPConsumerRecordTypeId, PersonEmail = 'EmptyConsumer@test.com'),
            new Account(FirstName = 'Consumer', LastName = 'EmptyMPA', recordtypeId = MPARecordTypeId, PersonEmail = 'EmptyMPA@test.com'),
            new Account(FirstName = 'Consumer', LastName = '12345', recordtypeId = BRPConsumerRecordTypeId, PersonEmail = '12345@test.com', SurrogateId__c = '12345'),
            new Account(FirstName = 'Consumer', LastName = '98765', recordtypeId = MPARecordTypeId, PersonEmail = '98765@test.com', Experian_ID__c = '98765', External_ID__c = '84598'), // Marketing Person Account not link to existing BRP Consumer
            new Account(FirstName = 'Consumer', LastName = '98765', recordtypeId = MPARecordTypeId, PersonEmail = '987652@test.com', Experian_ID__c = '00000', External_ID__c = '748596'),
            new Account(FirstName = 'Consumer', LastName = 'Parent', recordtypeId = BRPConsumerRecordTypeId, PersonEmail = 'Parent@test.com', SurrogateId__c = '99999'),
            new Account(FirstName = 'Consumer', LastName = 'Child', recordtypeId = MPARecordTypeId, PersonEmail = 'Parent2@test.com', Experian_ID__c = '99999', External_ID__c = '99999')
        };
    }

    static testMethod void testBuildExperianIds_NewAccount()
    {
        AccountConsumerUtils accountConsumerUtils = new AccountConsumerUtils(BRPConsumerRecordTypeId, MPARecordTypeId);
        List<Account> consumers = new List<Account> 
        {
            new Account(FirstName = 'Consumer', LastName= '00000', recordtypeId = BRPConsumerRecordTypeId, SurrogateId__c = '00000'),
            new Account(FirstName = 'Consumer', LastName= '00000', recordtypeId = MPARecordTypeId, Experian_ID__c = '00000'),
            new Account(FirstName = 'Consumer', LastName= '98765', recordtypeId = BRPConsumerRecordTypeId, SurrogateId__c = '98765'),
            new Account(FirstName = 'Consumer', LastName= '12345', recordtypeId = MPARecordTypeId, Experian_ID__c = '12345', External_ID__c = '555555')
        };

        Test.startTest();
        for (Account a: consumers)
        {
            accountConsumerUtils.BuildExperianIds(null, a);
        }
        Test.stopTest();

        Integer count = 0;
        for (Account a: consumers)
        {
            if(String.isNotBlank(a.Experian_ID__c))
            {
                accountConsumerUtils.experianIdsBefore.contains(a.Experian_ID__c);
                count++;
            } 
        }
        System.assertEquals(count, accountConsumerUtils.experianIdsBefore.size());   
    }

    static testMethod void testBuildExperianIds_UpdateAccount()
    {
        AccountConsumerUtils accountConsumerUtils = new AccountConsumerUtils(BRPConsumerRecordTypeId, MPARecordTypeId);
        Account oldAcc = [SELECT Id, Experian_ID__c, recordTypeId FROM Account WHERE External_ID__c = '748596'];
        Account newAcc = [SELECT Id, Experian_ID__c, recordTypeId FROM Account WHERE External_ID__c = '748596'];
        newAcc.Experian_ID__c = '12345';

        Test.startTest();
    	accountConsumerUtils.BuildExperianIds(oldAcc, newAcc);
    	Test.stopTest();
    	
        System.assertEquals(1, accountConsumerUtils.experianIdsBefore.size());
        System.assert(accountConsumerUtils.mapParentTransfer.containsKey(newAcc.Id));
        System.assertEquals(oldAcc.Experian_ID__c, accountConsumerUtils.mapParentTransfer.get(newAcc.Id).oldExperian_ID);
    }

    static testMethod void testBuildExperianAndSurrogateIdsCollections_NewAccount()
    {
        AccountConsumerUtils accountConsumerUtils = new AccountConsumerUtils(BRPConsumerRecordTypeId, MPARecordTypeId);
        Map<String, Account> consumers = new Map<String, Account>
        {
            'MPAEmpty' => new Account(FirstName = 'Consumer', LastName = '00000', recordtypeId = MPARecordTypeId),
            'ConsumerWithData' => new Account(FirstName = 'Consumer', LastName = '98765', recordtypeId = BRPConsumerRecordTypeId, SurrogateId__c = '98765'),
            'ConsumerEmpty' => new Account(FirstName = 'Consumer', LastName = '98765', recordtypeId = BRPConsumerRecordTypeId),
            'MPAWithData' => new Account(FirstName = 'Consumer', LastName = '12345', recordtypeId = MPARecordTypeId, Experian_ID__c = '12345', External_ID__c = '555555')
        };
        insert consumers.values();

        Test.startTest();
        for (Account a: consumers.values())
        {
            accountConsumerUtils.BuildExperianAndSurrogateIdsCollections(null, a);
        }
    	Test.stopTest();

        System.assertEquals(2, accountConsumerUtils.experianIdsAfter.size()); 
        System.assert(accountConsumerUtils.experianIdsAfter.contains('12345'));
        System.assert(accountConsumerUtils.experianIdsAfter.contains('98765'));  
        System.assertEquals(1, accountConsumerUtils.surrogateIds.size());
        System.assert(accountConsumerUtils.surrogateIds.contains('98765'));
        System.assertEquals(1, accountConsumerUtils.mapBPRConsumers.size());
        System.assert(accountConsumerUtils.mapBPRConsumers.containskey('98765'));
        System.assertEquals(consumers.get('ConsumerWithData').Id, accountConsumerUtils.mapBPRConsumers.get('98765'));
    }

    static testMethod void testBuildExperianAndSurrogateIdsCollections_UpdateAccount()
    {
        AccountConsumerUtils accountConsumerUtils = new AccountConsumerUtils(BRPConsumerRecordTypeId, MPARecordTypeId);
        Map<String, Account> consumers = new Map<String, Account>
        {
            'MPAEmpty' => new Account(FirstName = 'Consumer', LastName = '00000', recordtypeId = MPARecordTypeId),
            'ConsumerWithData' => new Account(FirstName = 'Consumer', LastName = '98765', recordtypeId = BRPConsumerRecordTypeId, SurrogateId__c = '98765'),
            'ConsumerEmpty' => new Account(FirstName = 'Consumer', LastName = '98765', recordtypeId = BRPConsumerRecordTypeId),
            'MPAWithData' => new Account(FirstName = 'Consumer', LastName = '12345', recordtypeId = MPARecordTypeId, Experian_ID__c = '12345', External_ID__c = '555555')
        };

        Test.startTest();
        for (Account a: consumers.values())
        {
            accountConsumerUtils.BuildExperianAndSurrogateIdsCollections(a, a);
        }
    	Test.stopTest();

        System.assertEquals(1, accountConsumerUtils.experianIdsAfter.size()); 
        System.assert(accountConsumerUtils.experianIdsAfter.contains(consumers.get('MPAWithData').Experian_ID__c));
        System.assertEquals(0, accountConsumerUtils.surrogateIds.size());
        System.assertEquals(0, accountConsumerUtils.mapBPRConsumers.size());   
    }

    static testMethod void testFinalize_ConsumerWithMPA()
    {
        AccountConsumerUtils accountConsumerUtils = new AccountConsumerUtils(BRPConsumerRecordTypeId, MPARecordTypeId);
        Account oldAcc = [SELECT Id, Experian_ID__c, recordTypeId FROM Account WHERE External_ID__c = '748596'];
        Account newAcc = [SELECT Id, Experian_ID__c, recordTypeId FROM Account WHERE External_ID__c = '748596'];
        newAcc.Experian_ID__c = '12345';

        accountConsumerUtils.BuildExperianIds(oldAcc, newAcc);

        Test.startTest();
        accountConsumerUtils.Finalize(new List<Account> { newAcc });
    	Test.stopTest();

        List<Account> mpas = [SELECT Id FROM Account WHERE SurrogateId__c =: newAcc.Experian_ID__c];
		System.assert(mpas.size() > 0);
        System.assertEquals(mpas[0].Id, newAcc.BRPConsumer__c);	                        	
    }

    static testMethod void testFinalize_MPAWithConsumer()
    {
        AccountConsumerUtils accountConsumerUtils = new AccountConsumerUtils(BRPConsumerRecordTypeId, MPARecordTypeId);
        Account childAcc = new Account(FirstName = 'Consumer', LastName = 'Child', recordtypeId = MPARecordTypeId, PersonEmail = '88888child@test.com', Experian_ID__c = '88888', External_ID__c = '88888');       
        Account parentAcc = new Account(FirstName = 'Consumer', LastName = 'Parent', recordtypeId = BRPConsumerRecordTypeId, PersonEmail = '88888Parent@test.com', SurrogateId__c = '88888');
        insert childAcc; 
        insert parentAcc;
        
        accountConsumerUtils.BuildExperianAndSurrogateIdsCollections(null, childAcc);

        Test.startTest();
        accountConsumerUtils.Finalize(new List<Account> { childAcc });
        Test.stopTest();

        parentAcc = [SELECT PersonEmail FROM Account WHERE Id =: parentAcc.Id];
        System.assertEquals(childAcc.PersonEmail, parentAcc.PersonEmail);
    }
 
    static testMethod void  testFinalize_MPAUpdateConsumerWithCase()
    {
        AccountConsumerUtils accountConsumerUtils = new AccountConsumerUtils(BRPConsumerRecordTypeId, MPARecordTypeId);
        Account parentBRPConsumer = [SELECT Id FROM Account WHERE SurrogateId__c = '99999' LIMIT 1];
        
        PrepareTestDataCase.LoadConfiguration();
        Case newCase = PrepareTestDataCase.CreateCACWebConsumerCase(parentBRPConsumer);    
    	insert newCase;

        Account childAcc = [SELECT Id, recordTypeId, BRPConsumer__c, Experian_ID__c FROM Account WHERE Experian_ID__c = '99999' LIMIT 1];
        Account newChildAcc = [SELECT Id, recordTypeId, BRPConsumer__c, Experian_ID__c FROM Account WHERE Experian_ID__c = '99999' LIMIT 1]; 
        newChildAcc.Experian_ID__c = '12345';

        accountConsumerUtils.BuildExperianIds(childAcc, newChildAcc);

        Test.startTest();
    	accountConsumerUtils.Finalize(new List<Account> { newChildAcc });
    	Test.stopTest();

        Account newParentBRPConsumer = [SELECT Id FROM Account WHERE SurrogateId__c = '12345' LIMIT 1];

        System.assertEquals(0, [SELECT count() FROM Case WHERE AccountId =: parentBRPConsumer.Id]);
        System.assertEquals(1, [SELECT count() FROM Case WHERE AccountId =: newParentBRPConsumer.Id]);
    	System.assertEquals(0, [SELECT count() FROM Account WHERE SurrogateId__c = '99999']); 
    } 
}