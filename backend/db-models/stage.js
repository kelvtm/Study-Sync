// db-models/stage.js
import mongoose from "mongoose";

const stageSchema = new mongoose.Schema({
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Course",
    required: true,
  },
  title: {
    type: String,
    required: true,
    enum: [
      "Planning and preparation",
      "Research, reading and note-taking",
      "Developing",
      "Reviewing and refining",
    ],
  },
  percentage: {
    type: Number,
    required: true,
    enum: [9, 36, 43, 12], // Corresponds to the 4 stages
  },
  order: {
    type: Number,
    required: true,
    min: 1,
    max: 4,
  },
  startDate: {
    type: Date,
    required: true,
  },
  endDate: {
    type: Date,
    required: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

// Index for efficient course stage queries
stageSchema.index({ courseId: 1, order: 1 });

const Stage = mongoose.model("Stage", stageSchema);
export default Stage;
