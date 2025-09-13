import express from "express";
import mongoose from "mongoose";
import cors from "cors";
import path from "path";
import { fileURLToPath } from "url";
import dotenv from "dotenv";

dotenv.config();
const app = express();
const PORT = process.env.PORT || 3000;
const MONGO_URI = process.env.MONGO_URI;
const VUE_DEV_ORIGIN = "http://localhost:5173";

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

// --- Models ---
const noteSchema = new mongoose.Schema({
  title: { type: String, required: true },
  body: String,
  createdAt: { type: Date, default: Date.now },
});
const Note = mongoose.model("Note", noteSchema);

const userSchema = new mongoose.Schema(
  {
    email: { type: String, required: true },
    password: { type: String, required: true },
  },
  { collection: "users" }
);
const User = mongoose.model("User", userSchema);

// --- Routes ---
app.get("/api/health", (req, res) => res.json({ status: "ok" }));

app.get("/api/notes", async (req, res) => {
  try {
    const notes = await Note.find().sort({ createdAt: -1 });
    res.json(notes);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/api/notes", async (req, res) => {
  try {
    const note = new Note(req.body);
    await note.save();
    res.status(201).json(note);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.delete("/api/notes/:id", async (req, res) => {
  try {
    await Note.findByIdAndDelete(req.params.id);
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

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

// --- Start server ---
app.listen(PORT, () =>
  console.log(`🚀 Server listening on http://localhost:${PORT}`)
);
