# VisionTrack User Guide & Operations Manual

Welcome to the **VisionTrack** ecosystem! This manual is designed to help field personnel and police administrators quickly understand how to navigate and utilize the mobile application in real-world scenarios.

---

## 👥 Understanding User Roles

The application strictly separates capabilities based on two primary roles:

1.  **👮 POLICE (Admin / Headquarter Operations)**
    *   **Primary Duty:** Surveillance monitoring, data analysis, and incident response.
    *   **Capabilities:** Can view the active camera matrix, inspect specific camera details (government and private), and activate network-wide **Emergency Overrides** during critical situations.

2.  **📋 SURVEY (Field Personnel / Technicians)**
    *   **Primary Duty:** Expanding the camera coverage database by registering new residential and commercial CCTVs.
    *   **Capabilities:** Can access the map to pinpoint geographical blind spots and use the **Registration Toolkit** to log new camera hardware coordinates into the central state database.

---

## 📱 Screen-by-Screen Walkthrough

### 1. VisionTrack Splash Screen
**Who uses it:** Both Roles
*   **What it does:** Displays the clean VisionTrack logo and smoothly authenticates your stored local session in the background. If a session is valid, it throws you straight to the Map. Otherwise, it pushes you to Role Selection.

### 2. The Role Selection Gateway
**Who uses it:** Unauthenticated Users
*   **What you do here:** A modern split selection screen. You must explicitly choose to **LOGIN AS ADMIN** or **LOGIN AS USER**.

### 3. Secure Admin Login (Headquarters Access)
**Who uses it:** 👮 POLICE Admins Only
*   **What it is:** A deeply isolated, restricted node. It validates against the primary 3 pre-seeded administrative master accounts safely hidden in the central database.
*   **Available Accounts:** `admin1@gmail.com`, `admin2@gmail.com`, `admin3@gmail.com` with respective passwords `admin1`, `admin2`, `admin3`.
*   Note: For maximum administrative security, there is **no public registration option** on this screen.

### 4. Field Operative Login & Registration
**Who uses it:** 📋 SURVEY Technicians
*   **What it is:** A secondary portal explicitly for users mapped with the **SURVEY** tag.
*   **Usage:** You can login with existing Surveyor credentials, or tap the **"New Field Operative? Register Here"** link to create your own account instantly via backend POST routing. All fields safely encrypt inside PostgreSQL.

### 5. Live Surveillance Map Dashboard (The Core Hub)
**Who uses it:** Both Roles (With different toolsets)
*   **What you do here:** This is the primary interactive Google Map where registered cameras appear as graphical markers.
*   **Color Coding:** 
    *   🔵 **Blue/Azure Markers:** Official Government & Traffic Cameras.
    *   🟡 **Amber/Orange Markers:** Private/Residential Cameras.
*   **Interactivity:** Tapping any marker pushes up a **Details Bottom-Sheet** containing the owner name, camera status (e.g., Active/Offline), coverage range (e.g., 50 meters), direction faced, and a button to view a simulated Live Feed.

### 3. Emergency Override System 🚨
**Who uses it:** POLICE Admins Only
*   **What it does:** In the bottom corner of the Map Dashboard, Police users have access to an **"EMERGENCY"** button.
*   **Actionable Consequence:** Tapping this button forces the app into a High-Alert UI. The screen frames in crimson red, and the map rapidly zeroes in and locks onto the nearest high-density camera clusters around an incident coordinates. Tapping it again cancels the alert.

### 4. Camera Registration Interface
**Who uses it:** Primarily SURVEY Personnel
*   **How to access it:** If your role authorizes camera logging, a **Camera (+)** icon will appear in the top-right of your Map Dashboard.
*   **What you do here:** 
    *   You arrive at a physical location (e.g., a local bakery owner agreed to share their exterior feed).
    *   Tap simple buttons to Auto-Fetch your exact GPS coordinates.
    *   Input the owner's Contact Info, the hardware Type (Private), and visual coverage details (Direction/Range).
    *   Hitting **Save** instantly broadcasts this new camera to Police headquarters servers.

---

## 🏃‍♂️ Typical Usage Scenarios

### A Day in the Life: Survey Personnel
1. Log into the app at the start of your shift using your Survey credentials.
2. Open the Live Map and walk down an assigned street. 
3. Tap the map to identify coordinate drop points, then hit the "Register Camera" icon.
4. Input the new camera's owner details, save it, and watch the icon instantly propagate onto the central grid for law enforcement to utilize.

### A Day in the Life: Police Operations
1. Log into the app at headquarters or in a patrol car.
2. Leave the Live Map Dashboard open to monitor city sectors. Tap on blue and amber icons to quickly verify if feeds are active.
3. *Incident occurs:* A robbery is reported. Tap **EMERGENCY**. The system highlights the zone.
4. Tap the markers closest to the incident out-path, open the details sheet, and request the live feed to track a suspect's direction securely.
