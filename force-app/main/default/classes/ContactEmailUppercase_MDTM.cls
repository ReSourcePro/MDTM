public with sharing class ContactEmailUppercase_MDTM extends MDTM.Handler implements MDTM.BeforeInsert, MDTM.BeforeUpdate {
    public void onBeforeInsert(List<SObject> records) {
        upperCaseEmail((List<Contact>) records);
    }

    public void onBeforeUpdate(List<SObject> records, Map<Id, SObject> existingRecordsMap) {
        upperCaseEmail((List<Contact>) records);
    }

    private void upperCaseEmail(List<Contact> contacts) {
        for (Contact c : contacts) {
            if (c.Email != null) {
                c.Email = c.Email.toUpperCase();
            }
        }
    }
}
