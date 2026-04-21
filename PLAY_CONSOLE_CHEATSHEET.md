# Play Console — Answers to Paste

Answers for each section of Play Console **App content** + **Store listing**
for TinySaver Kids. Verify everything yourself before submitting.

---

## Target audience and content

**Target age groups:** Ages 5 – 8, Ages 9 – 12
*(This flips TinySaver Kids into the "Designed for Families" program —
required because kids are the primary audience.)*

**Store listing preference:** "Show to everyone"
*(Parents often download it for their kids.)*

**App interests children:**
- **Is this app designed for children?** Yes
- The app will be listed as primarily child-directed.

---

## Data safety

### 1. Does your app collect or share any of the required user data types?
**Yes** (we collect and store email + account data).

### 2. Is all the user data collected by your app encrypted in transit?
**Yes** (all Firestore / Firebase Auth traffic uses HTTPS/TLS).

### 3. Do you provide a way for users to request that their data is deleted?
**Yes** — the app's BUDDY tab → Sign Out → Delete Account (or email us).

### Data types collected (fill out the table)

| Data type | Collected | Shared | Processed ephemerally | Required or Optional | Purpose |
|---|---|---|---|---|---|
| **Personal info → Email address** | ✓ | ✗ | ✗ | Required | Account management |
| **Personal info → Name** | ✓ | ✗ | ✗ | Required | Account management, App functionality |
| **Financial info → Purchase history** | ✓ | ✗ | ✗ | Optional | App functionality |
| **App activity → App interactions** | ✓ | ✗ | ✗ | Optional | Analytics, App functionality |
| **App info and performance → Crash logs** | ✓ | ✗ | ✗ | Optional | App functionality |
| **App info and performance → Diagnostics** | ✓ | ✗ | ✗ | Optional | App functionality |
| **Device or other IDs → Device or other IDs** | ✓ | ✓ | ✗ | Optional | Advertising or marketing (non-personalized) |

*Do NOT check* location, contacts, calendar, photos, videos, audio, messages,
files, health/fitness, or any other category.

---

## Ads

**Does your app contain ads?** **Yes**
*(Parent-facing banner ads only, via Google AdMob, non-personalized, G-rated.)*

---

## Content rating (IARC questionnaire)

Answer **"No"** to all violence / profanity / sexual / gambling / drug /
fear / controlled-substance questions.

Expected ratings:
- **IARC: Everyone / PEGI 3 / ESRB Everyone**
- **Google Play: Everyone**

---

## Privacy Policy URL

Host `PRIVACY_POLICY.md` as an HTML page and paste the public URL here.
Free options:
- **GitHub Pages** (commit the file, enable Pages, URL looks like `https://bicolallan.github.io/tinysaver-privacy/`)
- **Firebase Hosting** (`firebase init hosting` in this project, drop the MD as `public/index.html` converted via any MD→HTML tool)
- **Notion / Google Sites** (paste the markdown, publish, copy URL)

---

## App access

**All app functionality is available without restrictions:** No — login required.

Provide test credentials:
- **Email:** bicolallan@gmail.com (or create a fresh one just for review)
- **Password:** [whatever you set]
- **Notes:** "Default parent PIN after signup is 1234. The BUDDY tab
  requires that PIN to access parent settings."

---

## Government apps / Financial features / Health apps
**Answer: No** to all.

---

## Families Policy self-certification

You must agree to the Families Policy requirements:
- ✅ Age-appropriate content only
- ✅ No personalized ads to children
- ✅ Non-certified ad SDKs not used (AdMob only — certified ✓)
- ✅ COPPA flags set on all ad requests
- ✅ No behavioural profiling
- ✅ Privacy policy link provided

---

## Store listing content

### App name
`TinySaver Kids`

### Short description (80 chars max)
`Fun savings habit app for kids. Earn coins, collect mascots, reach goals!`

### Full description (4000 chars max)

```
TinySaver Kids turns saving money into a fun daily adventure for children.

⭐ HOW IT WORKS
Kids complete daily tasks (making the bed, brushing teeth, helping out)
and earn virtual coins from their parents. Coins go toward real-world
reward goals the family sets together — a toy, a book, a trip to the park.

⭐ FEATURES
• Daily task list with coin rewards
• 10 cute mascots (pig, bunny, fox, cat, panda, and more)
• Visual growth system — your mascot levels up as savings grow
• Reward goals with segmented progress bars
• Daily missions and streak tracking
• Parent dashboard behind a 4-digit PIN
• Multi-currency support (PHP, USD, EUR, and more)
• Export savings reports as PDF (Pro)

⭐ TINYSAVER PRO (one-time upgrade)
• Remove all ads
• Unlock premium mascots and accessories
• Parent dashboard with insights and trends
• Multiple reward goals at once
• Multi-child support
• PDF export of savings history

⭐ KID-SAFE BY DESIGN
• No behavioural advertising — ever
• No chat, no social features, no external links
• All ads are G-rated and shown only on parent screens
• COPPA-compliant for children under 13
• Data stays private (Firebase backend)

TinySaver Kids is built by a parent, for parents. Start building lifelong
savings habits in a way your child will actually enjoy.
```

### Tags / Category
- **Category:** Education  *(or Family — up to you)*
- **Tags:** Education, Family, Parenting, Kids, Finance

---

## Common rejection reasons (avoid these)

1. ❌ Privacy policy not accessible (URL returns 404) → test the link first.
2. ❌ Declared "No ads" but app contains ads → we declared Yes.
3. ❌ Missing Families Policy compliance → we certify above.
4. ❌ Using a non-certified ad SDK for kids → only AdMob is used. ✓
5. ❌ Asking for permissions we don't need → we don't request any dangerous permissions.
6. ❌ App Access reviewer can't log in → provide working test creds.
7. ❌ In-app purchases but no content rating → fill out IARC questionnaire.

---

## Internal Testing checklist before first rollout

- [ ] Privacy Policy URL live and publicly accessible
- [ ] AAB uploaded signed with upload keystore (`android/key.properties`)
- [ ] Test email added to Internal Testing testers list
- [ ] Merchant / Payments profile completed (for IAP)
- [ ] `com.tinysaverkids.pro` product created and activated
- [ ] Test one purchase end-to-end (use Play license-test account)
- [ ] Data safety form submitted
- [ ] Target audience set to Kids
- [ ] Content rating submitted
- [ ] App access test credentials provided

When all ten items are ✅, promote to Production.
