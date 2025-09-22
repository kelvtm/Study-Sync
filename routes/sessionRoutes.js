import express from "express";
import Session from "../db-models/sessions.js";
import User from "../db-models/user.js";

const router = express.Router();

// Store active timers
const activeTimers = new Map();

// User tries to find a study partner
router.post("/pair", async (req, res) => {
  try {
    const { userId, sessionTimeMinutes = 25 } = req.body;
    const io = req.app.get("io");

    // Look for a waiting session with similar time preference
    let waitingSession = await Session.findOne({
      status: "waiting",
      participants: { $ne: userId },
      plannedDurationMinutes: sessionTimeMinutes,
    });

    if (waitingSession) {
      // Add second participant
      waitingSession.participants.push(userId);
      waitingSession.status = "active";
      waitingSession.startedAt = new Date();
      waitingSession.remainingTimeSeconds =
        waitingSession.plannedDurationMinutes * 60;
      await waitingSession.save();

      // Start the timer
      startSessionTimer(
        waitingSession._id,
        waitingSession.remainingTimeSeconds,
        io
      );

      // Populate participants to get user details
      await waitingSession.populate("participants", "email username");

      // Notify the first user that a partner was found
      const firstUserId = waitingSession.participants[0]._id.toString();
      io.emit("partner_found", {
        sessionId: waitingSession._id,
        partnerId: userId,
        message: "Study partner found! Starting session...",
        targetUserId: firstUserId,
        sessionTime: waitingSession.plannedDurationMinutes,
      });

      return res.json({
        message: "Paired successfully!",
        session: waitingSession,
        partnerId: firstUserId,
      });
    } else {
      // Create new waiting session
      const newSession = new Session({
        participants: [userId],
        status: "waiting",
        plannedDurationMinutes: sessionTimeMinutes,
        remainingTimeSeconds: sessionTimeMinutes * 60,
      });
      await newSession.save();

      return res.json({
        message: "Waiting for partner...",
        session: newSession,
      });
    }
  } catch (error) {
    console.error("Pairing error:", error);
    res.status(500).json({ error: error.message });
  }
});

// Get session details
router.get("/:sessionId", async (req, res) => {
  try {
    const { sessionId } = req.params;
    const session = await Session.findById(sessionId).populate(
      "participants",
      "email username"
    );

    if (!session) {
      return res.status(404).json({ error: "Session not found" });
    }

    res.json({ session });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// End a session manually
router.put("/:sessionId/end", async (req, res) => {
  try {
    const { sessionId } = req.params;
    const { userId } = req.body;
    const io = req.app.get("io");

    const session = await Session.findById(sessionId).populate("participants");
    if (!session) {
      return res.status(404).json({ error: "Session not found" });
    }

    // Check if user is part of this session
    if (!session.participants.some((p) => p._id.toString() === userId)) {
      return res.status(403).json({ error: "Not authorized" });
    }

    // Calculate actual duration
    const actualDurationMinutes = calculateActualDuration(session);

    // Update session
    session.status = "terminated";
    session.endedAt = new Date();
    session.terminatedBy = userId;
    session.terminationReason = "user_quit";
    session.actualDurationMinutes = actualDurationMinutes;
    session.participantsAtEnd = session.participants.map((p) => p._id);
    await session.save();

    // Clear timer
    if (activeTimers.has(sessionId)) {
      clearInterval(activeTimers.get(sessionId));
      activeTimers.delete(sessionId);
    }

    // Update user stats
    await updateUserStats(session, io);

    // Notify all participants that session ended
    io.to(`session_${sessionId}`).emit("session_ended", {
      sessionId,
      message: "Study session has been ended",
      endedBy: userId,
      reason: "user_quit",
      actualDuration: actualDurationMinutes,
    });

    res.json({
      message: "Session ended successfully",
      session,
      actualDuration: actualDurationMinutes,
    });
  } catch (error) {
    console.error("End session error:", error);
    res.status(500).json({ error: error.message });
  }
});

// Helper function to start session timer
function startSessionTimer(sessionId, durationSeconds, io) {
  let remainingTime = durationSeconds;

  const timer = setInterval(async () => {
    remainingTime--;

    // Broadcast time update to session room
    io.to(`session_${sessionId}`).emit("timer_update", {
      remainingTime,
      formattedTime: formatTime(remainingTime),
    });

    // Warning at 5 minutes (300 seconds)
    if (remainingTime === 300) {
      io.to(`session_${sessionId}`).emit("timer_warning", {
        message: "5 minutes remaining!",
        remainingTime,
      });
    }

    // Session completed when timer reaches 0
    if (remainingTime <= 0) {
      clearInterval(timer);
      activeTimers.delete(sessionId);

      try {
        await completeSession(sessionId, io);
      } catch (error) {
        console.error("Error completing session:", error);
      }
    }

    // Update session in database every 30 seconds
    if (remainingTime % 30 === 0) {
      try {
        await Session.findByIdAndUpdate(sessionId, {
          remainingTimeSeconds: remainingTime,
        });
      } catch (error) {
        console.error("Error updating session time:", error);
      }
    }
  }, 1000);

  activeTimers.set(sessionId, timer);
}

// Helper function to complete session naturally
async function completeSession(sessionId, io) {
  try {
    const session = await Session.findById(sessionId).populate("participants");
    if (!session) return;

    const actualDurationMinutes = session.plannedDurationMinutes;

    session.status = "completed";
    session.endedAt = new Date();
    session.terminationReason = "time_expired";
    session.actualDurationMinutes = actualDurationMinutes;
    session.participantsAtEnd = session.participants.map((p) => p._id);
    await session.save();

    // Update user stats
    await updateUserStats(session, io);

    // Notify participants
    io.to(`session_${sessionId}`).emit("session_completed", {
      sessionId,
      message: "Study session completed! Great work! 🎉",
      actualDuration: actualDurationMinutes,
    });
  } catch (error) {
    console.error("Error completing session:", error);
  }
}

// Helper function to update user statistics
async function updateUserStats(session, io) {
  const actualMinutes = session.actualDurationMinutes;

  // Only count sessions with at least 5 minutes
  if (actualMinutes < 5) return;

  for (const participant of session.participants) {
    try {
      const user = await User.findById(participant._id);
      if (!user) continue;

      // Update study time
      user.totalStudyMinutes += actualMinutes;
      user.weeklyStudyMinutes += actualMinutes;

      // Update session counts
      if (session.terminationReason === "time_expired") {
        user.completedSessions += 1;
        user.weeklyCompletedSessions += 1;
      } else if (
        session.terminatedBy &&
        session.terminatedBy.toString() === participant._id.toString()
      ) {
        user.quitSessions += 1;
      }

      // Update longest session
      if (actualMinutes > user.longestSession) {
        user.longestSession = actualMinutes;
      }

      // Update study streak
      const today = new Date();
      const lastStudy = user.lastStudyDate;

      if (!lastStudy || !isSameDay(lastStudy, today)) {
        if (lastStudy && isConsecutiveDay(lastStudy, today)) {
          user.currentStreak += 1;
        } else if (!lastStudy || !isSameDay(lastStudy, today)) {
          user.currentStreak = 1;
        }
        user.lastStudyDate = today;
      }

      await user.save();

      // Emit stats update to user
      io.emit("stats_updated", {
        userId: participant._id,
        stats: {
          totalStudyMinutes: user.totalStudyMinutes,
          completedSessions: user.completedSessions,
          quitSessions: user.quitSessions,
          currentStreak: user.currentStreak,
          longestSession: user.longestSession,
        },
      });
    } catch (error) {
      console.error("Error updating user stats:", error);
    }
  }
}

// Helper functions
function calculateActualDuration(session) {
  if (!session.startedAt) return 0;
  const endTime = session.endedAt || new Date();
  const durationMs = endTime - session.startedAt;
  return Math.floor(durationMs / (1000 * 60)); // Convert to minutes
}

function formatTime(seconds) {
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${mins.toString().padStart(2, "0")}:${secs
    .toString()
    .padStart(2, "0")}`;
}

function isSameDay(date1, date2) {
  return date1.toDateString() === date2.toDateString();
}

function isConsecutiveDay(lastDate, currentDate) {
  const yesterday = new Date(currentDate);
  yesterday.setDate(yesterday.getDate() - 1);
  return isSameDay(lastDate, yesterday);
}

export default router;
