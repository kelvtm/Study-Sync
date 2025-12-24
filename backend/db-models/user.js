import mongoose from "mongoose";

const userSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    unique: true,
  },
  username: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    minlength: 3,
    maxlength: 20,
  },
  password: {
    type: String,
    required: true,
  },
  // Study Statistics
  totalStudyMinutes: {
    type: Number,
    default: 0,
  },
  completedSessions: {
    type: Number,
    default: 0,
  },
  quitSessions: {
    type: Number,
    default: 0,
  },
  disconnectedSessions: {
    type: Number,
    default: 0,
  },
  longestSession: {
    type: Number,
    default: 0,
  },
  currentStreak: {
    type: Number,
    default: 0,
  },
  lastStudyDate: {
    type: Date,
    default: null,
  },
  // Weekly stats for leaderboard reset
  weeklyStudyMinutes: {
    type: Number,
    default: 0,
  },
  weeklyCompletedSessions: {
    type: Number,
    default: 0,
  },
  lastWeekReset: {
    type: Date,
    default: Date.now,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

// Index for leaderboard queries
userSchema.index({ weeklyStudyMinutes: -1 });
userSchema.index({ totalStudyMinutes: -1 });

const User = mongoose.model("User", userSchema);
export default User;
