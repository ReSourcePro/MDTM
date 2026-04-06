global inherited sharing class MDTM {

    global interface BeforeInsert {
        void onBeforeInsert(List<SObject> records);
    }

    global interface AfterInsert {
        void onAfterInsert(List<SObject> records);
    }

    global interface BeforeUpdate {
        void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecordsMap);
    }

    global interface AfterUpdate {
        void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecordsMap);
    }

    global interface BeforeDelete {
        void onBeforeDelete(List<SObject> records);
    }

    global interface AfterDelete {
        void onAfterDelete(List<SObject> records);
    }

    global interface AfterUndelete {
        void onAfterUndelete(List<SObject> records);
    }

    global inherited sharing class TriggerContext {
        global Boolean isBefore = false;
        global Boolean isAfter = false;
        global Boolean isInsert = false;
        global Boolean isUpdate = false;
        global Boolean isDelete = false;
        global Boolean isUndelete = false;
        global List<SObject> newRecords;
        global List<SObject> oldRecords;
        global Map<Id, SObject> oldRecordsMap;
    }

    @TestVisible
    private static TriggerContext testTriggerContextOverride;

    global static TriggerContext getTriggerContext() {
        if (Test.isRunningTest() && testTriggerContextOverride != null) {
            return testTriggerContextOverride;
        }
        TriggerContext triggerContextVar = new TriggerContext();
        triggerContextVar.isBefore = Trigger.isBefore;
        triggerContextVar.isAfter = Trigger.isAfter;
        triggerContextVar.isInsert = Trigger.isInsert;
        triggerContextVar.isUpdate = Trigger.isUpdate;
        triggerContextVar.isDelete = Trigger.isDelete;
        triggerContextVar.isUndelete = Trigger.isUndelete;
        triggerContextVar.newRecords = Trigger.new;
        triggerContextVar.oldRecords = Trigger.old;
        triggerContextVar.oldRecordsMap = Trigger.oldMap;
        return triggerContextVar;
    }

    global static void handle() {
        handleFromRows(Trigger.new, Trigger.old);
    }

    @TestVisible
    private static void handleFromRows(List<SObject> newRows, List<SObject> oldRows) {
        List<SObject> rows = newRows != null ? newRows : oldRows;
        if (rows == null || rows.isEmpty()) {
            return;
        }
        handle(rows[0].getSObjectType());
    }

    private static List<Trigger_Handler__mdt> testHandlers = new List<Trigger_Handler__mdt>();

    global static void setupTestHandlers(List<Trigger_Handler__mdt> testHandlers) {
        MDTM.testHandlers = testHandlers == null ? new List<Trigger_Handler__mdt>() : testHandlers;
    }

    global static void handle(SObjectType sObjectTypeVar) {
        handle(sObjectTypeVar, getTriggerContext());
    }

    global static void handle(SObjectType sObjectTypeVar, TriggerContext triggerContextVar) {
        List<Trigger_Handler__mdt> handlers = getHandlers(sObjectTypeVar);
        handle(handlers, triggerContextVar);
    }

    private static final Map<String, List<Trigger_Handler__mdt>> HANDLERS_BY_OBJECT = new Map<String, List<Trigger_Handler__mdt>>();

    private static List<Trigger_Handler__mdt> getHandlers(SObjectType sObjectTypeVar) {
        List<Trigger_Handler__mdt> handlers = new List<Trigger_Handler__mdt>();
        Boolean useTestHandlers = Test.isRunningTest();

        if (useTestHandlers == true) {
            handlers = new List<Trigger_Handler__mdt>();
            for (Trigger_Handler__mdt testHandlerVar : MDTM.testHandlers) {
                if (testHandlerVar.Object__c == ('' + sObjectTypeVar)) {
                    handlers.add(testHandlerVar);
                }
            }
        } else {
            String sObjTypeStr = '' + sObjectTypeVar;
            if (HANDLERS_BY_OBJECT.containsKey(sObjTypeStr)) {
                handlers = HANDLERS_BY_OBJECT.get(sObjTypeStr);
            } else {
                handlers = [
                    SELECT Id, Object__c, Class__c
                    FROM Trigger_Handler__mdt
                    WHERE Object__c = :sObjTypeStr
                    AND Active__c = TRUE
                    ORDER BY Load_Order__c ASC NULLS LAST
                ];

                HANDLERS_BY_OBJECT.put(sObjTypeStr, handlers);
            }
        }

        return handlers;
    }

    global static void handle(List<Trigger_Handler__mdt> handlers, TriggerContext triggerContextVar) {
        if (handlers == null) {
            return;
        }
        for (Trigger_Handler__mdt handlerVar : handlers) {
            handle(handlerVar, triggerContextVar);
        }
    }

    global static void handle(Trigger_Handler__mdt triggerHandlerVar, TriggerContext triggerContextVar) {
        String className = triggerHandlerVar.Class__c;
        Type handlerType = Type.forName(className);

        if (handlerType != null) {
            Boolean isEnabledOnObjectLevel = getTriggerSObjectTypeEvent(triggerHandlerVar.Object__c).isEnabled(
                triggerContextVar.isBefore,
                triggerContextVar.isAfter,
                triggerContextVar.isInsert,
                triggerContextVar.isUpdate,
                triggerContextVar.isDelete,
                triggerContextVar.isUndelete
            );

            Boolean isEnabledOnHandlerLevel = getTriggerHandlerEvent(handlerType).isEnabled(
                triggerContextVar.isBefore,
                triggerContextVar.isAfter,
                triggerContextVar.isInsert,
                triggerContextVar.isUpdate,
                triggerContextVar.isDelete,
                triggerContextVar.isUndelete
            );

            Boolean isEnabled = isEnabledOnObjectLevel && isEnabledOnHandlerLevel;

            if (isEnabled != true) {
                return;
            }

            Handler handlerVar = (Handler) handlerType.newInstance();

            if (triggerContextVar.isBefore) {
                if (triggerContextVar.isInsert && handlerVar instanceof BeforeInsert) {
                    ((BeforeInsert) (handlerVar)).onBeforeInsert(triggerContextVar.newRecords);
                } else if (triggerContextVar.isUpdate && handlerVar instanceof BeforeUpdate) {
                    ((BeforeUpdate) (handlerVar)).onBeforeUpdate(triggerContextVar.newRecords, triggerContextVar.oldRecordsMap);
                } else if (triggerContextVar.isDelete && handlerVar instanceof BeforeDelete) {
                    ((BeforeDelete) (handlerVar)).onBeforeDelete(triggerContextVar.oldRecords);
                }
            } else {
                if (triggerContextVar.isInsert && handlerVar instanceof AfterInsert) {
                    ((AfterInsert) (handlerVar)).onAfterInsert(triggerContextVar.newRecords);
                } else if (triggerContextVar.isUpdate && handlerVar instanceof AfterUpdate) {
                    ((AfterUpdate) (handlerVar)).onAfterUpdate(triggerContextVar.newRecords, triggerContextVar.oldRecordsMap);
                } else if (triggerContextVar.isDelete && handlerVar instanceof AfterDelete) {
                    ((AfterDelete) (handlerVar)).onAfterDelete(triggerContextVar.oldRecords);
                } else if (triggerContextVar.isUndelete && handlerVar instanceof AfterUndelete) {
                    ((AfterUndelete) (handlerVar)).onAfterUndelete(triggerContextVar.newRecords);
                }
            }
        }
    }

    global inherited sharing virtual class Handler {
    }

    private static Map<String, TriggerEvent> TriggerEventBySObjectType = new Map<String, TriggerEvent>();
    private static Map<Type, TriggerEvent> TriggerEventByHandler = new Map<Type, TriggerEvent>();

    global static TriggerEvent getTriggerSObjectTypeEvent(SObjectType sObjectTypeVar) {
        return getTriggerSObjectTypeEvent('' + sObjectTypeVar);
    }

    global static TriggerEvent getTriggerSObjectTypeEvent(String sObjectTypeVar) {
        if (!TriggerEventBySObjectType.containsKey(sObjectTypeVar)) {
            TriggerEventBySObjectType.put(sObjectTypeVar, new TriggerEvent());
        }

        return TriggerEventBySObjectType.get(sObjectTypeVar);
    }

    global static TriggerEvent getTriggerHandlerEvent(Type domainClass) {
        if (!TriggerEventByHandler.containsKey(domainClass)) {
            TriggerEventByHandler.put(domainClass, new TriggerEvent());
        }

        return TriggerEventByHandler.get(domainClass);
    }

    @TestVisible
    private static Integer stubBeforeInsertCount;
    @TestVisible
    private static Integer stubBeforeUpdateCount;
    @TestVisible
    private static Integer stubAfterInsertCount;
    @TestVisible
    private static Integer stubAfterUpdateCount;
    @TestVisible
    private static Integer stubBeforeDeleteCount;
    @TestVisible
    private static Integer stubAfterDeleteCount;
    @TestVisible
    private static Integer stubAfterUndeleteCount;

    @TestVisible
    private static void resetInternalStateForTests() {
        testHandlers.clear();
        HANDLERS_BY_OBJECT.clear();
        TriggerEventBySObjectType.clear();
        TriggerEventByHandler.clear();
        testTriggerContextOverride = null;
        stubBeforeInsertCount = null;
        stubBeforeUpdateCount = null;
        stubAfterInsertCount = null;
        stubAfterUpdateCount = null;
        stubBeforeDeleteCount = null;
        stubAfterDeleteCount = null;
        stubAfterUndeleteCount = null;
    }

    global inherited sharing class TriggerEvent {
        global boolean BeforeInsertEnabled { get; private set; }
        global boolean BeforeUpdateEnabled { get; private set; }
        global boolean BeforeDeleteEnabled { get; private set; }

        global boolean AfterInsertEnabled { get; private set; }
        global boolean AfterUpdateEnabled { get; private set; }
        global boolean AfterDeleteEnabled { get; private set; }
        global boolean AfterUndeleteEnabled { get; private set; }

        global TriggerEvent() {
            this.enableAll();
        }

        global TriggerEvent enableBeforeInsert() {
            BeforeInsertEnabled = true;
            return this;
        }
        global TriggerEvent enableBeforeUpdate() {
            BeforeUpdateEnabled = true;
            return this;
        }
        global TriggerEvent enableBeforeDelete() {
            BeforeDeleteEnabled = true;
            return this;
        }

        global TriggerEvent disableBeforeInsert() {
            BeforeInsertEnabled = false;
            return this;
        }
        global TriggerEvent disableBeforeUpdate() {
            BeforeUpdateEnabled = false;
            return this;
        }
        global TriggerEvent disableBeforeDelete() {
            BeforeDeleteEnabled = false;
            return this;
        }

        global TriggerEvent enableAfterInsert() {
            AfterInsertEnabled = true;
            return this;
        }
        global TriggerEvent enableAfterUpdate() {
            AfterUpdateEnabled = true;
            return this;
        }
        global TriggerEvent enableAfterDelete() {
            AfterDeleteEnabled = true;
            return this;
        }
        global TriggerEvent enableAfterUndelete() {
            AfterUndeleteEnabled = true;
            return this;
        }

        global TriggerEvent disableAfterInsert() {
            AfterInsertEnabled = false;
            return this;
        }
        global TriggerEvent disableAfterUpdate() {
            AfterUpdateEnabled = false;
            return this;
        }
        global TriggerEvent disableAfterDelete() {
            AfterDeleteEnabled = false;
            return this;
        }
        global TriggerEvent disableAfterUndelete() {
            AfterUndeleteEnabled = false;
            return this;
        }

        global TriggerEvent enableAll() {
            return this.enableAllBefore().enableAllAfter();
        }

        global TriggerEvent disableAll() {
            return this.disableAllBefore().disableAllAfter();
        }

        global TriggerEvent enableAllBefore() {
            return this.enableBeforeInsert().enableBeforeUpdate().enableBeforeDelete();
        }

        global TriggerEvent disableAllBefore() {
            return this.disableBeforeInsert().disableBeforeUpdate().disableBeforeDelete();
        }

        global TriggerEvent enableAllAfter() {
            return this.enableAfterInsert().enableAfterUpdate().enableAfterDelete().enableAfterUndelete();
        }

        global TriggerEvent disableAllAfter() {
            return this.disableAfterInsert().disableAfterUpdate().disableAfterDelete().disableAfterUndelete();
        }

        global boolean isEnabled(Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete) {
            if (isBefore) {
                if (isInsert) {
                    return BeforeInsertEnabled;
                } else if (isUpdate) {
                    return BeforeUpdateEnabled;
                } else if (isDelete) {
                    return BeforeDeleteEnabled;
                }
            } else if (isAfter) {
                if (isInsert) {
                    return AfterInsertEnabled;
                } else if (isUpdate) {
                    return AfterUpdateEnabled;
                } else if (isDelete) {
                    return AfterDeleteEnabled;
                } else if (isUndelete) {
                    return AfterUndeleteEnabled;
                }
            }
            return true;
        }
    }

    public class TestStubBeforeInsert extends Handler implements BeforeInsert {
        public void onBeforeInsert(List<SObject> records) {
            Integer c = MDTM.stubBeforeInsertCount;
            MDTM.stubBeforeInsertCount = (c == null ? 0 : c) + records.size();
        }
    }

    public class TestStubBeforeUpdate extends Handler implements BeforeUpdate {
        public void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecordsMap) {
            Integer c = MDTM.stubBeforeUpdateCount;
            MDTM.stubBeforeUpdateCount = (c == null ? 0 : c) + records.size();
        }
    }

    public class TestStubAfterInsert extends Handler implements AfterInsert {
        public void onAfterInsert(List<SObject> records) {
            Integer c = MDTM.stubAfterInsertCount;
            MDTM.stubAfterInsertCount = (c == null ? 0 : c) + records.size();
        }
    }

    public class TestStubAfterUpdate extends Handler implements AfterUpdate {
        public void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecordsMap) {
            Integer c = MDTM.stubAfterUpdateCount;
            MDTM.stubAfterUpdateCount = (c == null ? 0 : c) + records.size();
        }
    }

    public class TestStubBeforeDelete extends Handler implements BeforeDelete {
        public void onBeforeDelete(List<SObject> records) {
            Integer c = MDTM.stubBeforeDeleteCount;
            MDTM.stubBeforeDeleteCount = (c == null ? 0 : c) + records.size();
        }
    }

    public class TestStubAfterDelete extends Handler implements AfterDelete {
        public void onAfterDelete(List<SObject> records) {
            Integer c = MDTM.stubAfterDeleteCount;
            MDTM.stubAfterDeleteCount = (c == null ? 0 : c) + records.size();
        }
    }

    public class TestStubAfterUndelete extends Handler implements AfterUndelete {
        public void onAfterUndelete(List<SObject> records) {
            Integer c = MDTM.stubAfterUndeleteCount;
            MDTM.stubAfterUndeleteCount = (c == null ? 0 : c) + records.size();
        }
    }
}

