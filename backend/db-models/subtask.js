// db-models/subtask.js
import mongoose from "mongoose";

const subtaskSchema = new mongoose.Schema({
  stageId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Stage",
    required: true,
  },
  title: {
    type: String,
    required: true,
    trim: true,
    maxlength: 200,
  },
  isCompleted: {
    type: Boolean,
    default: false,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  completedAt: {
    type: Date,
    default: null,
  },
});

// Index for efficient stage subtask queries
subtaskSchema.index({ stageId: 1, createdAt: 1 });

const Subtask = mongoose.model("Subtask", subtaskSchema);
export default Subtask;
