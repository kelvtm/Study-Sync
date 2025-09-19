import mongoose from "mongoose";

const sessionSchema = new mongoose.Schema({
  participants: [{ type: mongoose.Schema.Types.ObjectId, ref: "User" }],
  duration: { type: Number, required: true }, // in minutes
  startTime: { type: Date, default: Date.now },
  isActive: { type: Boolean, default: true },
});

export default mongoose.model("Session", sessionSchema);
