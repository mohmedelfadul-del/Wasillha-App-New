# Operations runbook

## Monitoring and alerts (Cloud Logging → log-based metrics → alert policies)

| Signal | Source | Suggested alert |
|---|---|---|
| Function errors | Cloud Functions error logs: `severity>=ERROR` on `resource.type="cloud_run_revision"`, excluding `trip.stuck` | more than 5 in 5 min |
| Stuck trips | `jsonPayload.message="trip.stuck"` (from `sweeper`, once a minute per stuck trip) | any for 3 consecutive minutes |
| Time to assign | `jsonPayload.metric="time_to_assign_seconds"` (logged by `acceptOffer`), as a distribution metric | p50 over 180 s for 15 min |
| Requests expiring unaccepted | trips cancelled with `cancellation.reason == "no_offers"`: count in a daily BigQuery export, or a log line | daily review (beta) |
| Dispatch reach | `dispatch.fanout` log `drivers` field | 0 drivers for more than 20 % of requests in 1 h |

How to create these:
1. Console → Logging → Log-based metrics → Create. Use the filters above.
2. Monitoring → Alerting → policy on the metric, sent to the ops on-call channel.

## Weekly beta review (phase 3)

Review these each week:
- Completed trips per week (north star): `trips` with `state == completed`.
- Cancellation rate by actor and reason.
- Pickup ETA: `timestamps.driverArrived − timestamps.driverAssigned`.
- Complaints: `cases` by type.

## Backup and restore drill (phase 2: not yet performed)

1. Turn on Firestore Point-in-Time Recovery (PITR) and scheduled backups:
   `gcloud firestore backups schedules create --database='(default)' --recurrence=daily --retention=14d`.
2. Drill on staging every quarter:
   1. Restore the latest backup into a new database: `gcloud firestore databases restore …`.
   2. Point a staging function at it.
   3. Verify that the trip, ledger and audit counts match.
   4. Record how long the restore took.

## Staff access

- **Grant a role:** `node functions/scripts/seed.js --staff <uid> <role>`. The person must enroll TOTP on their first console sign-in. With `REQUIRE_STAFF_MFA=true`, every staff command checks the second factor.
- **Remove access:** clear their custom claims (`setCustomUserClaims(uid, null)`) and revoke their refresh tokens.
- **Audit:** every staff command writes an `audit` entry in the same transaction. Admins can read the audit log; nobody can edit it.
