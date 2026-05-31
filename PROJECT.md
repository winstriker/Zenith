# Project: Flutter Pilot Flight Tracker ✈️

## 🚀 Goal

To develop a multiplatform (Android, iOS, iPadOS) Flutter application that tracks a pilot's flight path using GPS and visualizes the entire journey in an interactive 3D map environment post-landing.

## ✨ Key Features

- **Multiplatform Compatibility:** Seamless operation across Android, iOS, and iPadOS.
- **High-Accuracy Tracking:** Continuous, background-running GPS logging of coordinates during flight.
- **Terrain Mapping:** Visualization on an open-source map that includes rendered terrain data (excluding buildings).
- **3D Replay:** A core feature where a 3D airplane model follows and animates along the recorded path when viewed post-flight.

## ⚙️ Technology Stack

- **Framework:** Flutter
- **State Management:** Riverpod / Provider (Recommended)
- **Mapping/GIS:** MapLibre GL Native wrapper (or equivalent OpenStreetMap service supporting advanced styling).
- **Data Persistence:** Hive or Drift/sqflite.

## 🏗️ Project Phases & Milestones

### **Phase 1: Data Acquisition & Storage (MVP)**

- **Objective:** Establish reliable data capture and persistence.
- **Implementation Focus:**

1.  **Background Service:** Implement platform-specific services to ensure GPS continues logging when the app is backgrounded/closed (Android Foreground Services, iOS Background Modes).
2.  **Data Model:** Define `FlightPoint`: (`Latitude`, `Longitude`, `Altitude`, `Timestamp`). _Refinement:_ The model now includes a necessary **Session ID** field for grouping points belonging to one continuous mission run.
3.  **Storage:** Save all flight session data locally using Hive or Drift, structured by `SessionID`.

### **Phase 1: Data Acquisition & Storage (Operational)**

- **Status:** Complete - Phase 1 Operational.
- The core logging module is functional and persists data reliably to local storage via the `FlightPointService`. The system can successfully capture multiple points and group them under a unique `SessionID`, which fulfills the MVP requirement for demonstrable, durable data acquisition.

### **Phase 2: Open-Source Map & Terrain Integration**

- **Objective:** Display the recorded path on an immersive, open-source map featuring terrain elevation.
- **Technical Challenges & Mitigation:**
  1.  **Mapping Source:** Utilize OpenStreetMap and its compatible tiling service (e.g., through MapLibre).
  2.  **Terrain Data (DEM):** Standard OSM tiles are insufficient for terrain. Integration requires sourcing specialized Digital Elevation Model (DEM) tile layers (e.g., from OpenTopography). This must be configured as a custom tile source in the mapping library.
  3.  **Exclusions:** Ensure building data is excluded during map rendering, focusing solely on ground topography.

### **Phase 3: 3D Visualization & Replay (Final Product)**

- **Objective:** Render the flight path dynamically with an aircraft model for visual replay.
- **Implementation Details:**
  1.  **Path Projection:** Load saved `FlightPoint` data and calculate smooth, interpolated coordinates over time to define the complete flight spline.
  2.  **3D Scene Setup:** Initialize a 3D rendering viewport using a Flutter 3D package (e.g., one that handles geo-spatial positioning).
  3.  **Asset Integration:** Load a generic 3D plane model (Recommended format: GLTF/GLB).
  4.  **Replay Logic:** On user action, animate the plane model's position and orientation from start to finish, mapping its movement onto the base terrain mesh defined in Phase 2.

## 🛑 Scope & Constraints

1.  **DEM Data Access:** The primary blocker is obtaining reliable, streamable DEM tile data compatible with Flutter/MapLibre. This requires investigating external APIs or public datasets.
2.  **3D Geo-Rendering:** Selecting a Flutter package that can reliably handle the combination of geo-coordinates (Lat/Lng) and 3D physics/rendering for the aircraft model is highly challenging and may require writing significant native platform code.

**Platform Limitation:** Note that all features must only run on platforms specified in this document (e.g., Android, iOS, iPadOS). Any unsupported operating system paths must include runtime checks and fail gracefully to ensure stability.
