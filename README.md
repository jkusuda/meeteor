# Meeteor 📸

An astrophotography social platform that encourages users to capture celestial objects through daily challenges, share camera specs, and build a community.

## 🎯 Project Overview

**Health Focus:** Mental health through hobby engagement, community building, and outdoor activity encouragement.

**Key Features:**
- Daily astrophotography challenges based on what's visible in the night sky
- Share photos with detailed camera/telescope specifications
- Equipment-based search
- Community feed with likes and comments
- User profiles with stats and achievements

---

## 🛠️ Tech Stack

### Frontend
- **Flutter (Dart)** - Cross-platform framework
- **Material Design** - UI components and design system

### Backend (Supabase)
- **Supabase Authentication** - User login/registration
- **Supabase PostgreSQL Database** - Relational database for users, posts, challenges
- **Row Level Security (RLS)** - Secure data access policies

### Development Tools
- **VS Code** - IDE with Flutter plugin
- **Supabase Dashboard** - Backend management dashboard

---

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:
- **Git** - Version control
- **Flutter SDK** - Mobile/Web development framework
- **VS Code** or another preferred editor

---

## 📥 Installation Instructions

### 1. Install Flutter

#### Windows:
1. Download Flutter SDK: https://docs.flutter.dev/get-started/install/windows
2. Extract to `C:\src\flutter` (or your preferred location)
3. Add Flutter to PATH:
   - Search "Environment Variables" in Windows
   - Edit "Path" under System Variables
   - Add `C:\src\flutter\bin`
4. Verify installation:
   ```bash
   flutter doctor
   ```

#### macOS:
1. Download Flutter SDK: https://docs.flutter.dev/get-started/install/macos
2. Extract to a location like `~/development/flutter`
3. Add to PATH by editing `~/.zshrc` or `~/.bash_profile`:
   ```bash
   export PATH="$PATH:$HOME/development/flutter/bin"
   ```
4. Reload terminal and verify:
   ```bash
   source ~/.zshrc  # or ~/.bash_profile
   flutter doctor
   ```

### 2. Verify Flutter Installation

Run Flutter doctor to check everything is set up:
```bash
flutter doctor
```

You should see checkmarks (✓) for:
- Flutter SDK
- Chrome (for web development)

---

## 📦 Clone and Run the Project

### 1. Clone the Repository

```bash
# Clone the repo
git clone https://github.com/jkusuda/meeteor.git

# Navigate into project
cd meeteor
```

### 2. Install Dependencies

```bash
# Get all Flutter packages
flutter pub get
```

### 3. Configure Environment Variables

Create a `.env` file in the root directory and add your Supabase credentials:

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

*(You can find these in your Supabase project settings under API).*

### 4. Run the App (Web Development)

Default development for this project is done using the Flutter web server.

```bash
# Run web server locally
flutter run -d web-server --web-port=8080
```

Open your browser and navigate to `http://localhost:8080`.

**Hot reload during development:**
- Press `r` in the terminal to hot restart
- Press `q` to quit

---

## 📁 Project Structure

```text
meeteor/
│
├── lib/                             # Main Flutter code folder
│   │
│   ├── main.dart                   # App entry point + Supabase init
│   │
│   ├── services/                   # Backend services
│   │   ├── auth_service.dart       # Supabase auth operations
│   │   └── auth_gate.dart          # Session verification router
│   │
│   ├── screens/                    # UI Screens (one file per page)
│   │   ├── home.dart               # Main feed and challenges
│   │   ├── profile.dart            # User profile and demo mode toggling
│   │   ├── login.dart              # Authentication screen
│   │   └── nav_wrapper.dart        # Bottom navigation bar
│   │
│   └── widgets/                    # Reusable UI components
│       ├── post_card.dart          # Modular feed post component
│       └── challenge_card.dart     # Modular daily challenge component
│
├── .env                            # Environment variables (not tracked in git)
├── pubspec.yaml                    # Dependencies & assets
└── README.md                       # This file
```

### 📄 File Descriptions

#### `main.dart`
- App entry point
- Loads environment variables
- Initializes Supabase client
- Sets up app theme and routes to `AuthGate`

#### `services/auth_service.dart`
- Single file for Supabase auth operations
- Handles signIn, signUp, and signOut securely via the Supabase client

#### `services/auth_gate.dart`
- Listens to the Supabase authentication stream
- Safely routes users to either the `LoginScreen` or the protected `NavWrapper` preventing unauthorized access

#### `screens/home.dart`
- The core feed fetching dynamic `posts` and joining the `users` table via native Supabase Joins (`.select('*, users(username)')`).
- Renders the daily challenges UI

#### `widgets/`
- Modular, React-style stateless components for rendering UI logic cleanly and flexibly across screens, improving readability natively inside the `screens` directory.

---

## 👥 Git Workflow

### Branching Strategy

```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Make changes and commit
git add .
git commit -m "Add feature description"

# Push to remote
git push origin feature/your-feature-name

# Create Pull Request on GitHub for review
```

### Before Pushing Code

```bash
# Format code
dart format .

# Check for issues
flutter analyze
```

---

## 🐛 Common Issues & Fixes

### "Flutter command not found"
- Make sure Flutter is added to your PATH
- Restart terminal after adding to PATH

### Missing `.env` file
- If you see an error regarding `dotenv` or Supabase missing keys, ensure you have created the `.env` file with `SUPABASE_URL` and `SUPABASE_ANON_KEY` in the root of the project.

### Dependencies not installing
```bash
# Clean and reinstall
flutter clean
flutter pub get
```

---

## 📚 Useful Documentation

### Flutter
- [Flutter Docs](https://docs.flutter.dev/) - Official documentation
- [Flutter Widget Catalog](https://docs.flutter.dev/ui/widgets) - Browse available UI components

### Supabase
- [Supabase Flutter Quickstart](https://supabase.com/docs/guides/getting-started/tutorials/with-flutter) - Setting up Supabase
- [Supabase Auth](https://supabase.com/docs/guides/auth) - Authentication guide
- [Supabase Database](https://supabase.com/docs/guides/database) - PostgreSQL interactions