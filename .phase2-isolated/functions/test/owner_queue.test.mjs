import test from 'node:test';
import assert from 'node:assert/strict';
import {
  OwnerQueueError,
  calculateWaitingPosition,
  getOwnerQueuePosition,
} from '../src/owner_queue.mjs';

function fakeDb({queues = {}, appointments = {}}) {
  const collections = {queue_records: queues, appointments};
  return {
    collection(name) {
      const records = collections[name] ?? {};
      return {
        doc(id) {
          return {get: async () => ({data: () => records[id]})};
        },
        where(field, operator, value) {
          return fakeQuery(records, [{field, operator, value}]);
        },
      };
    },
  };
}

function fakeQuery(records, filters) {
  return {
    where(field, operator, value) {
      return fakeQuery(records, [...filters, {field, operator, value}]);
    },
    async get() {
      const docs = Object.entries(records)
        .filter(([, data]) =>
          filters.every(({field, operator, value}) => {
            assert.equal(operator, '==');
            return data[field] === value;
          }),
        )
        .map(([id, data]) => ({id, data: () => data}));
      return {docs};
    },
  };
}

const baseQueue = {
  queueId: 'queue-2',
  appointmentId: 'appointment-1',
  hospitalId: 'hospital-1',
  ownerId: 'owner-1',
  petId: 'pet-1',
  queueNumber: 2,
  currentServing: 0,
  position: 2,
  status: 'waiting',
  dayKey: '2026-11-07',
};

const baseAppointment = {
  appointmentId: 'appointment-1',
  ownerId: 'owner-1',
  petId: 'pet-1',
  hospitalId: 'hospital-1',
  queueId: 'queue-2',
};

test('waiting position excludes non-waiting entries and orders by queue number', () => {
  const entries = [
    {queueId: 'queue-4', queueNumber: 4, status: 'waiting'},
    {queueId: 'queue-2', queueNumber: 2, status: 'waiting'},
    {queueId: 'queue-1', queueNumber: 1, status: 'completed'},
    {queueId: 'queue-3', queueNumber: 3, status: 'called'},
    {queueId: 'queue-5', queueNumber: 5, status: 'cancelled'},
  ];

  assert.equal(calculateWaitingPosition(entries, 'queue-2'), 1);
  assert.equal(calculateWaitingPosition(entries, 'queue-4'), 2);
  assert.equal(calculateWaitingPosition(entries, 'queue-3'), 0);
});

test('owner receives a server-calculated position for their own waiting queue', async () => {
  const db = fakeDb({
    queues: {
      'queue-0': {
        ...baseQueue,
        queueId: 'queue-0',
        queueNumber: 1,
        ownerId: 'owner-2',
        appointmentId: 'appointment-0',
      },
      'queue-1': {
        ...baseQueue,
        queueId: 'queue-1',
        queueNumber: 2,
        status: 'completed',
      },
      'queue-2': {...baseQueue, queueNumber: 3},
      'queue-3': {
        ...baseQueue,
        queueId: 'queue-3',
        queueNumber: 4,
        ownerId: 'owner-2',
        appointmentId: 'appointment-2',
      },
    },
    appointments: {
      'appointment-0': {
        ...baseAppointment,
        appointmentId: 'appointment-0',
        ownerId: 'owner-2',
        queueId: 'queue-0',
      },
      'appointment-1': baseAppointment,
      'appointment-2': {
        ...baseAppointment,
        appointmentId: 'appointment-2',
        ownerId: 'owner-2',
        queueId: 'queue-3',
      },
    },
  });

  const result = await getOwnerQueuePosition(db, 'owner-1', {
    queueId: 'queue-2',
  });

  assert.deepEqual(result, {position: 2, status: 'waiting'});
});

test('another owner cannot read a queue position', async () => {
  const db = fakeDb({
    queues: {'queue-2': baseQueue},
    appointments: {'appointment-1': baseAppointment},
  });

  await assert.rejects(
    getOwnerQueuePosition(db, 'owner-2', {queueId: 'queue-2'}),
    error => error instanceof OwnerQueueError && error.code === 'not-found',
  );
});

test('mismatched appointment linkage is rejected', async () => {
  const db = fakeDb({
    queues: {'queue-2': baseQueue},
    appointments: {
      'appointment-1': {...baseAppointment, queueId: 'another-queue'},
    },
  });

  await assert.rejects(
    getOwnerQueuePosition(db, 'owner-1', {queueId: 'queue-2'}),
    error => error instanceof OwnerQueueError && error.code === 'not-found',
  );
});

test('non-waiting status returns zero without a stale position', async () => {
  const db = fakeDb({
    queues: {'queue-2': {...baseQueue, status: 'called'}},
    appointments: {'appointment-1': baseAppointment},
  });

  const result = await getOwnerQueuePosition(db, 'owner-1', {
    queueId: 'queue-2',
  });

  assert.deepEqual(result, {position: 0, status: 'called'});
});

test('unauthenticated and malformed requests are rejected', async () => {
  const db = fakeDb({});

  await assert.rejects(
    getOwnerQueuePosition(db, null, {queueId: 'queue-2'}),
    error => error instanceof OwnerQueueError && error.code === 'unauthenticated',
  );
  await assert.rejects(
    getOwnerQueuePosition(db, 'owner-1', {queueId: '../queue-2'}),
    error => error instanceof OwnerQueueError && error.code === 'invalid-argument',
  );
});
