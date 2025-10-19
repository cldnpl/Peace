# MindMesh 🧊
**Simple. Blue. Yours.**

MindMesh is a native iPhone app to track your mood and map your thoughts without the digital mess.

---

### 🎨 Design Philosophy
- **All Blue:** Light blue gradients to reduce visual stress.
- **Clean UI:** followed perfeclty HIG + integrated native Apple SF Symbols.
- **Tactile:** Real iPhone haptic feedback for every interaction.
- **Honest Data:** If there’s not enough data for an analysis, the app tells you.

---

### 🛠 Tech Stack (100% Native)
- **SwiftUI:** Modern, declarative, and fast.
- **MVVM:** Clean architecture for better maintenance.
- **Combine:** Real-time state updates.
- **UserDefaults:** Lightweight local persistence.
- **UserNotifications:** Real daily reminders.

### 🧠 Local Logic Engine (The "Honest AI")
Unlike other apps that rely on external LLMs, MindMesh uses a **Rule-Based Local Engine** for trend analysis, ensuring 100% privacy and offline functionality:
- **Data Source:** Check-ins are stored as `MoodEntry` arrays in `UserDefaults` via `MoodJournalStore`.
- **Reliability Threshold:** The engine (`reflectionSnapshot`) requires at least 3 entries in 7 days. If the data is insufficient, it displays an "Empty State" instead of inventing insights.
- **Analysis Logic:** It calculates energy metrics, mood frequency, and weekly deltas to generate predefined, high-quality insights (e.g., *"The tone is lightening up"* or *"More friction detected lately"*).
- **Fast & Private:** Zero latency, zero internet required, and total transparency on how insights are generated.

---

### 🚀 Key Features
- **Interactive Mind Maps:** Drag nodes around. Change the center node, the title updates automatically.
- **Mood Tracker:** Quick 7-day trend view.
- **Safe Area Optimized:** Perfect layout for Dynamic Island and all iPhone models.

---

### 🖋 Author
**Claudia Napolitano** *Project started: Sept 2025*
