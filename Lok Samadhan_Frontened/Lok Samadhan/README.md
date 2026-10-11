# Lok Samadhan (लोक समाधान)

> AI-Powered Civic Grievance Redressal & Citizen Governance Platform

Lok Samadhan is a comprehensive civic tech platform designed to bridge citizens and public departments. It enables multi-modal grievance lodging (Text, AI Photo Diagnosis, Voice, IVR simulation) and streamlines departmental resolution tracking.

---

## 📁 Repository Structure

```
Lok Samadhan/
├── Lok Samadhan/              # Flutter Frontend Application
│   ├── lib/                  # Dart application source code
│   │   ├── providers/        # State management (ChangeNotifier)
│   │   ├── screens/          # Citizen & Official UI dashboards
│   │   ├── services/         # API & Supabase clients
│   │   └── widgets/          # Reusable UI components
│   └── pubspec.yaml          # Flutter dependencies
│
└── lok Samadhan_backend/     # Node.js / Express Backend API
    ├── database/             # PostgreSQL / Supabase schema & seeds
    ├── src/
    │   ├── controllers/      # Route controllers (Auth, AI, Grievances)
    │   ├── middleware/       # JWT auth, rate limiting, error handlers
    │   ├── routes/           # REST endpoints
    │   └── services/         # Supabase, Gemini AI, OpenStreetMap Nominatim
    └── package.json          # Node.js dependencies
```

---

## 🚀 Getting Started

### 1. Prerequisites
- **Flutter SDK**: 3.x+
- **Node.js**: 18.x+
- **PostgreSQL / Supabase Account**

### 2. Backend Setup
```bash
cd "lok Samadhan_backend"
npm install
cp .env.example .env
# Edit .env with your Supabase and Gemini credentials
npm run dev
```

### 3. Frontend Setup
```bash
cd "Lok Samadhan"
flutter pub get
cp .env.example .env
# Configure API_BASE_URL and SUPABASE_URL in .env
flutter run
```

---

## 🛡️ License
Private & Proprietary - Developed for SIH / Civic Governance Initiative.
