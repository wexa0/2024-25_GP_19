
<div align="center">
  <img src="https://github.com/user-attachments/assets/ec3b0e50-de4c-44ae-9b74-9eba18cea4c7" alt="AttentionLens Diagram" width="500" height="300">
</div>

---

# AttentionLens Application
---

## Introduction
AttentionLens is an Android mobile application designed to assist adults with Attention Deficit Hyperactivity Disorder (ADHD) in managing their symptoms. By leveraging AI-powered chatbot technology and user-friendly task management tools, the app aims to simplify daily routines, improve focus, and boost productivity.

### Goals:
- Provide adults with ADHD tools to manage tasks, set goals, and monitor their progress.
- Implement a chatbot powered by OpenAI to assist users in breaking down complex tasks, setting reminders, and receiving personalized support.
- Offer features such as task lists, timers, visual progress tracking, and more.

---

##  Technology Stack
- **Programming Language:** Dart (via Flutter)
- **Framework:** Flutter (cross-platform development)
- **Database:** Firebase
- **Cloud Services:** Firebase for backend services
- **AI Model:** OpenAI GPT-based chatbot, fine-tuned for ADHD support
- **Version Control:** GitHub
- **Project Management:** Jira
- **UI/UX Design:** Figma

---

## Launching Instructions

### Launching Instructions for AttentionLens

1. **Clone the Repository**
   - Open the Command Prompt or Terminal.
   - Clone the project to your local machine by using the following command and specifying the correct path:

     ```bash
     git clone https://github.com/username/attentionlens.git "C:\Users\wexa0\OneDrive\Documents\GitHub\AttensionLens-App"
     cd "C:\Users\wexa0\OneDrive\Documents\GitHub\AttensionLens-App"
     ```

   **Note:** Replace `"username"` with your GitHub username.

2. **Install Prerequisites**
   - Ensure you have installed [Flutter](https://flutter.dev/docs/get-started/install), [Dart](https://dart.dev/get-dart), and [Android Studio](https://developer.android.com/studio).
   - Add Flutter and Dart to your system path.
   - Have an Android device with Developer Mode enabled or an Android emulator running via Android Studio.

3. **Install Dependencies**
   - In the project directory, run the following command to fetch all necessary packages:

     ```bash
     flutter pub get
     ```

4. **Run the App**
   - To launch the app on an Android device or emulator, use:

     ```bash
     flutter run
     ```

5. **Build for Release**
   - To build a release version for Android, use:

     ```bash
     flutter build apk
     ```

---

### Troubleshooting

- **Flutter and Dart not found**: Ensure both Flutter and Dart are installed and added to your system path. Verify by running:
  ```bash
  flutter --version
  dart --version



