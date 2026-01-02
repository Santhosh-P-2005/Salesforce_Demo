trigger LeadTrigger on Lead (after update) {
    //adding
    if (Trigger.isAfter && Trigger.isUpdate) {
        //test
        LeadHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
    //sample
    //removed
    //for another testing purpose

    // add this line of code for the changes error check
}
