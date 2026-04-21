# TinySaver Kids — Privacy Policy

**Effective date:** April 21, 2026
**Last updated:** April 21, 2026

TinySaver Kids ("the App", "we", "us") is a savings-habit app for children operated
by the TinySaver Kids team. This policy explains what information the App
collects, how it is used, and the choices you have.

We designed this App to be **family-friendly and COPPA/GDPR-K compliant**.
All ads shown in the App are child-directed, non-personalized, and rated G.

---

## 1. Information We Collect

### 1.1 Account information (required)
When you create an account, we collect:
- **Email address** (for Firebase Authentication)
- **Password** (hashed and stored by Firebase; we never see it in plaintext)
- **Child's display name** (chosen by the parent, e.g. "Allan")
- **Pig / mascot name** (chosen by the child)

### 1.2 App usage data
The App stores per-user:
- Coin balance, reward goals, tasks you create, completion history
- Streak counts, daily missions, owned mascots and accessories
- Selected currency and coin value
- Parent PIN (stored in plain text in Firestore — this is a **local household PIN**,
  not a security credential; do not reuse a real password)

### 1.3 Purchase information
If you purchase **TinySaver Pro**:
- The purchase is processed by **Google Play Billing** (Android) or the
  **App Store** (iOS). We never see your credit-card or banking details.
- We store a flag (`is_premium: true`) and the purchase date on your account.

### 1.4 Advertising data
In the parent-facing screens only, we display banner ads via **Google AdMob**.
For kids' privacy:
- Ads are flagged as **child-directed** (COPPA)
- Requests are **non-personalized** (no behavioural tracking)
- Maximum content rating: **G (general audiences)**
- We pass `tagForChildDirectedTreatment = yes` and
  `tagForUnderAgeOfConsent = yes` on every ad request.

Google's AdMob privacy practices for child-directed traffic apply:
https://support.google.com/admob/answer/6223431

### 1.5 Crash and diagnostic data
If the App crashes, we use **Firebase Crashlytics** to log:
- Stack trace, device model, OS version, app version
- No personal data is attached to crash reports
- You can disable crash reporting in the BUDDY tab → Diagnostics

### 1.6 What we do **NOT** collect
- We do **not** collect location data
- We do **not** access contacts, photos, microphone, or camera
- We do **not** track across third-party apps or websites
- We do **not** collect biometric data

---

## 2. How We Use the Information

- To run the App and save your progress across devices
- To process one-time Pro purchases via the store
- To show non-personalized, child-safe ads on the parent dashboard
- To fix bugs and improve stability (via anonymized crash reports)
- To enforce parental PIN / family-mode gates

We do **not** sell your data. We do **not** use your data for behavioural
advertising or profiling.

---

## 3. Legal Basis (GDPR)

For users in the EEA, UK, or similar jurisdictions:
- **Contract**: we process account data to provide the service you signed up for.
- **Legitimate interest**: we show non-personalized ads and use crash reports
  to keep the App running.
- **Consent**: you, as the parent, consent on behalf of the child when
  creating the account.

---

## 4. Children's Privacy (COPPA, US)

TinySaver Kids is designed for children under 13 with **parental account
creation required**. No persistent identifier is used for ad targeting. All
ad requests are tagged child-directed. We do not knowingly allow a child to
create an account without a parent's email.

If you believe a child created an account without your permission, email us
at the address below and we will delete the account within 7 days.

---

## 5. Data Storage & Security

- Data is stored in **Google Firebase** (Cloud Firestore + Firebase Auth),
  hosted on Google Cloud with industry-standard encryption at rest and in transit.
- Firestore security rules restrict each user's data to the authenticated owner
  of that document.
- Passwords are never stored in plaintext — Firebase Auth hashes them using
  industry-standard one-way functions.

---

## 6. Sharing With Third Parties

We share information only with:
- **Google Firebase** (Auth, Firestore, Crashlytics) — processing on our behalf
- **Google AdMob** — for serving non-personalized, child-safe banner ads
- **Apple / Google** — when processing in-app purchases

We do not sell, rent, or trade your personal data.

---

## 7. Data Retention

- Account data is kept as long as your account exists.
- You can delete your account at any time from **BUDDY tab → Sign Out →
  Delete Account** (or by emailing us). Deletion removes the Firestore
  document and the Firebase Auth record; it cannot be undone.
- Crashlytics retains anonymized crash reports for up to 90 days.

---

## 8. Your Rights

Depending on your region, you may have the right to:
- Access a copy of the data we store about you
- Correct inaccurate data (the BUDDY tab lets you edit most of it directly)
- Delete your account and all associated data
- Object to or restrict certain processing
- Lodge a complaint with your local data protection authority

To exercise any of these rights, email us at the address below.

---

## 9. International Transfers

Firebase stores data in Google Cloud data centres, which may be located
outside your country (including the United States). Google is certified
under the EU-US Data Privacy Framework.

---

## 10. Changes to This Policy

If we make material changes, we will:
- Update the "Last updated" date at the top
- Show a one-time in-app notice on the next launch
- Continued use of the App after a change means you accept the updated policy

---

## 11. Contact Us

**Email:** bicolallan@gmail.com

For COPPA / privacy concerns, please include "Privacy" in the subject line
and we will respond within 7 days.

---

*TinySaver Kids is an independent app, not affiliated with Google, Apple,
or any school.*
