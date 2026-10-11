# London Arrivals — iOS App & Live Platform Widgets 🚆🇬🇧

An authentic iOS app and WidgetKit extension that brings the iconic London Underground arrival boards to your iPhone Home Screen and Lock Screen. Powered by the real-time **TfL (Transport for London) Unified API**.

---

## 🌟 Highlights

- **Exact London Arrival Board Design**:
  - Recreates the iconic London platform **Dot Matrix Indicators (DMIs)**.
  - Substrate featuring thousands of unlit LED matrix dots (`LEDGridBackground`).
  - Glowing amber/orange (`#FFA000`) and National Rail canary yellow LED illumination with realistic bloom and character tracking.
  - Matte industrial enclosure casing with metallic bevel and 4 corner mounting screws/rivets.
  - Authentic 3-row platform indicator layout with departure order, destination, platform code, and countdown minutes (`DUE`, `1 MIN`, `5 MIN`).
  - Bottom service ticker (`● GOOD SERVICE ● CHECK FRONT OF TRAIN ●`).

- **Favourite Any London Commute**:
  - Preloaded with **Northern line to Moorgate** (from Old Street), **Elizabeth line to Canary Wharf**, **Victoria line**, and **Central line**.
  - Add any custom commute across **London Underground**, **Elizabeth line**, **London Overground**, or **DLR**.
  - Filter by origin station, line, destination, and platform.

- **iOS WidgetKit Integration**:
  - **Medium Widget**: Reproduces the exact 3-row London Underground platform indicator with live countdowns and status ticker.
  - **Small Widget**: High-impact next-train board featuring large amber LED minutes countdown, destination, and next queue.
  - **Large Widget**: Full station departure board displaying 5 upcoming services and calling points.
  - **Lock Screen Widgets**: Rectangular, Inline (`🚆 Moorgate in 2m`), and Circular countdown widgets.

- **Interactive In-App Experience**:
  - **Live Board**: Interactive platform board with automatic 10-second live refresh and manual refresh button.
  - **Platform Audio Chime**: British-accented station voice announcements (`AVSpeechSynthesizer`) reciting upcoming departures.
  - **Board Themes**:
    - *Underground Amber*: Classic London Underground platform LED.
    - *National Rail Yellow*: Iconic British mainline departure screen.
    - *Vintage Emerald*: Retro 1980s London vacuum fluorescent display.
    - *Modern OLED White*: High-contrast dot-matrix display.
  - **Station Explorer**: Live search across all London stations and hubs (Moorgate, Finsbury Park, King's Cross, London Bridge, etc.) with instant board inspection.
  - **Network Status**: Real-time TfL disruption and line status overview.

---

## 📱 How to Open & Run

1. Open the project in Xcode:
   ```bash
   open LondonArrivals.xcodeproj
   ```
2. Select your target simulator (e.g., iPhone 17/18 Pro on iOS 17.0+) or physical device.
3. Press **Cmd + R** to run!

---

## 🧩 Adding Widgets to Your iOS Home Screen

1. On your iPhone home screen, press and hold an empty area until the apps jiggle.
2. Tap the **`+`** button in the upper corner.
3. Search for **"London Arrivals"** or **"Arrivals Board"**.
4. Choose between **Small**, **Medium** (recommended for the authentic platform indicator look), or **Large**.
5. Tap **Add Widget**.
6. In the app, tap **"Set as Widget"** on any of your saved commutes (e.g. *Great Northern to Moorgate*) to update the widget instantly!

---

## 🛠 Project Architecture

```
new-test/
├── LondonArrivals.xcodeproj/      # Xcode project (generated via xcodegen)
├── project.yml                     # Reproducible project definition
├── LondonArrivals.entitlements      # App Group sharing entitlements
├── LondonArrivalsWidget.entitlements
├── LondonArrivals/
│   ├── App/
│   │   ├── Info.plist
│   │   ├── LondonArrivalsApp.swift
│   │   ├── ContentView.swift
│   │   └── Views/
│   │       ├── LiveBoardDetailView.swift    # Interactive platform indicator simulator
│   │       ├── WidgetGalleryView.swift      # In-app widget preview showroom
│   │       ├── CommutesListView.swift       # Saved favourites management
│   │       ├── AddCommuteView.swift         # Commute creator with TfL station search
│   │       ├── StationSearchView.swift      # London station explorer
│   │       ├── LineStatusView.swift         # TfL disruptions and service status
│   │       └── SettingsView.swift           # Widget guide & TfL API key setup
│   └── Shared/
│       ├── Models/
│       │   ├── FavouriteCommute.swift       # Commute model (Line, Origin, Destination, Theme)
│       │   ├── ArrivalPrediction.swift      # Live TfL prediction parser & matrix formatters
│       │   ├── BoardTheme.swift             # Authentic LED color palettes & bezel styles
│       │   ├── TransportMode.swift          # Tube, National Rail, Elizabeth, Overground, DLR
│       │   ├── TfLLine.swift                # Official line identities & brand colors
│       │   └── TfLStopPoint.swift           # Station hubs & search results
│       ├── Services/
│       │   ├── TfLService.swift             # TfL Unified API client with HUB resolution
│       │   ├── CommuteStorage.swift         # App Group persistence & timeline syncing
│       │   └── AudioAnnouncer.swift         # UK-accented platform departure voice
│       ├── Views/
│       │   ├── DotMatrixBoardView.swift     # Core London platform arrivals board
│       │   ├── DotMatrixText.swift          # Monospaced typography with dual LED bloom
│       │   ├── LEDGridBackground.swift      # Canvas rendering of unlit matrix pixels
│       │   └── BoardBezelView.swift         # Industrial enclosure with corner rivets
│       ├── Widgets/
│       │   └── CommuteWidgetTimelineProvider.swift  # WidgetKit timeline provider
│       └── WidgetViews/
│           ├── SmallWidgetBoardView.swift   # Compact next-train hero widget
│           ├── MediumWidgetBoardView.swift  # Flagship 3-row platform indicator widget
│           ├── LargeWidgetBoardView.swift   # 5-train mainline departures board widget
│           └── LockScreenWidgetViews.swift  # Rectangular, Inline, Circular Lock Screen
└── LondonArrivalsWidget/
    ├── Info.plist
    ├── LondonArrivalsWidgetBundle.swift     # Widget extension bundle entry
    └── LondonArrivalsWidget.swift           # Widget declaration & configuration
```
