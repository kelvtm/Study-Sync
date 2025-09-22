<template>
  <div class="sync-wrapper">
    <!-- Pairing Interface -->
    <div v-if="!activeSession" class="pairing-section">
      <h2>Start a Pair Study Session</h2>

      <label for="time">Select session length:</label>
      <select v-model="sessionTime" id="time">
        <option value="25">25 mins</option>
        <option value="50">50 mins</option>
        <option value="90">90 mins</option>
      </select>

      <button @click="findPartner" :disabled="isSearching" class="btn-el">
        {{ isSearching ? "Searching..." : "Find Partner" }}
      </button>

      <p v-if="statusMessage" class="status-message">{{ statusMessage }}</p>
    </div>

    <!-- Chat Interface -->
    <div v-if="activeSession" class="chat-section">
      <div class="chat-header">
        <div class="session-info">
          <h3>Study Session with {{ partnerUsername }}</h3>
          <div class="timer-container">
            <div class="timer-display" :style="{ color: getTimerColor() }">
              {{ formattedTime }}
            </div>
            <div v-if="timerWarning" class="timer-warning">
              {{ timerWarning }}
            </div>
          </div>
        </div>
        <button @click="endSession" class="btn-end">End Session</button>
      </div>

      <div class="chat-messages" ref="messagesContainer">
        <div
          v-for="message in messages"
          :key="message.timestamp"
          :class="['message', { 'own-message': message.userId === userId }]"
        >
          <div class="message-info">
            <span class="sender">{{
              message.userId === userId ? "You" : partnerUsername
            }}</span>
            <span class="timestamp">{{
              formatMessageTime(message.timestamp)
            }}</span>
          </div>
          <div class="message-content">{{ message.message }}</div>
        </div>

        <div v-if="partnerTyping" class="typing-indicator">
          {{ partnerUsername }} is typing...
        </div>
      </div>

      <div class="chat-input">
        <input
          v-model="newMessage"
          @keyup.enter="sendMessage"
          @input="handleTyping"
          placeholder="Type your message..."
          class="message-input"
        />
        <button
          @click="sendMessage"
          :disabled="!newMessage.trim()"
          class="btn-send"
        >
          Send
        </button>
      </div>
    </div>

    <!-- End Session Confirmation Modal -->
    <div v-if="showEndConfirmation" class="modal-overlay">
      <div class="confirmation-modal">
        <h3>⚠️ End Study Session?</h3>
        <p>Are you sure you want to end this session early?</p>
        <p class="warning-text">
          This will count as a quit session and will be added to your profile
          statistics. Your study partner will also be notified.
        </p>
        <div class="modal-buttons">
          <button @click="cancelEndSession" class="btn-cancel">Cancel</button>
          <button @click="confirmEndSession" class="btn-confirm">
            End Session
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, nextTick } from "vue";
import axios from "axios";
import { io } from "socket.io-client";

// Reactive data
const sessionTime = ref("25");
const statusMessage = ref("");
const isSearching = ref(false);
const activeSession = ref(null);
const partnerEmail = ref("");
const partnerUsername = ref("");
const messages = ref([]);
const newMessage = ref("");
const partnerTyping = ref(false);
const messagesContainer = ref(null);

// Timer data
const remainingTime = ref(0);
const formattedTime = ref("25:00");
const showEndConfirmation = ref(false);
const timerWarning = ref("");

// Socket and user info
let socket = null;
const userId = localStorage.getItem("userId");
const username = localStorage.getItem("username");
let typingTimer = null;

// Initialize socket connection
const initSocket = () => {
  socket = io("http://localhost:3000");

  socket.on("connect", () => {
    console.log("Connected to server");
    socket.emit("join_user", userId);
  });

  // Listen for partner found
  socket.on("partner_found", (data) => {
    if (data.targetUserId === userId) {
      statusMessage.value = "Partner found! Starting session...";
      setTimeout(() => {
        startChatSession(data.sessionId);
      }, 1000);
    }
  });

  // Listen for timer updates
  socket.on("timer_update", (data) => {
    remainingTime.value = data.remainingTime;
    formattedTime.value = data.formattedTime;
  });

  // Listen for timer warnings
  socket.on("timer_warning", (data) => {
    timerWarning.value = data.message;
    setTimeout(() => {
      timerWarning.value = "";
    }, 5000);
  });

  // Listen for session completed naturally
  socket.on("session_completed", (data) => {
    alert("🎉 " + data.message);
    resetSession();
  });

  // Listen for successful session join
  socket.on("joined_session", (data) => {
    console.log("Successfully joined session:", data);
  });

  // Listen for new messages
  socket.on("receive_message", (messageData) => {
    messages.value.push(messageData);
    scrollToBottom();
  });

  // Listen for typing indicators
  socket.on("user_typing", (data) => {
    if (data.userId !== userId) {
      partnerTyping.value = data.isTyping;
      if (data.isTyping) {
        setTimeout(() => {
          partnerTyping.value = false;
        }, 3000);
      }
    }
  });

  // Listen for session ended
  socket.on("session_ended", (data) => {
    if (data.reason === "user_quit") {
      alert(
        `Session ended. Your study partner left the session. You studied for ${data.actualDuration} minutes.`
      );
    } else {
      alert(`Session ended. You studied for ${data.actualDuration} minutes.`);
    }
    resetSession();
  });

  // Listen for user joined
  socket.on("user_joined", (data) => {
    statusMessage.value = data.message;
  });

  // Listen for errors
  socket.on("error", (error) => {
    console.error("Socket error:", error);
    statusMessage.value = `Error: ${error}`;
  });
};

// Find study partner
const findPartner = async () => {
  if (!userId) {
    statusMessage.value = "Please log in first";
    return;
  }

  isSearching.value = true;
  statusMessage.value = "Looking for a study partner...";

  try {
    const res = await axios.post("http://localhost:3000/api/sessions/pair", {
      userId,
      sessionTimeMinutes: parseInt(sessionTime.value),
    });

    if (res.data.session.status === "waiting") {
      statusMessage.value = "Waiting for a partner to join...";
    } else if (res.data.session.status === "active") {
      statusMessage.value = "Partner found! Starting session...";
      setTimeout(() => {
        startChatSession(res.data.session._id, res.data.partnerId);
      }, 1000);
    }
  } catch (err) {
    statusMessage.value =
      "Error: " + (err.response?.data?.error || err.message);
    isSearching.value = false;
  }
};

// Start chat session
const startChatSession = async (sessionId, partnerId) => {
  try {
    // Get session details
    const sessionRes = await axios.get(
      `http://localhost:3000/api/sessions/${sessionId}`
    );
    const session = sessionRes.data.session;

    // Find partner's details
    const partner = session.participants.find((p) => p._id !== userId);
    partnerEmail.value = partner ? partner.email : "Unknown";
    partnerUsername.value = partner ? partner.username : "Unknown";

    activeSession.value = {
      id: sessionId,
      plannedDuration: session.plannedDurationMinutes,
      ...session,
    };

    // Initialize timer
    remainingTime.value =
      session.remainingTimeSeconds || session.plannedDurationMinutes * 60;
    formattedTime.value = formatTime(remainingTime.value);

    isSearching.value = false;
    statusMessage.value = "";

    // Join the session room via socket
    socket.emit("join_session", {
      sessionId,
      userId,
    });
  } catch (error) {
    console.error("Error starting chat session:", error);
    statusMessage.value = "Error starting chat session";
    isSearching.value = false;
  }
};

// Send message
const sendMessage = () => {
  if (!newMessage.value.trim() || !activeSession.value) return;

  const messageData = {
    sessionId: activeSession.value.id,
    userId,
    message: newMessage.value.trim(),
    timestamp: new Date().toISOString(),
  };

  socket.emit("send_message", messageData);
  newMessage.value = "";

  // Stop typing indicator
  socket.emit("typing", {
    sessionId: activeSession.value.id,
    userId,
    isTyping: false,
  });
};

// Handle typing indicator
const handleTyping = () => {
  if (!activeSession.value) return;

  socket.emit("typing", {
    sessionId: activeSession.value.id,
    userId,
    isTyping: true,
  });

  // Clear existing timer
  if (typingTimer) {
    clearTimeout(typingTimer);
  }

  // Set new timer to stop typing indicator
  typingTimer = setTimeout(() => {
    socket.emit("typing", {
      sessionId: activeSession.value.id,
      userId,
      isTyping: false,
    });
  }, 1000);
};

// End session with confirmation
const endSession = () => {
  showEndConfirmation.value = true;
};

const confirmEndSession = async () => {
  if (!activeSession.value) return;

  try {
    await axios.put(
      `http://localhost:3000/api/sessions/${activeSession.value.id}/end`,
      {
        userId,
      }
    );
    showEndConfirmation.value = false;
    // resetSession will be called when we receive the socket event
  } catch (error) {
    console.error("Error ending session:", error);
    showEndConfirmation.value = false;
  }
};

const cancelEndSession = () => {
  showEndConfirmation.value = false;
};

// Reset session state
const resetSession = () => {
  activeSession.value = null;
  partnerEmail.value = "";
  partnerUsername.value = "";
  messages.value = [];
  newMessage.value = "";
  partnerTyping.value = false;
  isSearching.value = false;
  statusMessage.value = "";
  remainingTime.value = 0;
  formattedTime.value = "00:00";
  timerWarning.value = "";
  showEndConfirmation.value = false;
};

// Scroll to bottom of messages
const scrollToBottom = () => {
  nextTick(() => {
    if (messagesContainer.value) {
      messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight;
    }
  });
};

// Format time for display
const formatTime = (seconds) => {
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${mins.toString().padStart(2, "0")}:${secs
    .toString()
    .padStart(2, "0")}`;
};

// Get timer color based on remaining time
const getTimerColor = () => {
  if (remainingTime.value > 600) return "#28a745"; // Green > 10 minutes
  if (remainingTime.value > 300) return "#ffc107"; // Yellow > 5 minutes
  return "#dc3545"; // Red <= 5 minutes
};

// Format timestamp for messages
const formatMessageTime = (timestamp) => {
  return new Date(timestamp).toLocaleTimeString([], {
    hour: "2-digit",
    minute: "2-digit",
  });
};

// Lifecycle hooks
onMounted(() => {
  initSocket();
});

onUnmounted(() => {
  if (socket) {
    socket.disconnect();
  }
  if (typingTimer) {
    clearTimeout(typingTimer);
  }
});
</script>

<style scoped>
.sync-wrapper {
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
}

.pairing-section {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 15px;
  margin-top: 50px;
}

.btn-el {
  background-color: var(--secondary-color);
  font-family: "Nunito", serif;
  font-weight: 600;
  color: var(--primary-color);
  padding: 10px 20px;
  border-radius: 5px;
  cursor: pointer;
  border: none;
}

.btn-el:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.status-message {
  color: #666;
  font-style: italic;
}

/* Chat Styles */
.chat-section {
  display: flex;
  flex-direction: column;
  height: 600px;
  border: 1px solid #ddd;
  border-radius: 8px;
  overflow: hidden;
}

.chat-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px;
  background-color: #f5f5f5;
  border-bottom: 1px solid #ddd;
}

.session-info {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.session-info h3 {
  margin: 0;
  color: #333;
}

.timer-container {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 5px;
}

.timer-display {
  font-size: 1.5em;
  font-weight: bold;
  font-family: "Courier New", monospace;
  transition: color 0.3s ease;
}

.timer-warning {
  background-color: #fff3cd;
  color: #856404;
  padding: 5px 10px;
  border-radius: 4px;
  font-size: 0.9em;
  border: 1px solid #ffeaa7;
}

.btn-end {
  background-color: #ff4757;
  color: white;
  border: none;
  padding: 8px 16px;
  border-radius: 4px;
  cursor: pointer;
}

.chat-messages {
  flex: 1;
  padding: 15px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.message {
  max-width: 70%;
  align-self: flex-start;
}

.own-message {
  align-self: flex-end;
}

.message-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 5px;
  font-size: 0.8em;
  color: #666;
}

.message-content {
  background-color: #e9ecef;
  padding: 10px 15px;
  border-radius: 18px;
  word-wrap: break-word;
}

.own-message .message-content {
  background-color: var(--secondary-color, #007bff);
  color: white;
}

.typing-indicator {
  font-style: italic;
  color: #666;
  padding: 5px 15px;
}

.chat-input {
  display: flex;
  padding: 15px;
  border-top: 1px solid #ddd;
  gap: 10px;
}

.message-input {
  flex: 1;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 20px;
  outline: none;
}

.message-input:focus {
  border-color: var(--secondary-color, #007bff);
}

.btn-send {
  background-color: var(--secondary-color, #007bff);
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 20px;
  cursor: pointer;
}

.btn-send:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* Modal Styles */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.confirmation-modal {
  background: white;
  padding: 30px;
  border-radius: 12px;
  max-width: 400px;
  width: 90%;
  text-align: center;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
}

.confirmation-modal h3 {
  margin-bottom: 15px;
  color: #333;
}

.confirmation-modal p {
  margin-bottom: 15px;
  color: #666;
  line-height: 1.5;
}

.warning-text {
  background-color: #fff3cd;
  border: 1px solid #ffeaa7;
  border-radius: 6px;
  padding: 12px;
  color: #856404;
  font-size: 0.9em;
}

.modal-buttons {
  display: flex;
  gap: 15px;
  justify-content: center;
  margin-top: 20px;
}

.btn-cancel {
  background-color: #6c757d;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 6px;
  cursor: pointer;
}

.btn-confirm {
  background-color: #dc3545;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 6px;
  cursor: pointer;
}

.btn-cancel:hover {
  background-color: #5a6268;
}

.btn-confirm:hover {
  background-color: #c82333;
}
</style>
