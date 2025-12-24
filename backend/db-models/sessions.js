import mongoose from "mongoose";

const sessionSchema = new mongoose.Schema({
  participants: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
  ],
  status: {
    type: String,
    enum: ["waiting", "active", "completed", "terminated", "disconnected"],
    default: "waiting",
  },
  // Timer settings
  plannedDurationMinutes: {
    type: Number,
    required: true,
    default: 25,
  },
  actualDurationMinutes: {
    type: Number,
    default: 0,
  },
  remainingTimeSeconds: {
    type: Number,
    default: 0,
  },

  // Session tracking
  createdAt: {
    type: Date,
    default: Date.now,
  },
  startedAt: {
    type: Date,
    default: null,
  },
  endedAt: {
    type: Date,
    default: null,
  },

  // Termination details
  terminatedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    default: null,
  },
  terminationReason: {
    type: String,
    enum: ["time_expired", "user_quit", "disconnection", "mutual_agreement"],
    default: null,
  },

  // Track which users were present when session ended
  participantsAtEnd: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
  ],
});

const Session = mongoose.model("Session", sessionSchema);
export default Session;
