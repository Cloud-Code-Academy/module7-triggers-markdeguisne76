trigger OpportunityTrigger on Opportunity (before update, before delete) {

    // Before UPDATE
    if (Trigger.isBefore && Trigger.isUpdate) {

        Set<Id> accountIdsToQuery = new Set<Id>();
        for (Opportunity opp : Trigger.new) {
            if (opp.AccountId != null) {
                accountIdsToQuery.add(opp.AccountId);
            }
        }

        // Query CEO contacts for related accounts
        Map<Id, Contact> ceoContactByAccount = new Map<Id, Contact>();
        if (!accountIdsToQuery.isEmpty()) {
            for (Contact con : [
                SELECT Id, AccountId
                FROM Contact
                WHERE Title = 'CEO' AND AccountId IN :accountIdsToQuery
            ]) {
                // Only store the first CEO found per account
                if (!ceoContactByAccount.containsKey(con.AccountId)) {
                    ceoContactByAccount.put(con.AccountId, con);
                }
            }
        }

        for (Opportunity opp : Trigger.new) {
            // Amount validation
            if (opp.Amount < 5000) {
                opp.Amount.addError('Opportunity amount must be greater than 5000');
            }

            // Set Primary Contact if a CEO exists for the Account
            if (opp.AccountId != null && ceoContactByAccount.containsKey(opp.AccountId)) {
                opp.Primary_Contact__c = ceoContactByAccount.get(opp.AccountId).Id;
            }
        }
    }

    // Before DELETE
    if (Trigger.isBefore && Trigger.isDelete) {
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : Trigger.old) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }

        Map<Id, Account> accountMap = new Map<Id, Account>(
            [SELECT Id, Industry FROM Account WHERE Id IN :accountIds]
        );

        for (Opportunity opp : Trigger.old) {
            Account relatedAccount = accountMap.get(opp.AccountId);

            Boolean isBanking = relatedAccount != null && relatedAccount.Industry == 'Banking';
            Boolean isClosedWon = opp.StageName == 'Closed Won';

            if (isBanking && isClosedWon) {
                opp.addError('Cannot delete closed opportunity for a banking account that is won');
            }
        }
    }
}

