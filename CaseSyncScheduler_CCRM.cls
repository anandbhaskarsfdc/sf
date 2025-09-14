public class CaseSyncScheduler_CCRM implements Schedulable {
    public CaseSyncScheduler_CCRM() {

    }

    public void execute(SchedulableContext sc) {
        // Create batch instance and execute
        CaseSyncBatch_CCRM batch = new CaseSyncBatch_CCRM();
        Database.executeBatch(batch, 100); // Batch size is 100
    }

    // Convenience method for scheduling daily execution
    public static String scheduleDaily() {
        CaseSyncScheduler_CCRM scheduler = new CaseSyncScheduler_CCRM();
        // Run at 2:00 AM every day
        String cronExp = '0 0 2 * * ?';
        return System.schedule('Case Sync Daily ' + System.now(), cronExp, scheduler);
    }

    // Convenience method for scheduling hourly execution
    public static String scheduleHourly() {
        CaseSyncScheduler_CCRM scheduler = new CaseSyncScheduler_CCRM();
        // Run at the top of every hour
        String cronExp = '0 0 * * * ?';
        return System.schedule('Case Sync Hourly ' + System.now(), cronExp, scheduler);
    }

    // Convenience method for scheduling custom time execution
    public static String scheduleCustom(String cronExp) {
        CaseSyncScheduler_CCRM scheduler = new CaseSyncScheduler_CCRM();
        return System.schedule('Case Sync Custom ' + System.now(), cronExp, scheduler);
    }
}