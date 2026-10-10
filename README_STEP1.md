# Drift Stack – Step 1

1. `flutter create --org com.driftstack --project-name drift_stack .`
2. Copy these files over the generated project (overwrite).
   If the generated project has `android/app/build.gradle.kts`, delete it - this
   package uses the Groovy `android/app/build.gradle`.
3. Put fonts in assets/fonts (see list in pubspec.yaml).
4. `python3 tools/generate_sounds.py`
5. `flutter pub get`
