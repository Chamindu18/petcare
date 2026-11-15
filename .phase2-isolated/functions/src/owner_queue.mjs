const MAX_ID_LENGTH = 128;

export class OwnerQueueError extends Error {
  constructor(code, message) {
    super(message);
    this.name = 'OwnerQueueError';
    this.code = code;
  }
}

function fail(code, message) {
  throw new OwnerQueueError(code, message);
}

function requireId(value, label) {
  if (
    typeof value !== 'string' ||
    value.length === 0 ||
    value.length > MAX_ID_LENGTH ||
    value.includes('/')
  ) {
    fail('invalid-argument', `Invalid ${label}.`);
  }
  return value;
}

function isTimestamp(value) {
  return value != null && typeof value.toDate === 'function';
}

function queueIdOf(document) {
  const data = document.data();
  return typeof data.queueId === 'string' && data.queueId.length > 0
    ? data.queueId
    : document.id;
}

export function calculateWaitingPosition(entries, queueId) {
  const waiting = entries
    .filter(entry => entry.status === 'waiting')
    .sort((a, b) => {
      const numberDifference = a.queueNumber - b.queueNumber;
      if (numberDifference !== 0) return numberDifference;
      return String(a.queueId).localeCompare(String(b.queueId));
    });
  const index = waiting.findIndex(entry => entry.queueId === queueId);
  return index < 0 ? 0 : index + 1;
}

export async function getOwnerQueuePosition(db, uid, input) {
  if (!uid) fail('unauthenticated', 'Sign in to view your queue.');
  if (input == null || typeof input !== 'object' || Array.isArray(input)) {
    fail('invalid-argument', 'Invalid queue request.');
  }

  const queueId = requireId(input.queueId, 'queue');
  const queue = (
    await db.collection('queue_records').doc(queueId).get()
  ).data();
  if (!queue || queue.ownerId !== uid) {
    fail('not-found', 'Queue entry was not found.');
  }

  const appointmentId = requireId(queue.appointmentId, 'appointment');
  const appointment = (
    await db.collection('appointments').doc(appointmentId).get()
  ).data();
  if (
    !appointment ||
    appointment.ownerId !== uid ||
    appointment.queueId !== queueId ||
    appointment.hospitalId !== queue.hospitalId ||
    appointment.petId !== queue.petId
  ) {
    fail('not-found', 'Queue entry was not found.');
  }

  if (queue.status !== 'waiting') {
    return {position: 0, status: queue.status};
  }

  const hospitalId = requireId(queue.hospitalId, 'hospital');
  const dayKey =
    typeof queue.dayKey === 'string' && queue.dayKey.length > 0
      ? queue.dayKey
      : null;
  if (!dayKey && !isTimestamp(queue.day)) {
    fail('failed-precondition', 'Queue day is unavailable.');
  }

  let query = db
    .collection('queue_records')
    .where('hospitalId', '==', hospitalId);
  query = dayKey
    ? query.where('dayKey', '==', dayKey)
    : query.where('day', '==', queue.day);
  const snapshot = await query.get();
  const entries = snapshot.docs.map(document => ({
    ...document.data(),
    queueId: queueIdOf(document),
  }));
  const scopedEntries = entries.filter(entry => {
    if (entry.hospitalId !== hospitalId) return false;
    if (dayKey) return entry.dayKey === dayKey;
    return true;
  });

  return {
    position: calculateWaitingPosition(scopedEntries, queueId),
    status: queue.status,
  };
}
