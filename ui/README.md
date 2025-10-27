# EchoNote

A live transcription and translation Flutter app with real-time audio processing.

## Features

- 🎤 Live audio recording with 5-second chunks
- 🌍 Real-time transcription and translation
- 🔐 User authentication (Sign in/Sign up)
- 📝 Session management
- 🎯 Supports French, English, and Portuguese

## Setup

1. Install Flutter SDK (https://flutter.dev/docs/get-started/install)

2. Clone the repository:
```bash
git clone https://github.com/Edgar4505/EchoNote.git
cd EchoNote
```

3. Install dependencies:
```bash
flutter pub get
```

4. Create a `.env` file from `.env.example`:
```bash
cp .env.example .env
```

5. Update the `.env` file with your API URL:
```
API_BASE_URL=http://your-api-url:8000
```

6. Run the app:
```bash
flutter run
```

## Supported Languages

- French (fr) - Default source language
- English (en) - Default target language
- Portuguese (pt)

## API Integration

This app connects to a FastAPI backend for:
- Authentication (`/auth/signin`, `/auth/signup`)
- WebSocket transcription (`/ws/{client_id}`)

## Architecture

- **Services**: API calls, WebSocket connections, audio recording
- **Providers**: State management for authentication and transcription
- **Screens**: Sign In, Sign Up, Live Translate (idle & recording)
- **Widgets**: Reusable UI components

## License

MIT
