import express from "express";
import mongoose from "mongoose";
import cors from "cors";
import path from "path";
import { fileURLToPath } from "url";
import dotenv from "dotenv";
import { createServer } from "http";
import { Server } from "socket.io";
import bcrypt from "bcryptjs"; // Uses pure JS implementation
// Import models and routes
import sessionRoutes from "./routes/sessionRoutes.js";
import User from "./db-models/user.js";
import Session from "./db-models/sessions.js";

// Import course routes
import courseRoutes from "./routes/courseRoutes.js";
import subtaskRoutes from "./routes/subtaskRoutes.js";
import notificationRoutes from "./routes/notificationRoutes.js";
import Notification from "./db-models/notification.js";

import Course from "./db-models/course.js";
import Stage from "./db-models/stage.js";
import Subtask from "./db-models/subtask.js";

// Import metrics utilities
import metricsRegister, {
  metricsMiddleware,
  updateSocketConnections,
  incrementSocketMessages,
  updateActiveStudySessions,
  incrementUserRegistrations,
  updateMongoStatus,
} from "./metrics.js";

dotenv.config();
const app = express();
const httpServer = createServer(app);
const PORT = process.env.PORT || 3000;
const MONGO_URI = process.env.MONGO_URI;

// --- Middleware ---
app.use(express.json());
app.use(
  cors({
    origin: (origin, callback) => {
      const allowedOrigins = [
        "http://localhost:5173",
        "http://localhost", // Dev: Nginx proxy
        "http://localhost:80", // Dev: Nginx proxy
        "https://jettoner.xyz",
        "http://jettoner.xyz",
      ];
      if (!origin || allowedOrigins.includes(origin)) {
        return callback(null, true);
      }
      return callback(null, false);
    },
    credentials: true,
  })
);
// Metrics endpoint
app.use(metricsMiddleware);

// --- MongoDB ---
async function connectDB() {
  try {
    await mongoose.connect(MONGO_URI);
    const dbName = mongoose.connection.name;
    console.log(`✅ Connected to MongoDB`);
    console.log(`   Environment: ${process.env.NODE_ENV || "development"}`);
    console.log(`   Database: ${dbName}`);
    console.log(
      `   URI: ${MONGO_URI.replace(/\/\/[^:]+:[^@]+@/, "//***:***@")}`
    ); // Hide credentials

    // Update MongoDB connection metric
    updateMongoStatus(true);

    // Monitor connection events
    mongoose.connection.on("disconnected", () => {
      console.log("❌ MongoDB disconnected");
      updateMongoStatus(false);
    });

    mongoose.connection.on("reconnected", () => {
      console.log("✅ MongoDB reconnected");
      updateMongoStatus(true);
    });
  } catch (err) {
    console.error("❌ MongoDB connection error:", err);
    process.exit(1);
  }
}
connectDB();

app.use("/api/sessions", sessionRoutes);
app.use("/api/courses", courseRoutes);
app.use("/api/subtasks", subtaskRoutes);
app.use("/api/notifications", notificationRoutes);

// --- Routes ---
app.get("/api/health", (req, res) => res.json({ status: "ok" }));
// This exposes the /metrics endpoint that Prometheus will scrape

// --- Metrics endpoint ---
app.get("/metrics", async (req, res) => {
  try {
    res.set("Content-Type", metricsRegister.contentType);
    const metrics = await metricsRegister.metrics();
    res.end(metrics);
  } catch (err) {
    res.status(500).end(err);
  }
});

// ⭐ UPDATED Login route with bcrypt - supports email OR username
app.post("/api/login", async (req, res) => {
  const { email, password } = req.body;

  try {
    // Find user by email OR username
    const user = await User.findOne({
      $or: [
        { email: email },
        { username: email }, // 'email' field can contain username too
      ],
    });

    if (!user) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    // Compare password with hashed password
    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    // Success
    res.json({
      message: "Login successful!",
      user: {
        id: user._id,
        email: user.email,
        username: user.username,
      },
    });
  } catch (err) {
    console.error("Login error:", err);
    res.status(500).json({ message: "Server error during login" });
  }
});

// ⭐ UPDATED Signup route with bcrypt
app.post("/api/signup", async (req, res) => {
  const { email, password, username } = req.body;

  try {
    // Validate input
    if (!username || username.trim().length < 3) {
      return res
        .status(400)
        .json({ message: "Username must be at least 3 characters" });
    }

    if (!password || password.length < 6) {
      return res
        .status(400)
        .json({ message: "Password must be at least 6 characters" });
    }

    // Check if user already exists
    const existingEmail = await User.findOne({ email });
    if (existingEmail) {
      return res.status(400).json({ message: "Email already exists" });
    }

    const existingUsername = await User.findOne({ username: username.trim() });
    if (existingUsername) {
      return res.status(400).json({ message: "Username already taken" });
    }

    // Hash the password (10 salt rounds is the standard)
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create new user with hashed password
    const newUser = new User({
      email,
      password: hashedPassword, // Store hashed password
      username: username.trim(),
    });

    await newUser.save();
    incrementUserRegistrations(); // Track registration

    res.status(201).json({
      message: "Account created successfully",
      user: {
        id: newUser._id,
        email: newUser.email,
        username: newUser.username,
      },
    });
  } catch (err) {
    console.error("Signup error:", err);
    res.status(500).json({ message: "Server error during signup" });
  }
});

// Get user stats route
app.get("/api/users/:userId/stats", async (req, res) => {
  try {
    const { userId } = req.params;
    const user = await User.findById(userId).select("-password");

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json({
      stats: {
        totalStudyMinutes: user.totalStudyMinutes,
        completedSessions: user.completedSessions,
        quitSessions: user.quitSessions,
        disconnectedSessions: user.disconnectedSessions,
        longestSession: user.longestSession,
        currentStreak: user.currentStreak,
        lastStudyDate: user.lastStudyDate,
        weeklyStudyMinutes: user.weeklyStudyMinutes,
        weeklyCompletedSessions: user.weeklyCompletedSessions,
      },
      user: {
        username: user.username,
        email: user.email,
        createdAt: user.createdAt,
      },
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Get leaderboard route
app.get("/api/leaderboard", async (req, res) => {
  try {
    const oneWeekAgo = new Date();
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);

    await User.updateMany(
      { lastWeekReset: { $lt: oneWeekAgo } },
      {
        $set: {
          weeklyStudyMinutes: 0,
          weeklyCompletedSessions: 0,
          lastWeekReset: new Date(),
        },
      }
    );

    const topUsers = await User.find({
      weeklyCompletedSessions: { $gte: 1 },
    })
      .select(
        "username weeklyStudyMinutes weeklyCompletedSessions totalStudyMinutes"
      )
      .sort({ weeklyStudyMinutes: -1 })
      .limit(50);

    res.json({
      leaderboard: topUsers.map((user, index) => ({
        rank: index + 1,
        username: user.username,
        weeklyStudyMinutes: user.weeklyStudyMinutes,
        weeklyCompletedSessions: user.weeklyCompletedSessions,
        totalStudyMinutes: user.totalStudyMinutes,
        badge: index < 3 ? ["Gold", "Silver", "Bronze"][index] : null,
      })),
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Update static serving logic for microservices
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// In microservices, backend NEVER serves frontend
// Frontend is served by separate Nginx container
if (
  process.env.NODE_ENV !== "production" ||
  process.env.MICROSERVICES === "true"
) {
  app.get("/", (req, res) =>
    res.json({
      message: "StudySync API",
      version: "2.0.0",
      architecture: "microservices",
    })
  );
} else {
  // Fallback for Pattern 1 (monolithic)
  const distPath = path.join(__dirname, "dist");
  app.use(express.static(distPath));
  app.use((req, res) => {
    res.sendFile(path.join(distPath, "index.html"));
  });
}

// --- Error handler ---
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: err.message || "Internal server error" });
});

// --- Socket.IO setup ---
const io = new Server(httpServer, {
  cors: {
    origin: [
      "http://localhost:5173",
      "http://localhost", // Dev: Nginx proxy
      "http://localhost:80", // Dev: Nginx proxy
      "https://jettoner.xyz",
      "http://jettoner.xyz",
    ],
    methods: ["GET", "POST"],
    credentials: true,
  },
});

const userSockets = new Map();
let socketConnectionCount = 0;

io.on("connection", (socket) => {
  socketConnectionCount++;
  updateSocketConnections(socketConnectionCount); // 🆕 Update metric
  console.log(
    `🔌 User connected: ${socket.id} (Total: ${socketConnectionCount})`
  );

  socket.on("join_user", (userId) => {
    userSockets.set(userId, socket.id);
    console.log(`👤 User ${userId} mapped to socket ${socket.id}`);
  });

  socket.on("join_session", async (data) => {
    const { sessionId, userId } = data;

    incrementSocketMessages("join_session"); // 🆕 Track event

    try {
      const session = await Session.findById(sessionId);
      if (!session || !session.participants.includes(userId)) {
        socket.emit("error", "Not authorized to join this session");
        return;
      }

      socket.join(`session_${sessionId}`);
      console.log(
        `👥 User ${userId} joined session room: session_${sessionId}`
      );

      // 🆕 Update active sessions count
      await updateActiveStudySessions(Session);

      socket.to(`session_${sessionId}`).emit("user_joined", {
        message: "Your study partner has joined!",
        userId,
      });

      socket.emit("joined_session", {
        sessionId,
        message: "Successfully joined study session",
      });
    } catch (error) {
      console.error("Error joining session:", error);
      socket.emit("error", "Failed to join session");
    }
  });

  socket.on("leave_session", async (data) => {
    const { sessionId, userId } = data;

    incrementSocketMessages("leave_session"); // 🆕 Track event
    console.log(`👋 User ${userId} leaving session: ${sessionId}`);

    try {
      socket.leave(`session_${sessionId}`);

      // 🆕 Update active sessions count
      await updateActiveStudySessions(Session);

      socket.to(`session_${sessionId}`).emit("partner_left", {
        userId,
        message: "Your study partner has left the session",
      });

      console.log(`✅ User ${userId} left session room: session_${sessionId}`);
    } catch (error) {
      console.error("Error leaving session:", error);
    }
  });

  socket.on("send_message", async (data) => {
    const { sessionId, userId, message, timestamp } = data;

    incrementSocketMessages("send_message"); // 🆕 Track event

    try {
      const session = await Session.findById(sessionId);
      if (!session || !session.participants.includes(userId)) {
        socket.emit("error", "Not authorized to send messages in this session");
        return;
      }

      const user = await User.findById(userId);

      const messageData = {
        sessionId,
        userId,
        userEmail: user.email,
        message,
        timestamp: timestamp || new Date().toISOString(),
      };

      io.to(`session_${sessionId}`).emit("receive_message", messageData);

      console.log(`💬 Message in session ${sessionId}: ${message}`);
    } catch (error) {
      console.error("Error sending message:", error);
      socket.emit("error", "Failed to send message");
    }
  });

  socket.on("typing", (data) => {
    const { sessionId, userId, isTyping } = data;
    incrementSocketMessages("typing"); // 🆕 Track event
    socket.to(`session_${sessionId}`).emit("user_typing", { userId, isTyping });
  });

  socket.on("disconnect", async () => {
    socketConnectionCount--;
    updateSocketConnections(socketConnectionCount); // 🆕 Update metric
    console.log(
      `❌ User disconnected: ${socket.id} (Total: ${socketConnectionCount})`
    );

    let disconnectedUserId = null;
    for (const [userId, socketId] of userSockets.entries()) {
      if (socketId === socket.id) {
        disconnectedUserId = userId;
        userSockets.delete(userId);
        break;
      }
    }

    if (disconnectedUserId) {
      try {
        const activeSession = await Session.findOne({
          participants: disconnectedUserId,
          status: "active",
        });

        if (activeSession) {
          console.log(
            `⚠️  User ${disconnectedUserId} disconnected from active session ${activeSession._id}`
          );

          socket
            .to(`session_${activeSession._id}`)
            .emit("partner_disconnected", {
              userId: disconnectedUserId,
              message:
                "Your study partner disconnected. Session will continue...",
            });
        }
      } catch (error) {
        console.error("Error handling disconnect:", error);
      }
    }
  });
});

app.set("io", io);

httpServer.listen(PORT, () =>
  console.log(`🚀 Server + Socket.IO listening on http://localhost:${PORT}`)
);
