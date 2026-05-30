# Gota — gota-pp-frontend-flutter

Cross-platform **Flutter** frontend for an **irrigation optimization platform** focused on water saving in the arid zones of northern Mexico (with planned expansion to the southern United States).

The app tells farmers **how much water to apply per square meter**, combining NASA satellite data, the platform's own models, and data from partner drones and ground sensors. Its goal is to help low-resource farmers (and technical users alike) save water — and money — by watering exactly what's needed.

> **Status:** UI / demo stage. The figures shown in the app are realistic placeholder data; there is no backend wired up yet.

---

## ✨ Features

The Home screen has three entry points: a metrics **dashboard**, an **assistant chat**, and a **partner marketplace**.

### 🏠 Home — "the number that matters"
- App identity bar: brand **Gota**, location and today's date (auto-generated, in Spanish).
- Full-screen **weather background** that cycles every 7 seconds between three states — `templado` (mild), `calor` (hot) and `lluvia` (rain). All images share the exact same framing, so only the *weather* changes, never the terrain.
- A central **ring** highlighting the hero data: weather + temperature, the giant **L/m² recommendation**, the suggested action (*"Riega hoy"* / *"No riegues hoy"*) and a **"Datos NASA"** trust badge.
- The background fades into the app's khaki color right where the navigation buttons begin.

### 📊 Gráficos — dashboard
- **Forces landscape orientation** on entry (restores portrait on exit) for better chart readability.
- Three **KPI cards**: recommended water today, monthly savings, current soil humidity.
- Five charts built with **fl_chart**:
  1. Irrigation recommendation — last 7 days (line)
  2. Accumulated water saved — this month (bars)
  3. Current soil humidity (donut / gauge)
  4. Expected precipitation — next days (bars)
  5. Temperature — last 7 days (line)

### 💬 Chat — irrigation assistant
- **Local keyword bot** (no internet, no external AI): answers about *why to water today*, *when not to*, *how much you save*, and *where the data comes from*.
- Chat bubbles, quick-reply **FAQ chips**, and a text input bar.

### 🤝 Socios — partner marketplace
- **Swipeable carousel** (`PageView`) of three partner cards: camera drones, ground sensors, and a government-data connection.
- Plan-style cards (Surfshark-like) with a **metallic slate border**, a distinctive icon, monthly price (MXN), a benefits list, and a **"Contratar"** button.
- Navigation via swipe, side **arrows**, and page **dots**.

---

## 🎨 Design palette

| Token         | Hex         | Usage                          |
|---------------|-------------|--------------------------------|
| Slate         | `#2F3D52`   | Buttons, text, icons, borders  |
| Khaki / beige | `#E6E2DC`   | General background             |

Shapes across the app use **beveled corners** for a consistent look.

---

## 🧱 Tech stack

- **Flutter** (Dart SDK `^3.11.4`)
- [`fl_chart`](https://pub.dev/packages/fl_chart) `^1.2.0` — charts in the dashboard
- [`font_awesome_flutter`](https://pub.dev/packages/font_awesome_flutter) `^11.0.0` — partner icons
- `cupertino_icons` `^1.0.8`

---

## 📁 Project structure

```
lib/
  main.dart                       # App entry point, MaterialApp + theme
  presentacion/
    pantallas/
      home.dart                   # Home: weather hero + navigation
      graficos.dart               # Dashboard (landscape, fl_chart)
      chat.dart                   # Local keyword chatbot
      socios.dart                 # Partner cards carousel
assets/
  clima/                          # Weather backgrounds (templado / calor / lluvia)
  paneles/                        # Legacy panel images
```

---

## 🚀 Getting started

**Prerequisites:** [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and a device/emulator available.

```bash
# 1. Install dependencies
flutter pub get

# 2. Run the app (pick your device)
flutter run
# or target a specific device, e.g. an Android emulator:
flutter run -d emulator-5554
```

While `flutter run` is active: `r` hot reload · `R` hot restart · `q` quit.

> **Tip:** after changing assets or `pubspec.yaml`, do a full restart (`R`) — hot reload doesn't always pick up new assets.

---

## 📝 Notes

- The app currently ships with **demo data**; weather, recommendations, charts and partner prices are illustrative.
- The microphone shown next to the chat input belongs to the device keyboard (Gboard / system IME), not to the app.
