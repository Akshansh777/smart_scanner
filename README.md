# Smart Document Scanner 📄✨

> **Scan · Extract · Organize · Understand**  
> A high-performance Flutter mobile application combining on-device document scanning, offline OCR, PDF editing/annotation, and Gemini 1.5 AI summarization.

---

## 🛠 Tech Stack & Core Libraries

- **Framework:** Flutter (Targeting Android & iOS)
- **Architecture & State Management:** Clean Architecture + `flutter_riverpod`
- **Native Document Scanner:** `google_mlkit_document_scanner` (Edge detection, auto-crop, shadow removal)
- **On-Device OCR:** `google_mlkit_text_recognition`
- **PDF Engine & Canvas:** `syncfusion_flutter_pdfviewer` / `pdfrx`, `pdf`, `printing`
- **Local Persistence:** `hive_ce`, `hive_ce_flutter`
- **AI Intelligence:** `google_generative_ai` (Gemini 1.5 Flash / Pro)
- **Device Storage & Sharing:** `path_provider`, `share_plus`

---

## 👥 Team Workstreams & Ownership

| Member | Focus Area | Core Modules |
| :--- | :--- | :--- |
| **Akshansh (Lead)** | System Architecture, Storage & AI | App Shell, Riverpod, Hive CE DB, Gemini 1.5 Service (`features/ai_assistant`, `core/`) |
| **Krishna** | Camera Scanner & ML OCR | Native ML Scanner UI, Auto-crop/Filter, Offline OCR (`features/scanner/`) |
| **Arun** | PDF Generation, Viewer & Canvas | Image-to-PDF, PDF Viewer, Canvas Annotations, Share Sheet (`features/pdf_workspace/`) |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.3.0` or higher
- Android Studio / VS Code with Flutter & Dart extensions
- Android device or emulator running API level 21+ (Document Scanner works best on physical Android devices with Google Play Services)
- Gemini API Key from Google AI Studio

### Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Akshansh777/smart_scanner.git
   cd smart_scanner
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app with your Gemini API key:**
   ```bash
   flutter run --dart-define=GEMINI_API_KEY="YOUR_ACTUAL_GEMINI_API_KEY"
   ```
