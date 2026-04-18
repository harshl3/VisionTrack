# VisionTrack - CCTV Surveillance App


VisionTrack is a scalable, real-world mobile application designed for Police and Survey Personnel. It enables the registration, management, and visualization of government and private CCTV cameras on an interactive live map. Built with a professional "police-grade" interface, this system integrates robust Node.js backend logic with seamless mobile UI workflows.

---

## 🌟 Features

*   **Role-Based Security:** Secure JWT Authentication separating permissions between `POLICE` (Admin/Viewer) and `SURVEY` (Field Data Collector).
*   **Live Interactive Map Dashboard:** Real-time Google Maps integration showing camera markers. Includes click-to-view coverage details.
*   **Emergency Mode Override:** With a single button click, the app triggers High-Alert framing, automatically zooming the map to secure nearby zones and sending distinct visual signals.
*   **Smart Registration Form:** GPS geolocation fetching to smoothly input private/government cameras.
*   **Detailed Analytics (Simulated):** Bottom sheet displays highlighting Camera Type, Range, and interactive Live Feed simulations.

---

## 🛠️ Tech Stack

**Frontend (Mobile):**
*   **Flutter** (Dart)
*   **Provider** (State Management)
*   Google Maps Flutter SDK
*   Dio/Http Networking
*   Flutter Dotenv

**Backend & Database:**
*   **Node.js** & **Express** framework
*   **PostgreSQL** Database via raw `pg` queries
*   Bcrypt (Password Hashing)
*   JSON Web Tokens (JWT)
*   **Nodemon** for live reloading

---

## 📁 Folder Structure

### Frontend Structure (`lib/`)
```text
lib/
├── core/
│   ├── constants/app_colors.dart    # Central color theme 
│   ├── theme/app_theme.dart         # Flutter Material Themes
├── presentation/
│   ├── providers/auth_provider.dart # Auth UI State Management
│   ├── screens/                     # Views (Login, Map, Camera Registration)
└── main.dart
```

### Backend Structure (`backend/`)
```text
backend/
├── config/db.js                 # PostgreSQL config using Pool
├── controllers/                 # Business logic for requests
├── middlewares/                 # Auth verifier and RBAC
├── routes/                      # API routing mappings
├── server.js                    # Node starting point
├── initDb.js                    # Migration script for SQL DB
└── package.json
```

---

## 🚀 Project Workflow & Implementation

1.  **Backend Init:**
    *   Initialize PostgreSQL instance and insert `.env` configuration.
    *   Run `node initDb.js` to build `users` and `cameras` SQL schemas gracefully.
    *   Launch backend effectively via `npm run dev` (Nodemon tracking).

2.  **Frontend Execution:**
    *   App reads `.env` variables ensuring safe connection to base URLs (e.g. `http://10.0.2.2:3000`).
    *   Role authentication is processed through `auth_provider` routing dynamically to the Map.

3.  **Surveillance Activity:**
    *   Users can actively tap on map indicators to pop over detailed Bottom Sheets.
    *   Tapping the Emergency mode activates red bounding boxes emphasizing high alerts.

---

## 🔌 API Endpoints (Basic)

| Method | Endpoint               | Description                                      | Access           |
|--------|------------------------|--------------------------------------------------|------------------|
| POST   | `/api/auth/register`   | Registers new user with Bcrypt hashed passwords. | Public           |
| POST   | `/api/auth/login`      | Verifies credentials & assigns JWT token.          | Public           |
| GET    | `/api/cameras`         | Fetches full database of existing cameras.         | Auth/Token Req.  |
| GET    | `/api/cameras/:id`     | Details parameters of a unique camera.             | Auth/Token Req.  |
| POST   | `/api/cameras`         | Inputs a fresh camera payload from surveyors.      | Auth/Token Req.  |

---

## 🔮 Future Enhancements

*   **Offline Support:** Caching Map regions using SQLflite / Hive for out-of-bounds regions.
*   **AI Analytics:** Using Tensorflow-lite/Gemini plugins directly detecting blind spots from topological patterns.
*   **Clustering Enhancements:** Grouping hundreds of cameras into map bubbles dynamically zooming.
*   **Video Feed Proxies:** Connect real RTSP protocols linking Live feed directly to App players.




## Quick Steps to Launch Right Now:
* - Make sure your local Postgres database service is running in the background.
* - Open a terminal in policeApp/backend and type npm run dev. Your backend is now alive.
* - Launch your Android Emulator.
* - Open a second terminal precisely in policeApp (the root Flutter folder) and type flutter run to install and launch the app!