// db-models/notification.js
import mongoose from "mongoose";

const notificationSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Course",
    required: true,
  },
  stageId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Stage",
    required: true,
  },
  type: {
    type: String,
    enum: ["deadline", "warning", "info", "success"],
    default: "deadline",
  },
  message: {
    type: String,
    required: true,
    maxlength: 500,
  },
  isRead: {
    type: Boolean,
    default: false,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  readAt: {
    type: Date,
    default: null,
  },
});

// Index for efficient user notification queries
notificationSchema.index({ userId: 1, createdAt: -1 });
notificationSchema.index({ userId: 1, isRead: 1 });

const Notification = mongoose.model("Notification", notificationSchema);
export default Notification;
