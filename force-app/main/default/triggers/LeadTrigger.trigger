trigger LeadTrigger on Lead (after update) {
    //adding
    if (Trigger.isAfter && Trigger.isUpdate) {
        //test
        LeadHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
    //sample
    //removed
    //for another testing purpose
}
