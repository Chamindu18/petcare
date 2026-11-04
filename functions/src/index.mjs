import {initializeApp} from 'firebase-admin/app';
import {getFirestore} from 'firebase-admin/firestore';
import {onCall, HttpsError} from 'firebase-functions/v2/https';
import {BookingError, reserveAppointment} from './appointment_booking.mjs';

initializeApp();
export const reserveAppointmentSlot = onCall({region: 'asia-south2'}, async request => {
  try {
    return await reserveAppointment(getFirestore(), request.auth?.uid, request.data);
  } catch (error) {
    if (error instanceof BookingError) throw new HttpsError(error.code, error.message);
    console.error('Appointment transaction failed', error);
    throw new HttpsError('unavailable', 'Unable to reserve this appointment. Refresh and try again.');
  }
});
