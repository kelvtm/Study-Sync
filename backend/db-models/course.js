// db-models/course.js
import mongoose from "mongoose";

const courseSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
  },
  courseName: {
    type: String,
    required: true,
    trim: true,
    maxlength: 100,
  },
  submissionDate: {
    type: Date,
    required: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
  // Calculated field - total days from creation to submission
  totalDays: {
    type: Number,
    required: true,
  },
});

// Index for efficient user course queries
courseSchema.index({ userId: 1, createdAt: -1 });

const Course = mongoose.model("Course", courseSchema);
export default Course;
