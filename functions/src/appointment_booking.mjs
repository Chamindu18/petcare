import {FieldValue} from 'firebase-admin/firestore';

export class BookingError extends Error {
  constructor(code, message) { super(message); this.code = code; }
}
const fail = (code, message) => { throw new BookingError(code, message); };
function id(value) {
  if (typeof value !== 'string' || !/^[^/]{1,128}$/.test(value)) fail('invalid-argument', 'Invalid appointment reference.');
  return value;
}
export function instant(value) {
  if (value && typeof value.toDate === 'function') return value.toDate();
  // Existing Flutter ISO strings without an offset represent hospital local time.
  if (typeof value !== 'string' || value.length > 40 || !/^\d{4}-\d{2}-\d{2}T/.test(value)) fail('invalid-argument', 'Invalid appointment time.');
  const date = new Date(/(Z|[+-]\d{2}:\d{2})$/i.test(value) ? value : `${value}+05:30`);
  if (!Number.isFinite(date.getTime())) fail('invalid-argument', 'Invalid appointment time.');
  return date;
}
function duration(value) {
  if (!Number.isInteger(value) || value <= 0 || value > 1440) fail('failed-precondition', 'Service duration is unavailable.');
  return value;
}
export function schedule(data) {
  return Object.fromEntries(['vetId', 'hospitalId', 'serviceId', 'dateTime', 'status', 'durationMinutes']
    .filter(key => data[key] !== undefined).map(key => [key, data[key]]));
}

async function verifiedVeterinarianRecipient(tx, db, vetId, hospitalId, directory) {
  const userId = directory?.userId;
  if (typeof userId !== 'string' || !/^[^/]{1,128}$/.test(userId)) return null;
  const account = (await tx.get(db.collection('users').doc(userId))).data();
  return account?.role === 'veterinarian' && account.hospitalId === hospitalId &&
    (account.vetId ?? userId) === vetId ? userId : null;
}

/** Trusted scheduling boundary. All reads, including authorization and duration,
 * precede writes. A shared veterinarian mutex serializes even an empty query.
 * Canonical appointments include legacy records missing availability projections.
 */
export async function reserveAppointment(db, uid, input) {
  if (!uid) fail('unauthenticated', 'Sign in to manage appointments.');
  if (!input || !['create', 'update', 'reassign'].includes(input.action)) fail('invalid-argument', 'Invalid scheduling action.');
  const {action} = input;
  const appointmentId = id(input.appointmentId);
  const ref = db.collection('appointments').doc(appointmentId);
  return db.runTransaction(async tx => {
    const user = (await tx.get(db.collection('users').doc(uid))).data();
    const existing = (await tx.get(ref)).data();
    if (action === 'create' && existing) fail('already-exists', 'This booking request has already been processed.');
    if (action !== 'create' && !existing) fail('not-found', 'Appointment was not found.');
    const hospitalId = id(action === 'create' ? input.hospitalId : existing.hospitalId);
    if (hospitalId === 'unassigned') fail('failed-precondition', 'A hospital assignment is required.');
    if (input.hospitalId !== undefined && input.hospitalId !== hospitalId) fail('permission-denied', 'Hospital assignment does not match.');
    if ((await tx.get(db.collection('hospitals').doc(hospitalId))).data()?.active !== true) {
      fail('failed-precondition', 'Select an active hospital.');
    }
    if (action === 'reassign') {
      const staff = (await tx.get(db.collection('hospital_staff').doc(uid))).data();
      if (user?.role !== 'veterinary_staff' || staff?.userId !== uid ||
          staff?.active !== true || staff?.hospitalId !== hospitalId) fail('permission-denied', 'An active hospital staff assignment is required.');
    } else if (user?.role !== 'owner' || (existing && existing.ownerId !== uid)) {
      fail('permission-denied', 'Only the appointment owner may book or reschedule.');
    }
    if (existing && (!['pending', 'confirmed'].includes(existing.status) || existing.queueId != null ||
        (action === 'update' && existing.status !== 'pending'))) fail('failed-precondition', 'This appointment cannot be rescheduled.');
    const vetId = id(input.vetId);
    const serviceId = id(action === 'reassign' ? existing.serviceId : input.serviceId);
    const petId = id(action === 'create' ? input.petId : existing.petId);
    if (action === 'create' && (await tx.get(db.collection('pets').doc(petId))).data()?.ownerId !== uid) fail('permission-denied', 'The pet does not belong to this owner.');
    const vet = (await tx.get(db.collection('veterinarians').doc(vetId))).data();
    if (vet?.active !== true || vet.hospitalId !== hospitalId ||
        (vet.vetId !== undefined && vet.vetId !== vetId)) fail('failed-precondition', 'Select an active veterinarian at this hospital.');
    if (action === 'reassign' && existing.vetId === vetId) fail('failed-precondition', 'This veterinarian is already assigned.');
    const veterinarianRecipient = await verifiedVeterinarianRecipient(tx, db, vetId, hospitalId, vet);
    let previousVeterinarianRecipient = null;
    if (action === 'reassign') {
      const previousVetId = id(existing.vetId);
      const previousDirectory = (await tx.get(db.collection('veterinarians').doc(previousVetId))).data();
      if (previousDirectory?.active === true && previousDirectory.hospitalId === hospitalId &&
          (previousDirectory.vetId === undefined || previousDirectory.vetId === previousVetId)) {
        previousVeterinarianRecipient = await verifiedVeterinarianRecipient(
          tx, db, previousVetId, hospitalId, previousDirectory);
      }
    }
    const service = (await tx.get(db.collection('services').doc(serviceId))).data();
    if (service?.hospitalId !== hospitalId) fail('failed-precondition', 'Select a service at this hospital.');
    const minutes = duration(existing && existing.serviceId === serviceId && existing.durationMinutes !== undefined
      ? existing.durationMinutes : service.duration);
    const start = instant(action === 'reassign' ? existing.dateTime : input.dateTime);
    const end = start.getTime() + minutes * 60000;
    const reason = action === 'reassign' ? existing.reason : input.reason;
    if (typeof reason !== 'string' || reason.length > 2000) fail('invalid-argument', 'Reason must be at most 2000 characters.');
    const lockIds = [...new Set([vetId, ...(existing ? [id(existing.vetId)] : [])])].sort();
    const locks = lockIds.map(key => db.collection('appointment_booking_locks').doc(key));
    await tx.getAll(...locks);
    const occupied = await tx.get(db.collection('appointments')
      .where('hospitalId', '==', hospitalId).where('vetId', '==', vetId));
    for (const document of occupied.docs) {
      const other = document.data();
      if (document.id === appointmentId || ['cancelled', 'rejected'].includes(other.status)) continue;
      const otherStart = instant(other.dateTime).getTime();
      if (otherStart >= end) continue;
      const otherMinutes = duration(other.durationMinutes ??
        (await tx.get(db.collection('services').doc(id(other.serviceId)))).data()?.duration);
      if (otherStart + otherMinutes * 60000 > start.getTime()) fail('already-exists', 'This time is no longer available. Select another slot.');
    }
    // Only the trusted scheduler can enumerate provisioned hospital staff.
    // Resolve recipients before the first write in this transaction.
    const staffRecipients = [];
    if (action === 'create') {
      const assignments = await tx.get(db.collection('hospital_staff').where('hospitalId', '==', hospitalId));
      for (const assignment of assignments.docs) {
        const staff = assignment.data();
        if (staff.active !== true || staff.userId !== assignment.id) continue;
        const account = (await tx.get(db.collection('users').doc(assignment.id))).data();
        if (account?.role === 'veterinary_staff') staffRecipients.push(assignment.id);
      }
    }
    const data = action === 'create' ? {
      appointmentId, ownerId: uid, petId, hospitalId, serviceId, vetId,
      dateTime: start.toISOString(), reason, status: 'pending', queueId: null,
      createdAt: new Date().toISOString(), durationMinutes: minutes,
    } : {...existing, appointmentId, vetId, serviceId, dateTime: start.toISOString(), reason, durationMinutes: minutes};
    // No writes occur on validation/conflict failures. Firestore atomically
    // commits the appointment, projection and mutex revisions, or none of them.
    tx.set(ref, {...data, updatedAt: FieldValue.serverTimestamp()});
    tx.set(db.collection('appointment_schedule').doc(appointmentId), schedule(data));
    for (const recipientUserId of staffRecipients) {
      tx.create(db.collection('notifications').doc(`appointment_requested_${appointmentId}_${recipientUserId}`), {
        recipientUserId, type: 'appointment_requested',
        message: 'A new appointment request needs review.', read: false,
        targetType: 'appointment', targetId: appointmentId,
        appointmentTime: data.dateTime, createdAt: FieldValue.serverTimestamp(),
      });
    }
    if (veterinarianRecipient) {
      const type = action === 'create' ? 'appointment_assigned' :
        action === 'reassign' ? 'appointment_reassigned' : null;
      if (type) {
        tx.set(db.collection('notifications').doc(`${type}_${appointmentId}_${veterinarianRecipient}`), {
          recipientUserId: veterinarianRecipient, type,
          message: action === 'create' ? 'A new appointment was assigned to you.' :
            'An appointment was reassigned to you.',
          read: false, targetType: 'appointment', targetId: appointmentId,
          appointmentTime: data.dateTime, createdAt: FieldValue.serverTimestamp(),
        });
      }
    }
    if (action === 'reassign' && previousVeterinarianRecipient) {
      tx.set(db.collection('notifications').doc(
        `appointment_unassigned_${appointmentId}_${previousVeterinarianRecipient}`), {
        recipientUserId: previousVeterinarianRecipient,
        type: 'appointment_unassigned',
        message: 'An appointment was removed from your schedule.',
        read: false, targetType: 'none', targetId: appointmentId,
        appointmentTime: data.dateTime, createdAt: FieldValue.serverTimestamp(),
      });
    }
    for (const lock of locks) tx.set(lock, {revision: FieldValue.increment(1)});
    return {...data, createdAt: instant(data.createdAt).toISOString()};
  }, {maxAttempts: 10});
}
