# Pet photo retention (Spark MVP)

Pet photos are uploaded directly from Flutter through Cloudinary's unsigned
`petcare_unsigned` preset. The pet document stores only the returned `secure_url`
in `imageUrl`; the response's `public_id` is not persisted. The client-supplied
`folder` value (`pet-images/<Firebase UID>/<pet ID>`) organizes uploads but does
not prove ownership to Cloudinary. The preset name and cloud name are public
configuration, not credentials. Anyone who knows them may be able to upload
subject to the preset's Cloudinary-side restrictions and account limits; those
settings are not represented in this repository and must be reviewed in the
Cloudinary console. In particular, restrict allowed formats, size, folder or
asset behavior where the preset supports it, and monitor abuse.

Removing or replacing a photo changes the Firestore reference after a successful
write. Soft deletion clears the pet's `imageUrl` while retaining the pet document
as an ownership anchor. Neither action deletes the Cloudinary asset. Anyone who
already has its URL may still access it. Failed Firestore writes retain the
previous reference; an uploaded replacement may be orphaned because hosted
deletion is unavailable. A timed-out upload may also have succeeded remotely
without returning its URL to the app. There is no automatic cleanup or verified
retention period for these assets.

Authenticated deletion requires trusted server-side infrastructure with a
Cloudinary API secret, plus Firebase authentication and a server-side ownership
check against the pet and a stored, verified asset identifier. The server must
derive the target from trusted data rather than accept an arbitrary public ID or
URL from the client, and it must handle retries and partial failure. The current
Functions codebase contains appointment functions only; no Cloudinary credential
or deletion path exists. Firebase does not allow new Cloud Functions deployments
on Spark. Cloudinary also offers a short-lived delete token for a newly uploaded
asset, but the app does not request or store one, and it cannot cover later
profile edits or pet deletion. No new paid service or billing change is part of
this Spark MVP correction. Until secure infrastructure is available,
`deletePetImage` explicitly reports that hosted deletion is unavailable.
