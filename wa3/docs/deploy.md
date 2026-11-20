# Connect Wasilha to your Firebase project · ربط وصلها بمشروع Firebase

The **WA3 deploy** GitHub workflow sets everything up and deploys it, and you can re-run it at any time. Your part is three one-time steps.

## 1. Enable the Blaze plan · فعّل خطة Blaze
Firebase Console → your project → ⚙ **Usage and billing** → **Modify plan** → **Blaze**.
Cloud Functions, Secret Manager and scheduled jobs need it, and so do SMS codes.

فايربيس ← مشروعك ← ⚙ الاستخدام والفوترة ← تعديل الخطة ← Blaze.

## 2. Create a deploy key · أنشئ مفتاح النشر
1. Open <https://console.cloud.google.com/iam-admin/serviceaccounts> and select the same project.
2. **Create service account**, named `wa3-deploy`.
3. Give it the role **Owner**, then **Done**.
4. Open the account → **Keys** → **Add key** → **Create new key** → **JSON**. A file downloads.
5. **Keep this file secret.** Don't send it in chat and don't commit it.

افتح الرابط أعلاه ← اختر المشروع ← «إنشاء حساب خدمة» باسم `wa3-deploy` ← الدور **Owner** ← ثم من «المفاتيح» أنشئ مفتاح **JSON**. سيُحمَّل ملف: **لا ترسله لأحد**.

## 3. Add it to GitHub · أضفه إلى GitHub
In the repository, go to **Settings** → **Secrets and variables** → **Actions**:
- **Secrets** tab → **New repository secret**:
  - name `FIREBASE_SERVICE_ACCOUNT`
  - value: paste the whole JSON file
- **Variables** tab → **New repository variable**:
  - name `WA3_PROJECT_ID`
  - value: your project id. It's shown under the project name in Firebase → ⚙ Project settings, for example `wa-3-1a2b3`.

## 4. Run it · شغّله
**Actions** → **WA3 deploy** → **Run workflow**. Optionally fill in:
- **staff_email:** your email. You'll receive a "set your password" email for the operations console.
- **alert_email:** the address that receives monitoring alerts.
- **test_phones:** fictional numbers for testing without SMS, for example `{"+249900000001":"123456"}`.

When it finishes, the run summary shows:
- **Operations console:** `https://<project-id>.web.app`. Sign in with your email, then set up an authenticator app such as Google Authenticator.
- **APKs:** the `wasilha-apps-<project-id>` artifact contains `wasilha-rider.apk` and `wasilha-driver.apk`, connected to your project.

## What the workflow does
1. Checks that billing is enabled, then enables the required Google APIs.
2. Sets up the database: Firestore in `europe-west1`, with point-in-time recovery and daily backups kept for 14 days.
3. Sets up storage: the Storage bucket for driver documents.
4. Sets up sign-in:
   - Identity Platform, phone sign-in for riders and drivers, and email + TOTP for staff.
   - SMS limited to Sudan (+249).
5. Sets up the keys:
   - Maps keys. The server key goes to Secret Manager; the Android key is restricted to the Maps SDK.
   - App Check for the console (reCAPTCHA Enterprise).
6. Registers the three apps, then deploys the rules, indexes, functions and the console.
7. Seeds the Khartoum zone and pricing. Prices you've already edited are kept.
8. Creates the staff account you entered, plus the log metrics and alerts.
9. Builds the rider and driver APKs.

## Recommended next · خطوات لاحقة
- **Stable signing key.** Without one, each run signs with a one-off key, so you have to uninstall before installing a newer APK. Create a key once and add four secrets:
  ```bash
  keytool -genkeypair -keystore upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
  base64 -w0 upload.jks   # → ANDROID_KEYSTORE_BASE64
  ```
  Then add `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` (= `upload`) and `ANDROID_KEY_PASSWORD`. Keep `upload.jks` safe: Google Play needs the same key for every update.
- **Prices.** Set real prices in the console under **Pricing**. The seeded ones are placeholders.
- **App Check enforcement.** Turn on `app_check_enforce` once the apps ship through Google Play / TestFlight. Sideloaded APKs can't pass Play Integrity.
- **iOS:** register the iOS apps and upload an APNs key for phone sign-in. This needs a Mac with Xcode and an Apple Developer account.
- **Rotate the deploy key** after setup, and later replace Owner with narrower roles.
