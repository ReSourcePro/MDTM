/**
 * Handler rows are mocked with in-memory Trigger_Handler__mdt via MDTM.setupTestHandlers — no Custom Metadata records in source.
 */
@IsTest
private class MDTMTest {
    @IsTest
    static void testBeforeInsertDirectContext() {
        MDTM.resetInternalStateForTests();
        resetStubCounts();
        MDTM.setupTestHandlers(
            new List<Trigger_Handler__mdt>{
                new Trigger_Handler__mdt(
                    Object__c = '' + Contact.SObjectType,
                    Class__c = 'MDTM.TestStubBeforeInsert',
                    Active__c = true,
                    Load_Order__c = 1
                )
            }
        );

        MDTM.TriggerContext ctx = new MDTM.TriggerContext();
        ctx.isBefore = true;
        ctx.isInsert = true;
        ctx.newRecords = new List<Contact>{ new Contact(LastName = 'A') };

        MDTM.handle(Contact.SObjectType, ctx);

        System.assertEquals(1, MDTM.stubBeforeInsertCount);
    }

    @IsTest
    static void testHandlersFilteredByObject() {
        MDTM.resetInternalStateForTests();
        resetStubCounts();
        MDTM.setupTestHandlers(
            new List<Trigger_Handler__mdt>{
                new Trigger_Handler__mdt(
                    Object__c = 'Account',
                    Class__c = 'MDTM.TestStubBeforeInsert',
                    Active__c = true,
                    Load_Order__c = 1
                ),
                new Trigger_Handler__mdt(
                    Object__c = '' + Contact.SObjectType,
                    Class__c = 'MDTM.TestStubBeforeInsert',
                    Active__c = true,
                    Load_Order__c = 1
                )
            }
        );

        MDTM.TriggerContext ctx = new MDTM.TriggerContext();
        ctx.isBefore = true;
        ctx.isInsert = true;
        ctx.newRecords = new List<Contact>{ new Contact(LastName = 'B') };

        MDTM.handle(Contact.SObjectType, ctx);

        System.assertEquals(1, MDTM.stubBeforeInsertCount);
    }

    @IsTest
    static void testHandlerInvocationOrder() {
        MDTM.resetInternalStateForTests();
        resetStubCounts();
        MDTM.setupTestHandlers(
            new List<Trigger_Handler__mdt>{
                new Trigger_Handler__mdt(
                    Object__c = '' + Contact.SObjectType,
                    Class__c = 'MDTM.TestStubBeforeInsert',
                    Active__c = true,
                    Load_Order__c = 1
                ),
                new Trigger_Handler__mdt(
                    Object__c = '' + Contact.SObjectType,
                    Class__c = 'MDTM.TestStubAfterInsert',
                    Active__c = true,
                    Load_Order__c = 2
                )
            }
        );

        MDTM.TriggerContext ctx = new MDTM.TriggerContext();
        ctx.isBefore = true;
        ctx.isInsert = true;
        ctx.newRecords = new List<Contact>{ new Contact(LastName = 'C') };

        MDTM.handle(Contact.SObjectType, ctx);

        ctx = new MDTM.TriggerContext();
        ctx.isAfter = true;
        ctx.isInsert = true;
        ctx.newRecords = new List<Contact>{ new Contact(LastName = 'C') };

        MDTM.handle(Contact.SObjectType, ctx);

        System.assertEquals(1, MDTM.stubBeforeInsertCount);
        System.assertEquals(1, MDTM.stubAfterInsertCount);
    }

    @IsTest
    static void testHandlerBranchesAndNullType() {
        MDTM.resetInternalStateForTests();
        resetStubCounts();

        MDTM.TriggerContext ctx = new MDTM.TriggerContext();
        ctx.isBefore = true;
        ctx.isInsert = true;
        ctx.newRecords = new List<Contact>{ new Contact(LastName = 'E') };

        Trigger_Handler__mdt badClass = new Trigger_Handler__mdt(
            Object__c = '' + Contact.SObjectType,
            Class__c = 'NoSuchClass',
            Active__c = true,
            Load_Order__c = 1
        );
        MDTM.handle(badClass, ctx);

        MDTM.handle((List<Trigger_Handler__mdt>) null, ctx);

        Trigger_Handler__mdt noopWrongPhase = new Trigger_Handler__mdt(
            Object__c = '' + Contact.SObjectType,
            Class__c = 'MDTM.TestStubBeforeInsert',
            Active__c = true,
            Load_Order__c = 1
        );
        ctx = new MDTM.TriggerContext();
        ctx.isAfter = true;
        ctx.isInsert = true;
        ctx.newRecords = new List<Contact>{ new Contact(LastName = 'E') };
        MDTM.handle(noopWrongPhase, ctx);
    }

    @IsTest
    static void testAllTriggerPhases() {
        MDTM.resetInternalStateForTests();
        resetStubCounts();

        Contact c = new Contact(LastName = 'F');
        insert c;

        MDTM.setupTestHandlers(
            new List<Trigger_Handler__mdt>{
                new Trigger_Handler__mdt(
                    Object__c = '' + Contact.SObjectType,
                    Class__c = 'MDTM.TestStubBeforeUpdate',
                    Active__c = true,
                    Load_Order__c = 1
                ),
                new Trigger_Handler__mdt(
                    Object__c = '' + Contact.SObjectType,
                    Class__c = 'MDTM.TestStubAfterUpdate',
                    Active__c = true,
                    Load_Order__c = 2
                )
            }
        );

        MDTM.TriggerContext ctx = new MDTM.TriggerContext();
        ctx.isBefore = true;
        ctx.isUpdate = true;
        ctx.newRecords = new List<Contact>{ c };
        ctx.oldRecordsMap = new Map<Id, SObject>{ c.Id => c.clone(true, true, true, true) };

        MDTM.handle(Contact.SObjectType, ctx);

        ctx = new MDTM.TriggerContext();
        ctx.isAfter = true;
        ctx.isUpdate = true;
        ctx.newRecords = new List<Contact>{ c };
        ctx.oldRecordsMap = new Map<Id, SObject>{ c.Id => c.clone(true, true, true, true) };

        MDTM.handle(Contact.SObjectType, ctx);

        System.assertEquals(1, MDTM.stubBeforeUpdateCount);
        System.assertEquals(1, MDTM.stubAfterUpdateCount);

        MDTM.resetInternalStateForTests();
        resetStubCounts();
        MDTM.setupTestHandlers(
            new List<Trigger_Handler__mdt>{
                new Trigger_Handler__mdt(
                    Object__c = '' + Contact.SObjectType,
                    Class__c = 'MDTM.TestStubBeforeDelete',
                    Active__c = true,
                    Load_Order__c = 1
                ),
                new Trigger_Handler__mdt(
                    Object__c = '' + Contact.SObjectType,
                    Class__c = 'MDTM.TestStubAfterDelete',
                    Active__c = true,
                    Load_Order__c = 2
                )
            }
        );

        ctx = new MDTM.TriggerContext();
        ctx.isBefore = true;
        ctx.isDelete = true;
        ctx.oldRecords = new List<Contact>{ c };

        MDTM.handle(Contact.SObjectType, ctx);

        ctx = new MDTM.TriggerContext();
        ctx.isAfter = true;
        ctx.isDelete = true;
        ctx.oldRecords = new List<Contact>{ c };

        MDTM.handle(Contact.SObjectType, ctx);

        System.assertEquals(1, MDTM.stubBeforeDeleteCount);
        System.assertEquals(1, MDTM.stubAfterDeleteCount);
    }

    @IsTest
    static void testAfterUndelete() {
        MDTM.resetInternalStateForTests();
        resetStubCounts();

        Contact c = new Contact(LastName = 'G');
        insert c;

        MDTM.setupTestHandlers(
            new List<Trigger_Handler__mdt>{
                new Trigger_Handler__mdt(
                    Object__c = '' + Contact.SObjectType,
                    Class__c = 'MDTM.TestStubAfterUndelete',
                    Active__c = true,
                    Load_Order__c = 1
                )
            }
        );

        MDTM.TriggerContext ctx = new MDTM.TriggerContext();
        ctx.isAfter = true;
        ctx.isUndelete = true;
        ctx.newRecords = new List<Contact>{ c };

        MDTM.handle(Contact.SObjectType, ctx);

        System.assertEquals(1, MDTM.stubAfterUndeleteCount);
    }

    @IsTest
    static void testObjectAndHandlerTriggerEventGates() {
        MDTM.resetInternalStateForTests();
        resetStubCounts();
        MDTM.setupTestHandlers(
            new List<Trigger_Handler__mdt>{
                new Trigger_Handler__mdt(
                    Object__c = '' + Contact.SObjectType,
                    Class__c = 'MDTM.TestStubBeforeInsert',
                    Active__c = true,
                    Load_Order__c = 1
                )
            }
        );

        MDTM.getTriggerSObjectTypeEvent('Contact').disableBeforeInsert();

        MDTM.TriggerContext ctx = new MDTM.TriggerContext();
        ctx.isBefore = true;
        ctx.isInsert = true;
        ctx.newRecords = new List<Contact>{ new Contact(LastName = 'H') };

        MDTM.handle(Contact.SObjectType, ctx);
        System.assertEquals(null, MDTM.stubBeforeInsertCount);

        MDTM.getTriggerSObjectTypeEvent('Contact').enableBeforeInsert();
        MDTM.getTriggerHandlerEvent(Type.forName('MDTM.TestStubBeforeInsert')).disableBeforeInsert();

        MDTM.handle(Contact.SObjectType, ctx);
        System.assertEquals(null, MDTM.stubBeforeInsertCount);
    }

    @IsTest
    static void testHandleOneArgUsesTriggerContextOverride() {
        MDTM.resetInternalStateForTests();
        resetStubCounts();
        MDTM.setupTestHandlers(
            new List<Trigger_Handler__mdt>{
                new Trigger_Handler__mdt(
                    Object__c = '' + Contact.SObjectType,
                    Class__c = 'MDTM.TestStubBeforeInsert',
                    Active__c = true,
                    Load_Order__c = 1
                )
            }
        );

        MDTM.TriggerContext ctx = new MDTM.TriggerContext();
        ctx.isBefore = true;
        ctx.isInsert = true;
        ctx.newRecords = new List<Contact>{ new Contact(LastName = 'I') };
        MDTM.testTriggerContextOverride = ctx;

        MDTM.handle(Contact.SObjectType);

        System.assertEquals(1, MDTM.stubBeforeInsertCount);
    }

    @IsTest
    static void testHandleFromRowsEmpty() {
        MDTM.resetInternalStateForTests();
        MDTM.handleFromRows(null, null);
        MDTM.handleFromRows(new List<Contact>(), null);
    }

    @IsTest
    static void testTriggerEventApiSurface() {
        MDTM.TriggerEvent te = new MDTM.TriggerEvent();
        System.assertEquals(true, te.isEnabled(true, false, true, false, false, false));
        te.disableAll();
        System.assertEquals(false, te.isEnabled(true, false, true, false, false, false));
        System.assertEquals(true, te.isEnabled(true, false, false, false, false, false));
        te.enableAllBefore();
        te.enableAllAfter();
        te.disableAllBefore();
        te.disableAllAfter();
        te.enableBeforeInsert();
        te.disableBeforeInsert();
        te.enableBeforeUpdate();
        te.disableBeforeUpdate();
        te.enableBeforeDelete();
        te.disableBeforeDelete();
        te.enableAfterInsert();
        te.disableAfterInsert();
        te.enableAfterUpdate();
        te.disableAfterUpdate();
        te.enableAfterDelete();
        te.disableAfterDelete();
        te.enableAfterUndelete();
        te.disableAfterUndelete();
        te.enableAll();
        System.assertEquals(true, te.isEnabled(false, true, false, true, false, false));
        System.assertEquals(true, te.isEnabled(false, true, false, false, true, false));
        System.assertEquals(true, te.isEnabled(false, true, false, false, false, true));
    }

    @IsTest
    static void testGetTriggerSObjectTypeOverload() {
        MDTM.TriggerEvent a = MDTM.getTriggerSObjectTypeEvent(Contact.SObjectType);
        MDTM.TriggerEvent b = MDTM.getTriggerSObjectTypeEvent('Contact');
        System.assert(a != null && b != null);
    }

    private static void resetStubCounts() {
        MDTM.stubBeforeInsertCount = null;
        MDTM.stubBeforeUpdateCount = null;
        MDTM.stubAfterInsertCount = null;
        MDTM.stubAfterUpdateCount = null;
        MDTM.stubBeforeDeleteCount = null;
        MDTM.stubAfterDeleteCount = null;
        MDTM.stubAfterUndeleteCount = null;
    }
}
