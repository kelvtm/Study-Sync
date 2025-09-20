import mongoose from "mongoose";

const sessionSchema = new mongoose.Schema({
  participants: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User", // links to User schema
    },
  ],
  status: {
    type: String,
    enum: ["waiting", "active", "completed"],
    default: "waiting",
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  startedAt: Date,
  endedAt: Date,
});

const Session = mongoose.model("Session", sessionSchema);
export default Session;
