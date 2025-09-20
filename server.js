import express from "express";
import mongoose from "mongoose";
import cors from "cors";
import path from "path";
import { fileURLToPath } from "url";
import dotenv from "dotenv";
import { createServer } from "http";
import { Server } from "socket.io";

// Load environment variables from .env file
dotenv.config();
const app = express();
const httpServer = createServer(app);
const PORT = process.env.PORT || 3000;
const MONGO_URI = process.env.MONGO_URI;
const VUE_DEV_ORIGIN = "http://localhost:5173";

// --- Middleware ---
app.use(express.json());
app.use(
  cors({
    origin: (origin, callback) => {
      if (!origin || origin === VUE_DEV_ORIGIN) return callback(null, true);
      if (process.env.ALLOWED_ORIGIN && origin === process.env.ALLOWED_ORIGIN)
        return callback(null, true);
      return callback(null, false);
    },
    credentials: true,
  })
);

// --- MongoDB ---
async function connectDB() {
  try {
    await mongoose.connect(MONGO_URI);
    console.log("✅ Connected to MongoDB");
  } catch (err) {
    console.error("❌ MongoDB connection error:", err);
    process.exit(1);
  }
}
connectDB();

// Import models and routes
import sessionRoutes from "./routes/sessionRoutes.js";
import User from "./db-models/user.js";
import Session from "./db-models/sessions.js";

app.use("/api/sessions", sessionRoutes);

// --- Routes ---
app.get("/api/health", (req, res) => res.json({ status: "ok" }));

// Login route
app.post("/login", async (req, res) => {
  const { email, password } = req.body;
  try {
    const user = await User.findOne({ email });
    if (!user) return res.status(401).json({ message: "User not found" });
    if (user.password !== password)
      return res.status(401).json({ message: "Incorrect password" });
    res.json({
      message: "Login successful!",
      user: {
        id: user._id,
        email: user.email,
      },
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /signup route
app.post("/signup", async (req, res) => {
  const { email, password } = req.body;
  try {
    const existing = await User.findOne({ email });
    if (existing) {
      return res.status(400).json({ message: "User already exists" });
    }

    const newUser = new User({ email, password });
    await newUser.save();

    res.status(201).json({
      message: "Account created successfully",
      user: {
        id: newUser._id,
        email: newUser.email,
      },
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// --- Serve Vue in production ---
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const distPath = path.join(__dirname, "dist");

if (process.env.NODE_ENV === "production") {
  app.use(express.static(distPath));
  app.get("/*", (req, res) => res.sendFile(path.join(distPath, "index.html")));
} else {
  app.get("/", (req, res) =>
    res.send(`Backend running. Use Vue dev server at ${VUE_DEV_ORIGIN}`)
  );
}

// --- Error handler ---
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: err.message || "Internal server error" });
});

// --- Socket.IO setup with Room Management ---
const io = new Server(httpServer, {
  cors: {
    origin: VUE_DEV_ORIGIN,
    methods: ["GET", "POST"],
  },
});

// Store user-socket mapping
const userSockets = new Map();

io.on("connection", (socket) => {
  console.log(`🔌 User connected: ${socket.id}`);

  // User joins with their userId
  socket.on("join_user", (userId) => {
    userSockets.set(userId, socket.id);
    console.log(`👤 User ${userId} mapped to socket ${socket.id}`);
  });

  // User joins a session room
  socket.on("join_session", async (data) => {
    const { sessionId, userId } = data;

    try {
      // Verify user is part of this session
      const session = await Session.findById(sessionId);
      if (!session || !session.participants.includes(userId)) {
        socket.emit("error", "Not authorized to join this session");
        return;
      }

      // Join the room
      socket.join(`session_${sessionId}`);
      console.log(
        `👥 User ${userId} joined session room: session_${sessionId}`
      );

      // Notify others in the room
      socket.to(`session_${sessionId}`).emit("user_joined", {
        message: "Your study partner has joined!",
        userId,
      });

      // Send confirmation to the user
      socket.emit("joined_session", {
        sessionId,
        message: "Successfully joined study session",
      });
    } catch (error) {
      console.error("Error joining session:", error);
      socket.emit("error", "Failed to join session");
    }
  });

  // Handle chat messages
  socket.on("send_message", async (data) => {
    const { sessionId, userId, message, timestamp } = data;

    try {
      // Verify user is part of this session
      const session = await Session.findById(sessionId);
      if (!session || !session.participants.includes(userId)) {
        socket.emit("error", "Not authorized to send messages in this session");
        return;
      }

      // Get user details for the message
      const user = await User.findById(userId);

      const messageData = {
        sessionId,
        userId,
        userEmail: user.email,
        message,
        timestamp: timestamp || new Date().toISOString(),
      };

      // Broadcast to all users in this session room
      io.to(`session_${sessionId}`).emit("receive_message", messageData);

      console.log(`💬 Message in session ${sessionId}: ${message}`);
    } catch (error) {
      console.error("Error sending message:", error);
      socket.emit("error", "Failed to send message");
    }
  });

  // Handle typing indicators
  socket.on("typing", (data) => {
    const { sessionId, userId, isTyping } = data;
    socket.to(`session_${sessionId}`).emit("user_typing", { userId, isTyping });
  });

  // Handle disconnection
  socket.on("disconnect", () => {
    console.log(`❌ User disconnected: ${socket.id}`);
    // Remove from userSockets map
    for (const [userId, socketId] of userSockets.entries()) {
      if (socketId === socket.id) {
        userSockets.delete(userId);
        break;
      }
    }
  });
});

// Make io accessible to routes
app.set("io", io);

// --- Start server ---
httpServer.listen(PORT, () =>
  console.log(`🚀 Server + Socket.IO listening on http://localhost:${PORT}`)
);
