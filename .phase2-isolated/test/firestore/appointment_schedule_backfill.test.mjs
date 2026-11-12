import test from 'node:test';
import assert from 'node:assert/strict';
import { scheduleForAppointment } from '../../scripts/backfill-appointment-schedule.mjs';

test('projection excludes owner, pet and clinical information and preserves timestamp representation', () => {
  for (const dateTime of ['2026-11-10T09:00:00Z', {toDate: () => new Date('2026-11-10T09:00:00Z')}]) {
    const data = {vetId: 'vet', hospitalId: 'hospital', serviceId: 'service', status: 'pending', dateTime,
      durationMinutes: 30, ownerId: 'private', petId: 'private', reason: 'private'};
    assert.deepEqual(Object.keys(scheduleForAppointment(data)).sort(), ['dateTime', 'durationMinutes', 'hospitalId', 'serviceId', 'status', 'vetId']);
    assert.equal(scheduleForAppointment(data).dateTime, dateTime);
  }
});

test('malformed source data fails rather than publishing invalid availability', () => {
  assert.throws(() => scheduleForAppointment({}), /Invalid/);
  assert.throws(() => scheduleForAppointment({vetId: 'v', hospitalId: 'h', serviceId: 's', status: 'pending', dateTime: 'bad'}), /Invalid dateTime/);
});


test('backfill preserves server-snapshotted duration', () => {
  const data = {vetId: 'vet', hospitalId: 'hospital', serviceId: 'service', status: 'pending',
    dateTime: '2026-11-10T09:00:00Z', durationMinutes: 30};
  assert.equal(scheduleForAppointment(data).durationMinutes, 30);
  assert.throws(() => scheduleForAppointment({...data, durationMinutes: 0}), /Verified durationMinutes/);
  assert.throws(() => scheduleForAppointment({...data, durationMinutes: undefined}), /Verified durationMinutes/);
});
