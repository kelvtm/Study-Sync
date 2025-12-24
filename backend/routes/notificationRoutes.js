// routes/notificationRoutes.js
import express from "express";
import Notification from "../db-models/notification.js";
import Course from "../db-models/course.js";
import Stage from "../db-models/stage.js";

const router = express.Router();

// Helper function to check deadlines and create notifications
const checkDeadlinesAndNotify = async (userId) => {
  try {
    const now = new Date();

    // Get all user's courses
    const courses = await Course.find({ userId });

    if (courses.length === 0) {
      return [];
    }

    const courseIds = courses.map((c) => c._id);

    // Get all stages for these courses where deadline has passed
    const expiredStages = await Stage.find({
      courseId: { $in: courseIds },
      endDate: { $lte: now },
    }).populate("courseId");

    const newNotifications = [];

    for (const stage of expiredStages) {
      // Check if notification already exists for this stage
      const existingNotification = await Notification.findOne({
        userId,
        stageId: stage._id,
        courseId: stage.courseId._id,
      });

      if (!existingNotification) {
        // Create notification
        const message = `${stage.title} stage for ${stage.courseId.courseName} is due. Check out the remaining stages for your Assessment`;

        const notification = new Notification({
          userId,
          courseId: stage.courseId._id,
          stageId: stage._id,
          type: "deadline",
          message,
        });

        await notification.save();
        newNotifications.push(notification);

        console.log(
          `📢 Created notification for stage "${stage.title}" in course "${stage.courseId.courseName}"`
        );
      }
    }

    return newNotifications;
  } catch (error) {
    console.error("Error checking deadlines:", error);
    throw error;
  }
};

// GET /api/notifications - Get user notifications
router.get("/", async (req, res) => {
  try {
    const { userId } = req.query;

    if (!userId) {
      return res.status(400).json({ error: "userId is required" });
    }

    // Check for new deadline notifications
    await checkDeadlinesAndNotify(userId);

    // Get all notifications for user
    const notifications = await Notification.find({ userId })
      .sort({ createdAt: -1 })
      .limit(50) // Limit to 50 most recent
      .lean();

    res.json({ notifications });
  } catch (error) {
    console.error("Error fetching notifications:", error);
    res.status(500).json({ error: "Failed to fetch notifications" });
  }
});

// PUT /api/notifications/:id/read - Mark notification as read
router.put("/:id/read", async (req, res) => {
  try {
    const { id } = req.params;
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({ error: "userId is required" });
    }

    // Find notification and verify ownership
    const notification = await Notification.findOne({ _id: id, userId });

    if (!notification) {
      return res.status(404).json({ error: "Notification not found" });
    }

    notification.isRead = true;
    notification.readAt = new Date();
    await notification.save();

    res.json({
      message: "Notification marked as read",
      notification,
    });
  } catch (error) {
    console.error("Error marking notification as read:", error);
    res.status(500).json({ error: "Failed to update notification" });
  }
});

// PUT /api/notifications/read-all - Mark all notifications as read
router.put("/read-all", async (req, res) => {
  try {
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({ error: "userId is required" });
    }

    const result = await Notification.updateMany(
      { userId, isRead: false },
      { $set: { isRead: true, readAt: new Date() } }
    );

    res.json({
      message: "All notifications marked as read",
      modifiedCount: result.modifiedCount,
    });
  } catch (error) {
    console.error("Error marking all as read:", error);
    res.status(500).json({ error: "Failed to update notifications" });
  }
});

// DELETE /api/notifications/:id - Delete notification
router.delete("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { userId } = req.query;

    if (!userId) {
      return res.status(400).json({ error: "userId is required" });
    }

    // Find and delete notification
    const notification = await Notification.findOneAndDelete({
      _id: id,
      userId,
    });

    if (!notification) {
      return res.status(404).json({ error: "Notification not found" });
    }

    res.json({
      message: "Notification deleted successfully",
      deletedId: id,
    });
  } catch (error) {
    console.error("Error deleting notification:", error);
    res.status(500).json({ error: "Failed to delete notification" });
  }
});

// POST /api/notifications/check - Manually trigger deadline check
router.post("/check", async (req, res) => {
  try {
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({ error: "userId is required" });
    }

    const newNotifications = await checkDeadlinesAndNotify(userId);

    res.json({
      message: "Deadline check completed",
      newNotifications: newNotifications.length,
      notifications: newNotifications,
    });
  } catch (error) {
    console.error("Error checking deadlines:", error);
    res.status(500).json({ error: "Failed to check deadlines" });
  }
});

export default router;
