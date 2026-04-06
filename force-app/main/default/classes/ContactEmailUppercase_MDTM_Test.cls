/**
 * Handler config is mocked with in-memory Trigger_Handler__mdt via MDTM.setupTestHandlers.
 * DML is used only where a real Contact Id is needed for a before-update context.
 * At runtime (non-test), Contact_MDTM + Trigger_Handler__mdt row load handlers via SOQL.
 */
@IsTest
private class ContactEmailUppercase_MDTM_Test {
    @IsTest
    static void uppercasesEmailOnBeforeInsert() {
        MDTM.resetInternalStateForTests();
        MDTM.setupTestHandlers(
            new List<Trigger_Handler__mdt>{
                new Trigger_Handler__mdt(
                    Object__c = 'Contact',
                    Class__c = 'ContactEmailUppercase_MDTM',
                    Active__c = true,
                    Load_Order__c = 1
                )
            }
        );

        Contact c = new Contact(LastName = 'Test', Email = 'user@example.com');
        MDTM.TriggerContext ctx = new MDTM.TriggerContext();
        ctx.isBefore = true;
        ctx.isInsert = true;
        ctx.newRecords = new List<Contact>{ c };

        MDTM.handle(Contact.SObjectType, ctx);

        System.assertEquals('USER@EXAMPLE.COM', c.Email);
    }

    @IsTest
    static void uppercasesEmailOnBeforeUpdate() {
        MDTM.resetInternalStateForTests();
        MDTM.setupTestHandlers(new List<Trigger_Handler__mdt>());

        Contact c = new Contact(LastName = 'Upd', Email = 'start@example.com');
        insert c;
        System.assertEquals('start@example.com', [SELECT Email FROM Contact WHERE Id = :c.Id].Email);

        MDTM.setupTestHandlers(
            new List<Trigger_Handler__mdt>{
                new Trigger_Handler__mdt(
                    Object__c = 'Contact',
                    Class__c = 'ContactEmailUppercase_MDTM',
                    Active__c = true,
                    Load_Order__c = 1
                )
            }
        );

        Contact oldSnap = [SELECT Id, LastName, Email FROM Contact WHERE Id = :c.Id];
        Contact newVersion = oldSnap.clone(true, true, true, true);
        newVersion.Email = 'next@Example.com';

        MDTM.TriggerContext ctx = new MDTM.TriggerContext();
        ctx.isBefore = true;
        ctx.isUpdate = true;
        ctx.newRecords = new List<Contact>{ newVersion };
        ctx.oldRecordsMap = new Map<Id, SObject>{ oldSnap.Id => oldSnap };

        MDTM.handle(Contact.SObjectType, ctx);

        System.assertEquals('NEXT@EXAMPLE.COM', newVersion.Email);
    }
}
