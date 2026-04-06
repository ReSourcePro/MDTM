trigger Contact_MDTM on Contact(before insert, before update) {
    MDTM.handle();
}
