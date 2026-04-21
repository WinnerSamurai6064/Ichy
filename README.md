# IEchilli — Chat App by TEKDEV

A full-stack chat application: Flutter (Dart) mobile app + standalone web UI served on Vercel with Neon PostgreSQL and Cloudflare R2 storage.

---

## 📁 Project Structure

```
iechilli/
├── vercel.json                   ← Root Vercel config (deploy this folder)
├── package.json
├── build.sh                      ← Optional: run flutter build web locally
├── flutter_app/
│   ├── pubspec.yaml
│   ├── lib/                      ← Full Flutter source
│   └── build/web/
│       └── index.html            ← Pre-built web app (works immediately on Vercel)
└── vercel_api/
    ├── package.json              ← { @neondatabase/serverless }
    ├── schema.sql                ← Run once against your Neon DB
    └── api/
        ├── _lib/db.js            ← Shared DB + JWT + CORS helpers
        ├── auth/
        │   ├── login.js
        │   └── register.js
        ├── chats/index.js
        ├── messages/[chatId].js
        ├── users/
        │   ├── me.js
        │   └── search.js
        ├── upload/presign.js     ← R2 presigned PUT URLs
        └── statuses/index.js
```

---

## 🚀 Deploy to Vercel

### 1. Set environment variables in Vercel dashboard

| Variable | Description |
|---|---|
| `DATABASE_URL` | Neon connection string (`postgresql://...`) |
| `JWT_SECRET` | Any long random string |
| `R2_ACCOUNT_ID` | Cloudflare account ID |
| `R2_ACCESS_KEY_ID` | R2 API token key ID |
| `R2_SECRET_ACCESS_KEY` | R2 API token secret |
| `R2_BUCKET_NAME` | Your R2 bucket name |
| `R2_PUBLIC_URL` | Public URL for bucket (e.g. `https://pub-xxx.r2.dev`) |

### 2. Bootstrap the database

```bash
psql $DATABASE_URL -f vercel_api/schema.sql
```

### 3. Deploy

```bash
# Install Vercel CLI if needed
npm i -g vercel

# Deploy from the iechilli/ root
cd iechilli
vercel --prod
```

That's it. The pre-built `flutter_app/build/web/index.html` is served immediately as a full functional web app.

---

## 📱 Build Flutter App (mobile)

```bash
cd flutter_app

# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Web (replaces the pre-built index.html with Flutter compiled output)
flutter build web --release --web-renderer canvaskit
```

After `flutter build web`, copy the contents of `flutter_app/build/web/` and redeploy to Vercel.

---

## 🔧 Update API base URL

In `flutter_app/lib/services/api_service.dart`, change:
```dart
static const String baseUrl = 'https://iechilli-api.vercel.app/api';
```
to your actual Vercel deployment URL.

---

## 🌶️ Features

- Real-time messaging via WebSocket
- Auth with JWT (register / login)
- Chat list with unread badges
- Message bubbles with read receipts (✓✓)
- Media uploads to Cloudflare R2 (presigned PUT)
- Status updates (24h expiry)
- Group chats
- Dark theme — chilli red accent
- Works immediately as a web app on Vercel without Flutter compilation
