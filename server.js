require("dotenv").config();
const express = require("express");
const mongoose = require("mongoose");

const app = express();
const PORT = process.env.PORT || 5000;

// Serve static files from Vue build
app.use(express.static(path.join(__dirname, "vue-project", "dist")));

// Fallback: serve index.html for SPA routes (except API and special routes)
app.get(/^\/(?!api|login|test|login-page).*/, (req, res) => {
  res.sendFile(path.join(__dirname, "vue-project", "dist", "index.html"));
});

console.log("Loaded MONGO_URI:", process.env.MONGO_URI); // Debugging line

// Connect to MongoDB
mongoose
  .connect(process.env.MONGO_URI) // ✅ no need for extra options
  .then(() => console.log("✅ MongoDB Atlas connected"))
  .catch((err) => console.error("❌ MongoDB connection error:", err));
// ...existing code...
const bodyParser = require("body-parser");
app.use(bodyParser.json());

// Example User model (replace with your actual model)
const userSchema = new mongoose.Schema({
  email: String,
  password: String,
});
const User = mongoose.model("User", userSchema);

// Login route
app.post("/login", async (req, res) => {
  const { email, password } = req.body;
  try {
    const user = await User.findOne({ email, password });
    if (user) {
      res.json({ message: "Login successful", user });
    } else {
      res.status(401).json({ message: "Invalid credentials" });
    }
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err });
  }
});
// ...existing code...

// ...existing code...

const path = require("path");

// Serve login.html at /login-page
app.get("/login-page", (req, res) => {
  res.sendFile(path.join(__dirname, "login.html"));
});

// ...existing code...

app.get("/", (req, res) => {
  res.send("Study Sync backend is running 🚀");
});

// ...existing code...

app.get("/test", async (req, res) => {
  // Try to fetch all users from the database
  try {
    const users = await User.find({});
    res.json({ message: "Database connection is working!", users });
  } catch (err) {
    res.status(500).json({ message: "Database error", error: err });
  }
});

// ...existing code...

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
