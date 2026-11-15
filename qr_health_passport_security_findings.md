# QR Health Passport security findings

This untracked working note records the codebase analysis used for the QR rules change.

## Existing architecture and unfinished work

- Flutter/Dart with Firebase Auth and Firestore Standard (native mode); the project is on the Spark plan.
- Existing feature: `lib/features/qr_health_passport/` already contains the domain entity, model, repository contract, use cases, and a Firebase repository.
- Both Firebase repository methods throw `UnimplementedError`; there are no QR presentation pages, routes, dependencies, or tests.
- Owner appointment UI is `MyAppointmentsPage` (O13). Confirmed appointments currently have no passport action.
- Veterinarian entry is `VeterinarianDashboardPage` (V01), with appointment details in `VeterinarianAppointmentDetailsPage` (V02). Its passport button is a placeholder.
- Staff entry is `StaffShellPage`; assignment is trusted through `hospital_staff/{uid}`.
- Auth roles are stored in owner-readable `users/{uid}` documents; veterinarian and staff authorization is additionally tied to trusted directory/assignment documents.

## Existing data and queries used by this feature

- `appointments/{appointmentId}`: ownerId, petId, hospitalId, serviceId, vetId, dateTime, reason, status, queueId, createdAt, updatedAt. Owner query: `ownerId == uid`; veterinarian query: `vetId == canonicalVetId && hospitalId == assignedHospital`; staff query: `hospitalId == assignedHospital`.
- `pets/{petId}`: ownerId, petId, name, species, breed, dob, gender, weight, imageUrl, notes, status. Owner query: `ownerId == uid`.
- `medical_conditions`, `vaccinations`, `treatments`, and `health_measurements` each query by `petId == selectedPetId` and use existing feature models.
- Existing health rules allow only the pet owner to read/write these source collections. They must remain unchanged.
- Existing appointment rules already enforce canonical veterinarian and staff hospital assignments.

## Spark-compatible authorization design

- QR payload format: `petcare://health-passport/<43-character base64url token>`; it contains no pet, appointment, owner, hospital, or medical data.
- Token is generated from 32 bytes using Dart `Random.secure()` (256 bits).
- Parent document: `qr_health_passports/{token}` with immutable appointment/pet/hospital/veterinarian bindings, `status`, `schemaVersion`, and server timestamp `createdAt`.
- Authorization expiry is always `createdAt + 15 minutes`, evaluated with `request.time`; no editable expiry field is authoritative.
- Only the appointment owner can create a token, and only for a currently confirmed appointment whose pet, hospital, and veterinarian bindings match trusted documents.
- Revocation is the only client update and may only change `status` from active to revoked plus a server timestamp `revokedAt`.
- Rules cannot search for a token grant while authorizing arbitrary source-collection reads. The secure Spark alternative is a bounded projection under the token. Pet projection exposes only name/species/breed/dob. Health projection documents must exactly match an existing owner-readable source document and have a strict schema. They are immutable after creation.
- Creation fails if more than 12 health records are present across the four collections. This respects the Rules document access budget for the atomic batch and avoids silently omitting records.
- The assigned veterinarian can read the bounded projection only while the token is active, unexpired, and the linked appointment remains confirmed and correctly assigned.
- Assigned hospital staff can get the parent verification document only; staff cannot read pet or medical projections.
- Adoption providers and cross-hospital users have no matching allow rule.

## Threat checks to cover in emulator tests

- Unauthenticated/list access; wrong owner create/read; forged token schema; identity replacement; client timestamp manipulation; arbitrary expiry; invalid appointment state; wrong vet; wrong hospital; staff medical access; adoption-provider access; expired/revoked/cancelled use; projection field tampering; source-document mismatch; schema pollution; oversized strings; update bypass; and session changes.

## Known platform limitation

Firestore Rules cannot atomically prove that a client-created projection includes every source record, because rules cannot execute collection queries. Each included record can be proven exact, and the owner UI copies all records returned by the existing repositories. A trusted backend would be required for a completeness guarantee; this implementation intentionally does not broaden source health reads.
