import express from "express";
import Session from "../db-models/sessions.js"; // make sure path is correct

const router = express.Router();

// User tries to find a study partner
router.post("/pair", async (req, res) => {
  try {
    const { userId } = req.body; // get from frontend or auth middleware

    // Look for a waiting session
    let waitingSession = await Session.findOne({ status: "waiting" });

    if (waitingSession) {
      // Add second participant
      waitingSession.participants.push(userId);
      waitingSession.status = "active";
      waitingSession.startedAt = new Date();
      await waitingSession.save();

      return res.json({
        message: "Paired successfully!",
        session: waitingSession,
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
    res.status(500).json({ error: error.message });
  }
});

export default router;
