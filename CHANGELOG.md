# Changelog

## 1.1.0 (2026-03-27)

### New Features

- **Secure WiFi device sync** — Pair devices with a QR code and biometric approval.
  Auto-syncs when both devices are on the same WiFi network. All traffic is
  AES-256-GCM encrypted with a unique 256-bit shared secret per device pair.
  Data never leaves your local network.

- **BCC group email** — Compose an email in-app, select recipients from your flock
  (BCC so addresses stay private), and open it in your email app. The message is
  logged as a care contact with timestamp.

- **Import from contacts** — Add people to your flock directly from the native OS
  contact picker. Name and phone number are pre-filled.

- **Filter prayers by person** — Scroll the filter chips in the Pray tab to see
  people from your flock who have linked prayers. Tap a name to show only their
  prayers.

- **Email field on flock members** — Store an email address for each person in your
  flock, used for group email.

### Improvements

- **Keyboard handling** — Bottom sheet forms now properly resize when the keyboard
  opens. Tap the header or drag the form to dismiss the keyboard without closing
  the modal. Scroll-to-dismiss on drag is enabled.

- **Privacy policy updated** — Now describes local WiFi sync, AES-256-GCM encryption,
  and biometric lock. Effective date: March 27, 2026.

### Migration Notes

- Fully backward-compatible with v1.0.0 data. All new model fields have safe
  defaults. Sync uses additive-only merging — existing data is never deleted or
  overwritten. Two new SharedPreferences keys (`ps-device-id`,
  `ps-paired-devices`) are introduced without touching existing keys.

---

## 1.0.0 (2026-03-12)

Initial release.

- Prayer tracking with urgency levels, categories, and recurrence
- Private journaling with scripture and reflection fields
- Flock management with contact frequency and care tags
- Pastoral care logging (calls, visits, emails, etc.)
- Share text from any app into a prayer, journal entry, or flock contact
- Link prayers to people in your flock
- Optional biometric lock (fingerprint / Face ID)
- Backup and restore via JSON file
- Daily reminders for prayer, journaling, and pastoral care
- Fully offline — no account or internet required
- Dark theme with gold accents
- Free and open source
