# Pawsitive Care App 
A Flutter app for pet wellness. 
 
## Prerequisites 
- [Flutter](https://flutter.dev/docs/get-started/install) (latest stable version) 
- [Git](https://git-scm.com/downloads) 
- An IDE like [VS Code](https://code.visualstudio.com/) or [Android Studio](https://developer.android.com/studio) 
 
## Setup Instructions 
1. **Clone the Repository**: 
   ```bash 
   git clone https://github.com/AtifAnsari0345/pet_wellness_app.git 
   cd pet_wellness_app 
   ``` 
2. **Install Dependencies**: 
   ```bash 
   flutter pub get 
   ``` 
   This fetches all required packages listed in `pubspec.yaml`. 
3. **Generate Build Files**: 
   ```bash 
   flutter clean 
   flutter pub get 
   ``` 
   This ensures a clean slate and regenerates necessary files. 
4. **Run the App**: 
   - Connect a device or start an emulator. 
   - Then run: 
     ```bash 
     flutter run 
     ``` 
   This builds and launches the app in debug mode. 
 
## Building for Release 
To create a release APK: 
```bash 
flutter build apk --release 
``` 
The APK will be in `build\app\outputs\flutter-apk\app-release.apk`. 
