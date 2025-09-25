// routes/courseRoutes.js
import express from "express";
import Course from "../db-models/course.js";
import Stage from "../db-models/stage.js";
import Subtask from "../db-models/subtask.js";

const router = express.Router();

// Helper function to calculate stage dates
const calculateStageDates = (submissionDate, createdDate) => {
  const totalMs = submissionDate.getTime() - createdDate.getTime();
  const totalDays = Math.ceil(totalMs / (1000 * 60 * 60 * 24));

  // Stage configurations with percentages
  const stages = [
    { title: "Planning and preparation", percentage: 9, order: 1 },
    { title: "Research, reading and note-taking", percentage: 36, order: 2 },
    { title: "Developing", percentage: 43, order: 3 },
    { title: "Reviewing and refining", percentage: 12, order: 4 },
  ];

  let currentStartDate = new Date(createdDate);
  const stageData = [];

  stages.forEach((stage, index) => {
    const stageDays = Math.max(
      1,
      Math.floor((totalDays * stage.percentage) / 100)
    );
    const startDate = new Date(currentStartDate);
    const endDate = new Date(currentStartDate);
    endDate.setDate(endDate.getDate() + stageDays - 1);

    // Ensure last stage ends exactly on submission date
    if (index === stages.length - 1) {
      endDate.setTime(submissionDate.getTime());
    }

    stageData.push({
      ...stage,
      startDate,
      endDate,
      stageDays,
    });

    // Next stage starts the day after current stage ends
    currentStartDate = new Date(endDate);
    currentStartDate.setDate(currentStartDate.getDate() + 1);
  });

  return { stageData, totalDays };
};

// POST /api/courses - Create new course with auto-generated stages
router.post("/", async (req, res) => {
  try {
    const { userId, courseName, submissionDate } = req.body;

    // Validation
    if (!userId || !courseName || !submissionDate) {
      return res.status(400).json({
        error: "Missing required fields: userId, courseName, submissionDate",
      });
    }

    const submissionDateObj = new Date(submissionDate);
    const createdDate = new Date();

    // Validate submission date is in the future
    if (submissionDateObj <= createdDate) {
      return res.status(400).json({
        error: "Submission date must be in the future",
      });
    }

    // Calculate stage dates
    const { stageData, totalDays } = calculateStageDates(
      submissionDateObj,
      createdDate
    );

    // Create course
    const course = new Course({
      userId,
      courseName: courseName.trim(),
      submissionDate: submissionDateObj,
      totalDays,
      createdAt: createdDate,
    });

    await course.save();

    // Create stages for this course
    const stages = await Stage.insertMany(
      stageData.map((stage) => ({
        courseId: course._id,
        title: stage.title,
        percentage: stage.percentage,
        order: stage.order,
        startDate: stage.startDate,
        endDate: stage.endDate,
      }))
    );

    console.log(
      `✅ Created course "${courseName}" with ${stages.length} stages`
    );

    res.status(201).json({
      message: "Course created successfully",
      course: {
        ...course.toObject(),
        stages: stages,
      },
    });
  } catch (error) {
    console.error("Error creating course:", error);
    res.status(500).json({ error: "Failed to create course" });
  }
});

// GET /api/courses - Get all courses for a user with stages and subtasks
router.get("/", async (req, res) => {
  try {
    const { userId } = req.query;

    if (!userId) {
      return res.status(400).json({ error: "userId is required" });
    }

    // Get user's courses
    const courses = await Course.find({ userId })
      .sort({ createdAt: -1 })
      .lean();

    if (courses.length === 0) {
      return res.json({ courses: [] });
    }

    // Get all stages for these courses
    const courseIds = courses.map((course) => course._id);
    const stages = await Stage.find({ courseId: { $in: courseIds } })
      .sort({ courseId: 1, order: 1 })
      .lean();

    // Get all subtasks for these stages
    const stageIds = stages.map((stage) => stage._id);
    const subtasks = await Subtask.find({ stageId: { $in: stageIds } })
      .sort({ stageId: 1, createdAt: 1 })
      .lean();

    // Organize data structure
    const coursesWithDetails = courses.map((course) => {
      const courseStages = stages
        .filter((stage) => stage.courseId.toString() === course._id.toString())
        .map((stage) => {
          const stageSubtasks = subtasks.filter(
            (subtask) => subtask.stageId.toString() === stage._id.toString()
          );

          return {
            ...stage,
            subtasks: stageSubtasks,
          };
        });

      return {
        ...course,
        stages: courseStages,
      };
    });

    res.json({ courses: coursesWithDetails });
  } catch (error) {
    console.error("Error fetching courses:", error);
    res.status(500).json({ error: "Failed to fetch courses" });
  }
});

// GET /api/courses/:id - Get specific course with stages and subtasks
router.get("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { userId } = req.query;

    // Get course and verify ownership
    const course = await Course.findOne({ _id: id, userId }).lean();

    if (!course) {
      return res.status(404).json({ error: "Course not found" });
    }

    // Get stages for this course
    const stages = await Stage.find({ courseId: id }).sort({ order: 1 }).lean();

    // Get subtasks for these stages
    const stageIds = stages.map((stage) => stage._id);
    const subtasks = await Subtask.find({ stageId: { $in: stageIds } })
      .sort({ stageId: 1, createdAt: 1 })
      .lean();

    // Organize stages with subtasks
    const stagesWithSubtasks = stages.map((stage) => {
      const stageSubtasks = subtasks.filter(
        (subtask) => subtask.stageId.toString() === stage._id.toString()
      );

      return {
        ...stage,
        subtasks: stageSubtasks,
      };
    });

    res.json({
      course: {
        ...course,
        stages: stagesWithSubtasks,
      },
    });
  } catch (error) {
    console.error("Error fetching course:", error);
    res.status(500).json({ error: "Failed to fetch course" });
  }
});

// DELETE /api/courses/:id - Delete course and all related data
router.delete("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { userId } = req.query;

    // Verify course exists and user owns it
    const course = await Course.findOne({ _id: id, userId });

    if (!course) {
      return res.status(404).json({ error: "Course not found" });
    }

    // Get all stages for this course
    const stages = await Stage.find({ courseId: id });
    const stageIds = stages.map((stage) => stage._id);

    // Delete all subtasks for these stages
    const deletedSubtasks = await Subtask.deleteMany({
      stageId: { $in: stageIds },
    });

    // Delete all stages for this course
    const deletedStages = await Stage.deleteMany({ courseId: id });

    // Delete the course
    await Course.deleteOne({ _id: id });

    console.log(
      `🗑️  Deleted course "${course.courseName}" and ${deletedStages.deletedCount} stages, ${deletedSubtasks.deletedCount} subtasks`
    );

    res.json({
      message: "Course deleted successfully",
      deleted: {
        course: course.courseName,
        stages: deletedStages.deletedCount,
        subtasks: deletedSubtasks.deletedCount,
      },
    });
  } catch (error) {
    console.error("Error deleting course:", error);
    res.status(500).json({ error: "Failed to delete course" });
  }
});

export default router;
