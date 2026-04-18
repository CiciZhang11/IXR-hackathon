
# 📍 Vision Pro “Find My” Hackathon Project

## 🧠 Project Overview

This project is a **minimal, hackathon-friendly prototype** of a “Find My”-style system:

> Use Apple Vision Pro to locate a nearby iPhone using distance + directional guidance.

⚠️ **Scope is intentionally limited**:

* No encryption
* No Bluetooth / UWB
* No background tracking
* No multi-user system

✅ Focus:

* Last known location
* Distance to device
* Directional arrow

---

## 🏗️ System Architecture

### Components

1. **iPhone App (Sender)**

   * Uses CoreLocation to get GPS coordinates
   * Sends `{lat, lon, timestamp}` to backend

2. **Backend**

   * Firebase Realtime Database
   * Stores latest location only

3. **Vision Pro App (Receiver)**

   * Reads location updates
   * Computes:

     * Distance
     * Bearing (direction)
   * Displays UI (arrow + distance)

---

## 🔄 Data Flow

```
[iPhone] --(GPS data)--> Firebase --> Vision Pro
                                         |
                                         v
                           Distance + Bearing Calculation
                                         |
                                         v
                                UI (Arrow + Text)
```

---

## 🗄️ Firebase Data Model

Keep it extremely simple:

```json
{
  "devices": {
    "demo-phone": {
      "lat": 47.6205,
      "lon": -122.3493,
      "timestamp": 1710000000
    }
  }
}
```

* No authentication
* Single hardcoded device ID: `demo-phone`
* Only store latest value (overwrite each update)

---

## 📱 iPhone App

### Responsibilities

* Fetch GPS location
* Push updates every 2–5 seconds

---

### Suggested File Structure

```
iPhoneApp/
├── App.swift
├── ContentView.swift
├── Location/
│   └── LocationManager.swift
├── Services/
│   └── FirebaseService.swift
└── Models/
    └── DeviceLocation.swift
```

---

### Key Components

#### LocationManager.swift

* Wraps CoreLocation
* Publishes current location

```swift
@Published var currentLocation: CLLocation?
```

---

#### FirebaseService.swift

```swift
func updateLocation(_ location: CLLocation) {
    let data: [String: Any] = [
        "lat": location.coordinate.latitude,
        "lon": location.coordinate.longitude,
        "timestamp": Date().timeIntervalSince1970
    ]

    ref.child("devices/demo-phone").setValue(data)
}
```

---

#### ContentView.swift

* Button: “Start Sharing”
* Subscribes to location updates
* Sends updates periodically

---

## 🥽 Vision Pro App

### Responsibilities

* Listen to Firebase updates
* Compute distance + direction
* Render UI (arrow + distance)

---

### Suggested File Structure

```
VisionProApp/
├── App.swift
├── ContentView.swift
├── ViewModels/
│   └── TrackerViewModel.swift
├── Services/
│   └── FirebaseService.swift
├── Utils/
│   └── GeoUtils.swift
└── UI/
    └── ArrowView.swift
```

---

## 🧮 Core Logic

### GeoUtils.swift

#### Distance (Haversine)

```swift
func distance(from: CLLocationCoordinate2D,
              to: CLLocationCoordinate2D) -> Double
```

Returns distance in meters.

---

#### Bearing (Direction)

```swift
func bearing(from: CLLocationCoordinate2D,
             to: CLLocationCoordinate2D) -> Double
```

Returns angle in degrees (0–360).

---

## 🧭 Direction Calculation

```swift
let bearingToPhone = GeoUtils.bearing(from: userLocation, to: phoneLocation)
let userHeading = currentHeading

let relativeAngle = bearingToPhone - userHeading
```

* `relativeAngle` determines arrow rotation
* Normalize if needed to (-180, 180)

---

## 🧠 ViewModel

### TrackerViewModel.swift

```swift
class TrackerViewModel: ObservableObject {
    @Published var distanceText: String = "--"
    @Published var arrowRotation: Double = 0

    func update(userLocation: CLLocation, phoneLocation: CLLocation) {
        let distance = GeoUtils.distance(
            from: userLocation.coordinate,
            to: phoneLocation.coordinate
        )

        let bearing = GeoUtils.bearing(
            from: userLocation.coordinate,
            to: phoneLocation.coordinate
        )

        let heading = userLocation.course

        DispatchQueue.main.async {
            self.distanceText = "\(Int(distance)) m"
            self.arrowRotation = bearing - heading
        }
    }
}
```

---

## 🎯 UI Layer

### ContentView.swift

Displays:

* Distance text
* Arrow indicator

---

### ArrowView.swift

```swift
Image(systemName: "arrow.up")
    .rotationEffect(.degrees(viewModel.arrowRotation))
    .font(.system(size: 60))
```

---

## ⏱️ Build Plan (Hackathon Timeline)

### Phase 1 (1–2 hrs)

* Setup Firebase
* Hardcode test location
* Verify Vision Pro reads data

---

### Phase 2 (2–3 hrs)

* Implement iPhone GPS sending
* Display raw coordinates on Vision Pro

---

### Phase 3 (2 hrs)

* Add distance calculation
* Show “X meters”

---

### Phase 4 (2–3 hrs)

* Add bearing logic
* Rotate arrow

---

### Phase 5 (Optional Polish)

* Smooth animations
* “Last updated” timestamp
* Add “Ping phone” button (sound trigger)

---

## ⚠️ Known Limitations

* GPS accuracy: ±5–20 meters
* No indoor precision
* No background updates (app must stay open)
* No device authentication
* Direction may drift without proper heading calibration

---

## 🚫 Out of Scope

Do NOT attempt:

* Bluetooth / UWB tracking
* End-to-end encryption
* Multi-user systems
* Real-time background tracking
* Map integrations

---

## 🎉 Demo Script

1. Place iPhone somewhere nearby
2. Start location sharing on iPhone
3. Wear Vision Pro
4. Open app:

   * Shows distance
   * Arrow points toward phone
5. Walk → distance decreases → arrow updates

---

## 🧩 Key Takeaways

This project demonstrates:

* Real-time client-server communication
* Sensor data integration (GPS + heading)
* Spatial UI concepts
* Cross-device interaction

Despite its simplicity, it creates a **compelling “magic moment”** during demo.

---

## 🛟 Backup Plan (Highly Recommended)

Add a fallback mode:

* Hardcoded phone location
* Simulated heading

This ensures demo works even if:

* GPS fails
* Sensors behave unpredictably

---

## ✅ Final Scope Checklist

* [ ] iPhone sends location
* [ ] Vision Pro receives data
* [ ] Distance displayed
* [ ] Arrow rotates correctly
* [ ] Demo works reliably

---

**It is expected that the user will encounter issues during the process,
this is just a Hackathon project, remember, the end goal's just an unsophisticated demo,
and hopefully learning experience with coding for Vision Pro**
