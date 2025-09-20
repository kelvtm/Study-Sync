import express from "express";
import mongoose from "mongoose";
import cors from "cors";
import path from "path";
import { fileURLToPath } from "url";
import dotenv from "dotenv";
import { createServer } from "http"; // (if needed for Socket.IO)
import { Server } from "socket.io"; // (if needed for Socket.IO)

// Load environment variables from .env file
dotenv.config();
const app = express();
const httpServer = createServer(app); // wrap express with http
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

// Session routes
import sessionRoutes from "./routes/sessionRoutes.js";
//import User model for auth routes
import User from "./db-models/user.js";
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
    res.json({ message: "Login successful!" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /signup route
app.post("/signup", async (req, res) => {
  const { email, password } = req.body;
  try {
    // check if user already exists
    const existing = await User.findOne({ email });
    if (existing) {
      return res.status(400).json({ message: "User already exists" });
    }

    const newUser = new User({ email, password });
    await newUser.save();

    res.status(201).json({ message: "Account created successfully" });
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

// --- Socket.IO setup ---
const io = new Server(httpServer, {
  cors: {
    origin: VUE_DEV_ORIGIN, // allow frontend dev server
    methods: ["GET", "POST"],
  },
});

io.on("connection", (socket) => {
  console.log(`🔌 User connected: ${socket.id}`);

  // listen for test messages
  socket.on("chat message", (msg) => {
    console.log("💬 Message received:", msg);
    io.emit("chat message", msg); // broadcast to everyone
  });

  socket.on("disconnect", () => {
    console.log(`❌ User disconnected: ${socket.id}`);
  });
});

// --- Start server ---
httpServer.listen(PORT, () =>
  console.log(`🚀  Server + Socket.IO  listening on http://localhost:${PORT}`)
);
