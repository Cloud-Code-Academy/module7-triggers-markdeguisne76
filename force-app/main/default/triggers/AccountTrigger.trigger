trigger AccountTrigger on Account (before insert, after insert) {
    
    // BEFORE INSERT logic (set fields on the Account)
    if (Trigger.isBefore && Trigger.isInsert) {
        for (Account acc : Trigger.new) {
            // Set Type to 'Prospect' if blank
            if (String.isBlank(acc.Type)) {
                acc.Type = 'Prospect';
            }

            // Check if shipping fields are filled in
            Boolean hasShippingAddress =
                !String.isBlank(acc.ShippingStreet) ||
                !String.isBlank(acc.ShippingCity) ||
                !String.isBlank(acc.ShippingState) ||
                !String.isBlank(acc.ShippingPostalCode) ||
                !String.isBlank(acc.ShippingCountry);

            // Copy shipping to billing
            if (hasShippingAddress) {
                acc.BillingStreet     = acc.ShippingStreet;
                acc.BillingCity       = acc.ShippingCity;
                acc.BillingState      = acc.ShippingState;
                acc.BillingPostalCode = acc.ShippingPostalCode;
                acc.BillingCountry    = acc.ShippingCountry;
            }

            // Set Rating to 'Hot' if Phone, Website, and Fax are all populated
            Boolean hasFields = 
                !String.isBlank(acc.Phone) &&
                !String.isBlank(acc.Website) &&
                !String.isBlank(acc.Fax);

            if (hasFields) {
                acc.Rating = 'Hot';
            }
        }
    }

    // AFTER INSERT logic (create related Contact)
    if (Trigger.isAfter && Trigger.isInsert) {
        List<Contact> contactsToInsert = new List<Contact>();

        for (Account acc : Trigger.new) {
            contactsToInsert.add(new Contact(
                LastName = 'DefaultContact',
                Email = 'default@email.com',
                AccountId = acc.Id
            ));
        }

        if (!contactsToInsert.isEmpty()) {
            Database.insert (contactsToInsert);
        }
    }
}
