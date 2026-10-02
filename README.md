# InsureX – Digital Insurance Claim & Lifecycle Management Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Cloudinary](https://img.shields.io/badge/Cloudinary-Media%20Engine-3448C5?logo=cloudinary&logoColor=white)](https://cloudinary.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **Enterprise-Grade Digital Insurance Application**  
> A cross-platform insurance lifecycle platform designed for real-time First Notice of Loss (FNOL), high-resolution damage adjudication, officer workload dispatching, and administrative intelligence.

---

## 📸 Overview & Vision

**InsureX** re-imagines traditional claim processing by bridging policyholders, field claim adjusters, and executive insurance administrators into a seamless, synchronized workflow. The platform emphasizes transparency, sub-second status propagation, automated audit trails, and a signature editorial visual identity.

### Three Persona Ecosystem:
1. **Policyholder / Customer**: Instant FNOL submission, live 5-phase visual progress trackers, direct in-app adjuster messaging, and digital policy document management.
2. **Claim Adjuster / Officer**: Mobile and desktop claims adjudication queue, high-resolution evidence inspection, document verification chips, adjustor remarks, and instant decision workflows (Approve / Reject / More Info).
3. **Insurance Administrator**: Centralized executive command center with live portfolio KPIs (in ₹), loss distributions, claim volume analytics, adjuster workload balancing, and immutable audit logs.

---

## 🎨 Visual Identity & Design System

The application strictly adheres to the locked **InsureX Corporate Design System**:

| Color | Hex | Role | Usage |
|---|---|---|---|
| **Merino** | `#F5EEDD` | Warm Base | Page backgrounds, subtle section fills, pill backgrounds |
| **Rock Blue** | `#84B3CE` | Secondary Blue | Information chips, subtle borders, secondary action accents |
| **Venice Blue** | `#16587B` | Primary Dark | Brand identity, primary CTAs, active states, key icons |
| **Subtle Beige** | `#FAF6EE` | Card & Container Fill | Stats containers, inner claim cards, login surfaces |
| **Beige Border** | `#EADBCE` | Card Separation | Clean, tactile container borders |

- **Currency Standard**: Indian Rupee (`₹`) standardized across all policy coverage, estimates, payouts, and executive charts.
- **Glassmorphic Floating Navigation**: Floating rounded navigation bars with elevation shadow and active state pills.

---

## 🌟 Key Features

### 👤 1. Customer Portal
- **Dashboard & Policies Overview**:
  - Live policy status breakdown (`Active`, `Expired`, `Renewing`).
  - Total coverage snapshot and monthly premium calculations.
  - Active claims preview with visual progress bars and SLA indicators.
- **Multi-Step FNOL Wizard (First Notice of Loss)**:
  - **Step 1: Policy Selection**: Dynamic policy picker loading user policies from Firestore.
  - **Step 2: Incident Details**: Claim type, incident date/time, location, and detailed damage description.
  - **Step 3: Document Upload**: Police reports, driving licenses, and repair estimates via Cloudinary.
  - **Step 4: Evidence Gallery**: Multi-photo damage capture with instant preview and Cloudinary CDN storage.
  - **Step 5: Review & Submit**: Final summary check with calculated reserve validation.
  - **Step 6: Confirmation**: Generates unique tracking ID (`CLM-YYYY-XXXX`) and routes directly to the live tracker.
- **Interactive Claim Tracker**:
  - Multi-stage timeline stepper: *Submitted → Verification → Assessment → Adjudication → Settlement*.
  - Claim detail tabs: Overview, Documents, Evidence, Timeline, and Direct Chat.
- **Customer Support Chat**:
  - Real-time bidirectional chat channel between policyholder and assigned claim officer.

### 🛡️ 2. Claim Officer Portal
- **Adjuster Field Queue**:
  - Filter claims by *Priority* (Critical, High, Medium, Low), *Status*, or *Category* (Motor, Property, Health).
  - SLA countdown timers highlighting urgent reviews (e.g., `24h left`, `4h left`).
  - Fast-action buttons: Quick Approve, Review File, or Re-assign.
- **Full Claim Adjudication Suite**:
  - Damage evidence inspector with zoomable Cloudinary media previews.
  - Document verification checklist with per-item status toggles.
  - Decision engine: Approve with disbursed settlement amount, Reject with formal reason, or Request More Info.
  - Automatic return to dashboard upon approval for streamlined field ergonomics.

### 🏢 3. Administrator Control Centre
- **Executive Analytics**:
  - Real-time status distribution donut chart and claims-by-type breakdown.
  - Key Performance Indicators: Total Portfolio Claim Value (`₹`), Average Processing Time (`d`), Approval Rate (`%`), and Total Volume.
- **Workload Management**:
  - Dynamic officer registry showing active workload, on-duty status, and department.
  - One-tap unassigned claim dispatching with automated notification triggers.
- **Regulatory Audit Trail**:
  - Immutable system activity log recording status changes, assignments, and approvals with timestamps.

---

## 🛠️ Architecture & Tech Stack

```
insurex_app/
├── lib/
│   ├── core/
│   │   ├── constants/       # App constants, routes, status codes
│   │   └── theme/           # AppColors, InsureXColors, AppTextStyles
│   ├── features/
│   │   ├── admin/           # Admin dashboards, officer assignments, audit logs
│   │   ├── auth/            # Login, registration, role-based routing
│   │   ├── customer/        # Customer home, policy vault, FNOL wizard, tracker
│   │   └── officer/         # Adjuster queue, claim detail adjudication, verification
│   ├── models/              # ClaimModel, PolicyModel, UserModel, AuditLogModel
│   ├── providers/           # AuthProvider, ClaimProvider, Navigation providers
│   ├── services/            # FirestoreService, CloudinaryService, NotificationService
│   └── widgets/             # Reusable UI cards, buttons, badges, navigation
```

- **Framework**: Flutter 3.x (Web, Android, iOS, macOS)
- **Database**: Cloud Firestore (real-time stream synchronization)
- **Media Engine**: Cloudinary unsigned direct REST upload pipeline
- **State Management**: Provider architecture with reactive Streams
- **Charts & Data Viz**: `fl_chart` for dynamic vector analytics
- **Formatting**: `intl` for Rupee currency and localized date formatting

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (v3.19.0 or newer)
- Dart SDK (v3.3.0 or newer)
- Chrome / Android Studio / Xcode

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/sakshi1013-coder/InsureTech.git
   cd InsureTech
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run tests**:
   ```bash
   flutter test
   ```

4. **Launch the application**:
   ```bash
   # Run on Chrome
   flutter run -d chrome

   # Or run on connected device
   flutter run
   ```

---

## 🔑 Demo Access Credentials

The login screen features one-tap **Quick Demo Access** chips for instant evaluation without entering credentials:

| Role | Email | Password | Scope |
|---|---|---|---|
| **Customer** | `customer@insurex.com` | `customer123` | Policyholder Dashboard & Claim Wizard |
| **Officer** | `officer@insurex.com` | `officer123` | Claim Review, Evidence & Adjudication |
| **Admin** | `admin@insurex.com` | `admin123` | Executive Metrics, Officer Dispatch & Logs |

---

## ☁️ Cloud Services Configuration

### Cloudinary Direct Upload
Direct media uploads utilize an unsigned upload preset configured for the `d2c6a4ta` cloud environment:
- **Cloud Name**: `d2c6a4ta`
- **Upload Preset**: `insurex_unsigned`
- **Storage Folder**: `insurex/`

### Firebase Firestore
- Real-time streams on `claims`, `policies`, `users`, `audit_logs`, and `notifications` collections.
- Auto-seeding mock data generator ensures complete immediate testability on fresh environments.

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
