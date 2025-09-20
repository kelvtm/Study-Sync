import express from "express";
import Session from "../db-models/sessions.js";
import User from "../db-models/user.js";

const router = express.Router();

// User tries to find a study partner
router.post("/pair", async (req, res) => {
  try {
    const { userId } = req.body;
    const io = req.app.get("io"); // Get Socket.IO instance

    // Look for a waiting session
    let waitingSession = await Session.findOne({
      status: "waiting",
      participants: { $ne: userId }, // Don't match user's own session
    });

    if (waitingSession) {
      // Add second participant
      waitingSession.participants.push(userId);
      waitingSession.status = "active";
      waitingSession.startedAt = new Date();
      await waitingSession.save();

      // Populate participants to get user details
      await waitingSession.populate("participants", "email");

      // Notify the first user that a partner was found
      const firstUserId = waitingSession.participants[0]._id.toString();
      io.emit("partner_found", {
        sessionId: waitingSession._id,
        partnerId: userId,
        message: "Study partner found! Starting session...",
        targetUserId: firstUserId,
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
      "email"
    );

    if (!session) {
      return res.status(404).json({ error: "Session not found" });
    }

    res.json({ session });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// End a session
router.put("/:sessionId/end", async (req, res) => {
  try {
    const { sessionId } = req.params;
    const { userId } = req.body;
    const io = req.app.get("io");

    const session = await Session.findById(sessionId);
    if (!session) {
      return res.status(404).json({ error: "Session not found" });
    }

    // Check if user is part of this session
    if (!session.participants.includes(userId)) {
      return res.status(403).json({ error: "Not authorized" });
    }

    session.status = "completed";
    session.endedAt = new Date();
    await session.save();

    // Notify all participants that session ended
    io.to(`session_${sessionId}`).emit("session_ended", {
      sessionId,
      message: "Study session has ended",
      endedBy: userId,
    });

    res.json({
      message: "Session ended successfully",
      session,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

export default router;
