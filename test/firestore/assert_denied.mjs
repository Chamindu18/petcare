import assert from 'node:assert/strict';
import { assertFails as firebaseAssertFails } from '@firebase/rules-unit-testing';

// assertFails alone accepts expression exhaustion and malformed-field errors.
// Check the emulator's diagnostic as well as the permission-denied code.
export async function assertDenied(operation) {
  const error = await firebaseAssertFails(operation);
  assert.doesNotMatch(error.message,
    /maximum of 1000|expression.*limit|access.*limit|undefined on object|Null value|Invalid path/i);
  return error;
}

