export const current = [
 ['Borrower', 'Visit the Resource Centre', 'Ask whether the equipment you need is available.'],
 ['Officer', 'Check the printed record book', 'Look up the item’s availability in the manual log.', 'The record may not reflect the actual availability or condition.'],
 ['Borrower', 'Complete a paper application', 'Write down the purpose of the loan and the borrowing period.'],
 ['Borrower + lecturer', 'Obtain a signature', 'Take the form to a lecturer or supervisor for approval.', 'The request waits when the approver cannot be contacted.'],
 ['Borrower', 'Return with the signed form', 'Bring the approved application back to the Resource Centre.'],
 ['Officer', 'Enter the borrower’s details', 'Copy the loan information into the record book.'],
 ['Officer', 'Locate the equipment', 'Find the requested item in the storage area.'],
 ['Officer', 'Verify and hand over', 'Check the approved application and release the equipment.'],
 ['Borrower', 'Use the equipment', 'Use the item for the approved purpose and period.'],
 ['Borrower + officer', 'Return and update the book', 'Return the item; the officer records the return manually.', 'Without condition photos, existing damage can lead to disputes.']
];
export const improved = [
 ['Borrower', 'Check availability online', 'View the item’s current availability before making a trip.'],
 ['Borrower', 'Reserve the equipment', 'Submit the purpose, dates and item details through the portal.'],
 ['System', 'Notify the approver', 'Send the request directly to the lecturer or supervisor.'],
 ['Lecturer', 'Review and approve online', 'Approve remotely or return the request with a reason.'],
 ['System', 'Create a QR-linked loan record', 'Link the item, recorded condition, borrower and due date.'],
 ['Borrower', 'Visit the collection counter', 'Bring the approved booking and present its QR code.'],
 ['Officer', 'Scan and photograph', 'Verify the loan record and save a clear before-loan photo.'],
 ['Officer + system', 'Hand over and log the loan', 'Release the equipment and automatically record the transaction.'],
 ['System', 'Send return reminders', 'Notify the borrower when the loan is due or overdue.'],
 ['Borrower + officer', 'Return, inspect and update', 'Take an after-loan photo, compare the condition and update availability.']
];
export const problems = [
 ['Uncertain availability', 'An outdated record can lead to conflicting requests and unnecessary trips.', 'Students and lecturers', 'Check live availability before reserving.'],
 ['Approval delays', 'A paper form cannot move forward while the lecturer or supervisor is unavailable.', 'Borrowers and event organisers', 'Send the request digitally for remote review.'],
 ['Condition disputes', 'Without a record of existing damage, responsibility is difficult to establish.', 'Borrowers and Resource Centre staff', 'Compare clear photographs taken before and after the loan.'],
 ['Overdue equipment', 'A missed return reduces access for the next borrower and makes assets harder to track.', 'The institution and the next borrower', 'Keep due dates in the loan record and send reminders.'],
 ['Repeated administration', 'Rewriting loan details increases workload and creates opportunities for transcription errors.', 'Resource Centre staff and management', 'Reuse one loan record from reservation to return.']
];
export const members = [
 ['A', 'Muhammad Khairul Ikhwan bin Anuar', '19DIT26F1234', 'Overview & current process', 'Group leader'],
 ['B', 'Muhammad Zahin bin Zulbahry', '19DIT26F1218', 'Problems & precautions', ''],
 ['C', 'Norshahmi Daniel bin Noradzuan', '19DIT26F1044', 'Improved process', ''],
 ['D', 'Afif Amsyar bin Mohd Faizal', '19DIT26F1052', 'Process explanation & website', '']
];
