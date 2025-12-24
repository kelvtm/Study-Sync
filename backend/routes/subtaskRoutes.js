// routes/subtaskRoutes.js
import express from "express";
import Subtask from "../db-models/subtask.js";
import Stage from "../db-models/stage.js";
import Course from "../db-models/course.js";

const router = express.Router();

// POST /api/subtasks - Create new subtask
router.post("/", async (req, res) => {
  try {
    const { stageId, title, userId } = req.body;

    // Validation
    if (!stageId || !title || !userId) {
      return res.status(400).json({
        error: "Missing required fields: stageId, title, userId",
      });
    }

    const trimmedTitle = title.trim();
    if (trimmedTitle.length === 0) {
      return res.status(400).json({ error: "Subtask title cannot be empty" });
    }

    if (trimmedTitle.length > 200) {
      return res
        .status(400)
        .json({ error: "Subtask title cannot exceed 200 characters" });
    }

    // Verify user owns this stage (through course ownership)
    const stage = await Stage.findById(stageId).populate("courseId");
    if (!stage) {
      return res.status(404).json({ error: "Stage not found" });
    }

    if (stage.courseId.userId.toString() !== userId) {
      return res
        .status(403)
        .json({ error: "Not authorized to add subtasks to this stage" });
    }

    // Create subtask
    const subtask = new Subtask({
      stageId,
      title: trimmedTitle,
      isCompleted: false,
    });

    await subtask.save();

    console.log(`✅ Created subtask "${trimmedTitle}" for stage ${stageId}`);

    res.status(201).json({
      message: "Subtask created successfully",
      subtask,
    });
  } catch (error) {
    console.error("Error creating subtask:", error);
    res.status(500).json({ error: "Failed to create subtask" });
  }
});

// PUT /api/subtasks/:id - Update subtask (toggle completion or edit title)
router.put("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { userId, isCompleted, title } = req.body;

    if (!userId) {
      return res.status(400).json({ error: "userId is required" });
    }

    // Find subtask and verify ownership
    const subtask = await Subtask.findById(id).populate({
      path: "stageId",
      populate: {
        path: "courseId",
        model: "Course",
      },
    });

    if (!subtask) {
      return res.status(404).json({ error: "Subtask not found" });
    }

    if (subtask.stageId.courseId.userId.toString() !== userId) {
      return res
        .status(403)
        .json({ error: "Not authorized to update this subtask" });
    }

    const updates = {};

    // Update completion status
    if (typeof isCompleted === "boolean") {
      updates.isCompleted = isCompleted;
      updates.completedAt = isCompleted ? new Date() : null;
    }

    // Update title if provided
    if (title !== undefined) {
      const trimmedTitle = title.trim();
      if (trimmedTitle.length === 0) {
        return res.status(400).json({ error: "Subtask title cannot be empty" });
      }
      if (trimmedTitle.length > 200) {
        return res
          .status(400)
          .json({ error: "Subtask title cannot exceed 200 characters" });
      }
      updates.title = trimmedTitle;
    }

    // Apply updates
    Object.assign(subtask, updates);
    await subtask.save();

    console.log(`✅ Updated subtask ${id}: ${JSON.stringify(updates)}`);

    res.json({
      message: "Subtask updated successfully",
      subtask,
    });
  } catch (error) {
    console.error("Error updating subtask:", error);
    res.status(500).json({ error: "Failed to update subtask" });
  }
});

// DELETE /api/subtasks/:id - Delete subtask
router.delete("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { userId } = req.query;

    if (!userId) {
      return res.status(400).json({ error: "userId is required" });
    }

    // Find subtask and verify ownership
    const subtask = await Subtask.findById(id).populate({
      path: "stageId",
      populate: {
        path: "courseId",
        model: "Course",
      },
    });

    if (!subtask) {
      return res.status(404).json({ error: "Subtask not found" });
    }

    if (subtask.stageId.courseId.userId.toString() !== userId) {
      return res
        .status(403)
        .json({ error: "Not authorized to delete this subtask" });
    }

    const subtaskTitle = subtask.title;
    await Subtask.deleteOne({ _id: id });

    console.log(`🗑️  Deleted subtask "${subtaskTitle}"`);

    res.json({
      message: "Subtask deleted successfully",
      deletedSubtask: {
        id,
        title: subtaskTitle,
      },
    });
  } catch (error) {
    console.error("Error deleting subtask:", error);
    res.status(500).json({ error: "Failed to delete subtask" });
  }
});

// GET /api/subtasks/stage/:stageId - Get all subtasks for a stage (optional, for debugging)
router.get("/stage/:stageId", async (req, res) => {
  try {
    const { stageId } = req.params;
    const { userId } = req.query;

    if (!userId) {
      return res.status(400).json({ error: "userId is required" });
    }

    // Verify user owns this stage
    const stage = await Stage.findById(stageId).populate("courseId");
    if (!stage) {
      return res.status(404).json({ error: "Stage not found" });
    }

    if (stage.courseId.userId.toString() !== userId) {
      return res
        .status(403)
        .json({ error: "Not authorized to view these subtasks" });
    }

    // Get subtasks for this stage
    const subtasks = await Subtask.find({ stageId }).sort({ createdAt: 1 });

    res.json({
      subtasks,
      stage: {
        id: stage._id,
        title: stage.title,
        courseId: stage.courseId._id,
      },
    });
  } catch (error) {
    console.error("Error fetching subtasks:", error);
    res.status(500).json({ error: "Failed to fetch subtasks" });
  }
});

export default router;
