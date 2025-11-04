# Study Sync Project

website link: https://jettoner.xyz/

This is a Node.js backend project using Express and MongoDB.

## Author

Tochi

# CI/CD Pipeline Active ���

# 📚 StudySync - Collaborative Study Platform

> Connect with study partners worldwide and boost your productivity through focused study sessions

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Vue 3](https://img.shields.io/badge/Vue-3.x-brightgreen.svg)](https://vuejs.org/)
[![Socket.io](https://img.shields.io/badge/Socket.io-4.x-black.svg)](https://socket.io/)

## 🌟 Overview

StudySync is a real-time collaborative study platform that pairs students together for focused study sessions. Using intelligent matching algorithms and live chat functionality, StudySync helps students stay accountable, motivated, and productive during their study time.

## ✨ Features

### 🤝 Smart Pairing System

- **Real-time matching** - Get paired with study partners instantly
- **Flexible session lengths** - Choose from 25, 50, or 90-minute sessions
- **Waiting pool** - Join a queue and get notified when a partner is found
- **Cancel anytime** - Exit the matching queue before being paired

### 💬 Live Chat Interface

- **Real-time messaging** - Chat with your study partner during sessions
- **Typing indicators** - See when your partner is typing
- **Message history** - View all messages within your session
- **Clean UI** - Distraction-free chat interface

### ⏱️ Session Management

- **Live countdown timer** - Track remaining study time
- **Session warnings** - Get notified when time is running low
- **Session recovery** - Rejoin active sessions after page refresh
- **Background sessions** - Sessions continue even if you navigate away
- **Completion tracking** - Monitor finished and incomplete sessions

### 🎨 User Experience

- **Responsive design** - Works on desktop, tablet, and mobile
- **Dark mode support** - Easy on the eyes during late-night study sessions
- **Session badges** - Visual indicator of active sessions
- **Confirmation dialogs** - Prevent accidental session exits

## 🛠️ Tech Stack

### Frontend

- **Vue 3** - Progressive JavaScript framework with Composition API
- **Socket.io-client** - Real-time bidirectional communication
- **Axios** - HTTP client for API requests
- **Lucide Vue** - Beautiful icon library
- **Vue Router** - Client-side routing

### Backend (Required)

- **Node.js & Express** - Server framework
- **Socket.io** - WebSocket server for real-time features
- **MongoDB** - Database for session and user data
- **JWT** - Authentication tokens

## 📦 Installation

### Prerequisites

- Node.js (v16 or higher)
- npm or yarn
- MongoDB instance
- Backend API server running

### Frontend Setup

1. **Clone the repository**

```bash
git clone https://github.com/yourusername/studysync.git
cd studysync
```

2. **Install dependencies**

```bash
npm install
```

3. **Configure environment variables**
   Create a `src/config.js` file:

```javascript
export const API_BASE_URL = "http://localhost:5000";
export const SOCKET_URL = "http://localhost:5000";
```

4. **Run development server**

```bash
npm run dev
```

5. **Build for production**

```bash
npm run build
```

## 🔧 Configuration

### Required Environment Variables

**Frontend (`src/config.js`):**

```javascript
export const API_BASE_URL = "your-api-url";
export const SOCKET_URL = "your-socket-server-url";
```

**Backend Environment Variables:**

- `PORT` - Server port (default: 5000)
- `MONGODB_URI` - MongoDB connection string
- `JWT_SECRET` - Secret key for JWT tokens
- `CORS_ORIGIN` - Allowed frontend origins

## 📡 API Endpoints

### Authentication

```
POST   /api/auth/register     - Register new user
POST   /api/auth/login        - Login user
GET    /api/auth/verify       - Verify JWT token
```

### Sessions

```
POST   /api/sessions/pair            - Request study partner
GET    /api/sessions/:id             - Get session details
PUT    /api/sessions/:id/end         - End session
DELETE /api/sessions/:id/cancel      - Cancel pending session
GET    /api/sessions/user/:userId    - Get user's session history
```

## 🔌 Socket Events

### Client → Server

- `join_user` - Register user with socket
- `join_session` - Join a study session room
- `send_message` - Send chat message
- `typing` - Broadcast typing status

### Server → Client

- `partner_found` - Notify when match is found
- `timer_update` - Real-time timer updates
- `timer_warning` - Warning before session ends
- `session_completed` - Session finished successfully
- `session_ended` - Session ended early
- `receive_message` - New chat message
- `user_typing` - Partner typing indicator
- `error` - Error notifications

## 🎯 Usage Flow

1. **Login/Register** - Create an account or sign in
2. **Select Duration** - Choose study session length (25/50/90 min)
3. **Find Partner** - Click "Find Study Partner" to join matching pool
4. **Wait for Match** - System finds another user with same duration
5. **Start Session** - Chat opens with countdown timer
6. **Study & Chat** - Communicate with partner during session
7. **Complete** - Session ends automatically or can be ended early

## 📱 Component Structure

```
src/
├── components/
│   ├── StudySync.vue         # Main session component
│   ├── Navbar.vue            # Navigation bar
│   └── SessionBadge.vue      # Active session indicator
├── views/
│   ├── Home.vue              # Landing page
│   ├── Login.vue             # Authentication
│   └── Dashboard.vue         # User dashboard
├── config.js                 # API configuration
└── App.vue                   # Root component
```

## 🚀 Key Features Implementation

### Session Recovery

Sessions are stored in localStorage and automatically recovered on page reload:

```javascript
localStorage.setItem("activeSessionId", sessionId);
// On mount: reconnect if session exists
```

### Real-time Synchronization

Timer and messages sync across all clients via Socket.io:

```javascript
socket.on("timer_update", (data) => {
  remainingTime.value = data.remainingTime;
});
```

### Navigation Protection

Prevents accidental navigation during active sessions:

```javascript
onBeforeRouteLeave((to, from, next) => {
  if (activeSession.value) {
    const confirm = window.confirm("Leave active session?");
    next(confirm);
  }
});
```

## 🎨 Theming

The app supports light/dark mode and uses CSS custom properties:

```css
--primary-color: #6366f1;
--secondary-color: #34dc3b;
--background: #f8f9fa;
--color-text: #2c3e50;
```

## 🐛 Troubleshooting

### Common Issues

**Socket connection fails:**

- Verify SOCKET_URL in config
- Check backend server is running
- Ensure CORS is properly configured

**Timer not syncing:**

- Check active session state
- Verify socket event listeners
- Review browser console for errors

**Session not recovering:**

- Check localStorage permissions
- Verify sessionId is being stored
- Ensure backend session still exists

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Tochukwu Ezechykwy** - _Initial work_ - [@kelvtm](https://github.com/yourusername)

## 🙏 Acknowledgments

- Icons by [Lucide](https://lucide.dev/)
- Inspiration from Pomodoro technique
- Study community feedback

## 📞 Support

- 📧 Email: support@kelvtmoni@gmail.com
- 💬 Discord: [Join our server](https://discord.gg/studysync)
- 🐛 Issues: [GitHub Issues](https://github.com/kelvtm/studysync)

---

**Made with ❤️ by students, for students**
