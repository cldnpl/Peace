# MindMesh — Setup Guide per Xcode

## Requisiti
- Xcode 15+
- iOS 17+ Deployment Target
- Swift 5.9+

---

## Come creare il progetto Xcode

### 1. Crea il progetto
1. Apri Xcode → **File > New > Project**
2. Seleziona **iOS > App**
3. Impostazioni:
   - **Product Name:** MindMesh
   - **Team:** (il tuo Apple ID)
   - **Bundle ID:** com.yourname.mindmesh
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Include Tests:** opzionale
4. Clicca **Create** e scegli dove salvare

### 2. Struttura cartelle da creare
Nel Project Navigator (pannello sinistra), crea i seguenti **Groups** (tasto destro → New Group):

```
MindMesh/
├── MindMeshApp.swift          ← già creato da Xcode
├── Theme/
│   └── Theme.swift
├── Models/
│   └── Models.swift
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── MindMapViewModel.swift
│   └── EmotionViewModel.swift
├── Components/
│   └── SharedComponents.swift
└── Views/
    ├── MainTabView.swift
    ├── Onboarding/
    │   └── OnboardingView.swift
    ├── Home/
    │   └── HomeView.swift
    ├── MindMap/
    │   └── MindMapView.swift
    ├── EmotionTracker/
    │   └── EmotionTrackerView.swift
    ├── AIInsights/
    │   └── AIInsightsView.swift
    └── Profile/
        └── ProfileView.swift
```

### 3. Aggiungi i file
Per ogni file Swift fornito:
1. **Tasto destro** sul gruppo corretto → **New File > Swift File**
2. Dai il nome corretto (es. `Theme.swift`)
3. **Incolla** il contenuto del file corrispondente
4. Ripeti per tutti i file

### 4. Cancella ContentView.swift
Il progetto Xcode crea `ContentView.swift` di default — **eliminalo** (Move to Trash), dato che usiamo `MainTabView`.

### 5. Aggiorna MindMeshApp.swift
Xcode genera un `MindMeshApp.swift` di default. **Sostituisci tutto il contenuto** con quello fornito.

### 6. Build Settings
In **Project Settings > General**:
- **Minimum Deployments:** iOS 17.0
- **iPhone Orientation:** Portrait (consigliato per ora)

### 7. Colori (opzionale ma consigliato)
In **Assets.xcassets**, puoi aggiungere un **AccentColor**:
- Seleziona `AccentColor` → imposta su `#7C6AF7` (hex) per entrambe le appearance

---

## Architettura

| Layer | Tecnologia |
|---|---|
| UI | SwiftUI (iOS 17) |
| State | @StateObject / @ObservedObject / @AppStorage |
| Pattern | MVVM |
| Data | In-memory (pronto per Firebase/Firestore) |
| Animations | SwiftUI native animations + spring |
| Canvas | SwiftUI Canvas API per Mind Map edges |

---

## Prossimi step per produzione

### Firebase
```swift
// Package.swift o SPM
// URL: https://github.com/firebase/firebase-ios-sdk
// Prodotti: FirebaseFirestore, FirebaseAuth
```

### AI Integration
```swift
// Chiama OpenAI API o Anthropic API
// in AIInsightsViewModel → func fetchInsights()
```

### Persistenza locale
```swift
// Sostituire array sample con SwiftData:
// @Model class MoodEntry { ... }
// @Query var entries: [MoodEntry]
```

---

## Note sul design
- Dark mode only (per ora)
- Palette: Viola `#7C6AF7`, Teal `#2DD4BF`, Rose `#FB7185`
- Font: SF Pro (sistema iOS nativo — HIG compliant)
- Border radius coerenti tramite `MMRadius` enum
- Spacing coerente tramite `MMSpacing` enum

---

*Built @ Apple Developer Academy, Napoli · VentureLab 2025*
