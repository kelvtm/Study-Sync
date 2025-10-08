<template>
  <div class="sync-wrapper">
    <!-- Pairing Interface -->
    <div v-if="!activeSession" class="pairing-section">
      <div class="pairing-header">
        <div class="header-icon">
          <i class="fas fa-users"></i>
        </div>
        <h2>Start Your Study Session</h2>
        <p class="subtitle">
          Connect with a study partner and boost your productivity together
        </p>
      </div>

      <div class="pairing-card">
        <div class="image-container">
          <img
            class="study-image"
            src="https://media.istockphoto.com/id/1347747136/vector/group-of-students-studying.jpg?s=612x612&w=0&k=20&c=t8UwXDXTCu2O-2mOLE8_aQ7KTXxjuUk_WgiR0cS6pSk="
            alt="Students studying"
          />
        </div>

        <div class="session-setup">
          <label for="time" class="setup-label">
            <i class="fas fa-clock"></i>
            Select Session Length
          </label>
          <div class="select-wrapper">
            <select v-model="sessionTime" id="time" class="time-select">
              <option value="25">🍅 25 minutes - Quick Focus</option>
              <option value="50">📚 50 minutes - Deep Study</option>
              <option value="90">🎯 90 minutes - Marathon Session</option>
            </select>
            <i class="fas fa-chevron-down select-arrow"></i>
          </div>

          <button @click="findPartner" :disabled="isSearching" class="find-btn">
            <i v-if="isSearching" class="fas fa-spinner fa-spin"></i>
            <i v-else class="fas fa-search"></i>
            {{
              isSearching ? "Searching for Partner..." : "Find Study Partner"
            }}
          </button>

          <div v-if="statusMessage" class="status-message">
            <i v-if="isSearching" class="fas fa-circle-notch fa-spin"></i>
            <i v-else class="fas fa-info-circle"></i>
            {{ statusMessage }}
          </div>
        </div>
      </div>

      <div class="info-tip">
        <i class="fas fa-lightbulb"></i>
        <p>
          <strong>Pro Tip:</strong> Stay on this page during your session for
          the best experience!
        </p>
      </div>
    </div>

    <!-- Chat Interface -->
    <div v-if="activeSession" class="chat-section">
      <div class="chat-header">
        <div class="session-info">
          <div class="partner-info">
            <div class="partner-avatar">
              <i class="fas fa-user"></i>
            </div>
            <div class="partner-details">
              <h3>{{ partnerUsername }}</h3>
              <span class="session-label">
                <i class="fas fa-book-open"></i>
                Study Session
              </span>
            </div>
          </div>
          <div class="timer-container">
            <div
              class="timer-display"
              :class="{ warning: remainingTime <= 300 }"
            >
              <i class="fas fa-clock"></i>
              {{ formattedTime }}
            </div>
            <div v-if="timerWarning" class="timer-warning">
              <i class="fas fa-exclamation-triangle"></i>
              {{ timerWarning }}
            </div>
          </div>
        </div>
        <button @click="endSession" class="btn-end">
          <i class="fas fa-stop"></i>
          End Session
        </button>
      </div>

      <div class="chat-messages" ref="messagesContainer">
        <div
          v-for="message in messages"
          :key="message.timestamp"
          :class="['message', { 'own-message': message.userId === userId }]"
        >
          <div class="message-avatar">
            <i class="fas fa-user"></i>
          </div>
          <div class="message-bubble">
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
        </div>

        <div v-if="partnerTyping" class="typing-indicator">
          <div class="typing-avatar">
            <i class="fas fa-user"></i>
          </div>
          <div class="typing-bubble">
            <div class="typing-animation">
              <span></span>
              <span></span>
              <span></span>
            </div>
            <span class="typing-text">{{ partnerUsername }} is typing...</span>
          </div>
        </div>
      </div>

      <div class="chat-input">
        <div class="input-wrapper">
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
            <i class="fas fa-paper-plane"></i>
          </button>
        </div>
      </div>
    </div>

    <!-- End Session Confirmation Modal -->
    <div v-if="showEndConfirmation" class="modal-overlay">
      <div class="confirmation-modal">
        <div class="modal-icon">
          <i class="fas fa-exclamation-triangle"></i>
        </div>
        <h3>End Study Session?</h3>
        <p>Are you sure you want to end this session early?</p>
        <div class="warning-box">
          <i class="fas fa-info-circle"></i>
          <div class="warning-content">
            <p><strong>This will:</strong></p>
            <ul>
              <li>Count as an incomplete session</li>
              <li>Notify your study partner</li>
              <li>Affect your completion rate</li>
            </ul>
          </div>
        </div>
        <div class="modal-buttons">
          <button @click="cancelEndSession" class="btn-cancel">
            <i class="fas fa-arrow-left"></i>
            Continue Session
          </button>
          <button @click="confirmEndSession" class="btn-confirm">
            <i class="fas fa-stop"></i>
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

  socket.on("partner_found", (data) => {
    if (data.targetUserId === userId) {
      statusMessage.value = "Partner found! Starting session...";
      setTimeout(() => {
        startChatSession(data.sessionId);
      }, 1000);
    }
  });

  socket.on("timer_update", (data) => {
    remainingTime.value = data.remainingTime;
    formattedTime.value = data.formattedTime;
  });

  socket.on("timer_warning", (data) => {
    timerWarning.value = data.message;
    setTimeout(() => {
      timerWarning.value = "";
    }, 5000);
  });

  socket.on("session_completed", (data) => {
    alert("🎉 " + data.message);
    resetSession();
  });

  socket.on("joined_session", (data) => {
    console.log("Successfully joined session:", data);
  });

  socket.on("receive_message", (messageData) => {
    messages.value.push(messageData);
    scrollToBottom();
  });

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

  socket.on("user_joined", (data) => {
    statusMessage.value = data.message;
  });

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
  statusMessage.value = "Looking for a motivated study partner...";

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
    const sessionRes = await axios.get(
      `http://localhost:3000/api/sessions/${sessionId}`
    );
    const session = sessionRes.data.session;

    const partner = session.participants.find((p) => p._id !== userId);
    partnerEmail.value = partner ? partner.email : "Unknown";
    partnerUsername.value = partner ? partner.username : "Unknown";

    activeSession.value = {
      id: sessionId,
      plannedDuration: session.plannedDurationMinutes,
      ...session,
    };

    remainingTime.value =
      session.remainingTimeSeconds || session.plannedDurationMinutes * 60;
    formattedTime.value = formatTime(remainingTime.value);

    isSearching.value = false;
    statusMessage.value = "";

    socket.emit("join_session", { sessionId, userId });
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

  if (typingTimer) {
    clearTimeout(typingTimer);
  }

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
  max-width: 900px;
  margin: 0 auto;
  padding: 1.5rem;
  min-height: calc(100vh - 80px);
}

/* Pairing Section */
.pairing-section {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.pairing-header {
  text-align: center;
  margin-bottom: 1rem;
}

.header-icon {
  width: 70px;
  height: 70px;
  background: linear-gradient(
    135deg,
    var(--secondary-color),
    var(--secondary-variant)
  );
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 1.5rem;
  color: white;
  font-size: 2rem;
  box-shadow: var(--box-shadow-light);
}

.pairing-header h2 {
  font-size: 2.5rem;
  font-weight: 700;
  color: var(--color-heading);
  margin-bottom: 1rem;
}

.subtitle {
  font-size: 1.2rem;
  color: var(--color-text-secondary);
  max-width: 500px;
  margin: 0 auto;
  line-height: 1.5;
}

.pairing-card {
  background: var(--background-secondary);
  border-radius: var(--border-radius-large);
  padding: 2rem;
  box-shadow: var(--box-shadow-light);
}

.image-container {
  text-align: center;
  margin-bottom: 2rem;
}

.study-image {
  max-width: 400px;
  width: 100%;
  height: auto;
  border-radius: var(--border-radius-large);
  box-shadow: var(--box-shadow-light);
}

.session-setup {
  max-width: 400px;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.setup-label {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 600;
  color: var(--color-text);
  font-size: 1.1rem;
}

.setup-label i {
  color: var(--primary-variant);
}

.select-wrapper {
  position: relative;
}

.time-select {
  width: 100%;
  padding: 1rem 1.5rem;
  border: 2px solid var(--color-border);
  border-radius: var(--border-radius);
  background: white;
  color: var(--color-text);
  font-size: 1rem;
  font-weight: 500;
  appearance: none;
  cursor: pointer;
  transition: var(--transition-fast);
}

.time-select:focus {
  outline: none;
  border-color: var(--secondary-color);
  box-shadow: 0 0 0 3px rgba(52, 220, 59, 0.1);
}

.select-arrow {
  position: absolute;
  right: 1rem;
  top: 50%;
  transform: translateY(-50%);
  color: var(--color-text-secondary);
  pointer-events: none;
}

.find-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  background: linear-gradient(
    135deg,
    var(--secondary-color),
    var(--secondary-variant)
  );
  color: white;
  border: none;
  padding: 1.2rem 2rem;
  border-radius: var(--border-radius-large);
  font-size: 1.1rem;
  font-weight: 600;
  cursor: pointer;
  transition: var(--transition-normal);
  box-shadow: var(--box-shadow-light);
}

.find-btn:hover:not(:disabled) {
  background: var(--secondary-hover);
  transform: translateY(-2px);
  box-shadow: var(--box-shadow);
}

.find-btn:disabled {
  opacity: 0.7;
  cursor: not-allowed;
  transform: none;
}

.status-message {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  padding: 1rem;
  background: var(--background);
  border-radius: var(--border-radius);
  color: var(--color-text);
  font-weight: 500;
  border: 1px solid var(--color-border);
}

.info-tip {
  background: white;
  border-radius: var(--border-radius);
  padding: 1.5rem;
  display: flex;
  align-items: center;
  gap: 1rem;
  border: 1px solid var(--color-border);
  box-shadow: var(--box-shadow-light);
}

.info-tip i {
  color: var(--secondary-color);
  font-size: 1.5rem;
}

.info-tip p {
  margin: 0;
  color: var(--color-text);
  line-height: 1.5;
}

/* Chat Section */
.chat-section {
  display: flex;
  flex-direction: column;
  height: 75vh;
  background: white;
  border-radius: var(--border-radius-large);
  box-shadow: var(--box-shadow);
  overflow: hidden;
}

.chat-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  background: var(--background-secondary);
  border-bottom: 2px solid var(--color-border);
}

.session-info {
  display: flex;
  align-items: center;
  gap: 2rem;
  flex: 1;
}

.partner-info {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.partner-avatar {
  width: 50px;
  height: 50px;
  background: linear-gradient(
    135deg,
    var(--primary-color),
    var(--primary-variant)
  );
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--on-primary);
  font-size: 1.2rem;
}

.partner-details h3 {
  margin: 0 0 0.25rem 0;
  color: var(--color-heading);
  font-size: 1.2rem;
}

.session-label {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: var(--color-text-secondary);
  font-size: 0.9rem;
}

.timer-container {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.timer-display {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 2.2rem;
  font-weight: 700;
  color: var(--color-success);
  font-family: "Courier New", monospace;
}

.timer-display.warning {
  color: var(--color-error);
  animation: blink 1s infinite;
}

@keyframes blink {
  0%,
  50% {
    opacity: 1;
  }
  51%,
  100% {
    opacity: 0.5;
  }
}

.timer-warning {
  background: rgba(255, 193, 7, 0.1);
  color: var(--color-warning);
  padding: 0.5rem 1rem;
  border-radius: var(--border-radius);
  font-size: 0.8rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  border: 1px solid rgba(255, 193, 7, 0.3);
}

.btn-end {
  background: var(--color-error);
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: var(--border-radius);
  cursor: pointer;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  transition: var(--transition-fast);
}

.btn-end:hover {
  background: #c82333;
  transform: translateY(-1px);
}

/* Chat Messages */
.chat-messages {
  flex: 1;
  padding: 1.5rem;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 1rem;
  background: var(--background);
}

.message {
  display: flex;
  gap: 0.75rem;
  align-items: flex-start;
  max-width: 75%;
}

.own-message {
  align-self: flex-end;
  flex-direction: row-reverse;
}

.message-avatar {
  width: 35px;
  height: 35px;
  background: var(--primary-variant);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 0.9rem;
  flex-shrink: 0;
}

.own-message .message-avatar {
  background: var(--secondary-color);
}

.message-bubble {
  background: white;
  border-radius: var(--border-radius-large);
  padding: 1rem;
  box-shadow: var(--box-shadow-light);
  max-width: 100%;
}

.own-message .message-bubble {
  background: var(--secondary-color);
  color: white;
}

.message-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
  font-size: 0.8rem;
}

.sender {
  font-weight: 600;
}

.timestamp {
  opacity: 0.7;
}

.message-content {
  word-wrap: break-word;
  line-height: 1.4;
}

/* Typing Indicator */
.typing-indicator {
  display: flex;
  gap: 0.75rem;
  align-items: center;
  max-width: 200px;
}

.typing-avatar {
  width: 35px;
  height: 35px;
  background: var(--primary-variant);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-size: 0.9rem;
}

.typing-bubble {
  background: white;
  border-radius: var(--border-radius-large);
  padding: 1rem;
  box-shadow: var(--box-shadow-light);
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.typing-animation {
  display: flex;
  gap: 2px;
}

.typing-animation span {
  width: 4px;
  height: 4px;
  background: var(--color-text-secondary);
  border-radius: 50%;
  animation: typing 1.4s infinite ease-in-out;
}

.typing-animation span:nth-child(2) {
  animation-delay: 0.2s;
}

.typing-animation span:nth-child(3) {
  animation-delay: 0.4s;
}

@keyframes typing {
  0%,
  60%,
  100% {
    transform: scale(0.8);
    opacity: 0.5;
  }
  30% {
    transform: scale(1);
    opacity: 1;
  }
}

.typing-text {
  font-size: 0.8rem;
  color: var(--color-text-secondary);
  font-style: italic;
}

/* Chat Input */
.chat-input {
  padding: 1.5rem;
  background: var(--background-secondary);
  border-top: 1px solid var(--color-border);
}

.input-wrapper {
  display: flex;
  gap: 0.75rem;
}

.message-input {
  flex: 1;
  padding: 1rem 1.5rem;
  border: 2px solid var(--color-border);
  border-radius: var(--border-radius-large);
  outline: none;
  font-size: 1rem;
  background: white;
  color: var(--color-text);
  transition: var(--transition-fast);
}

.message-input:focus {
  border-color: var(--secondary-color);
  box-shadow: 0 0 0 3px rgba(52, 220, 59, 0.1);
}

.btn-send {
  background: var(--secondary-color);
  color: white;
  border: none;
  padding: 1rem 1.5rem;
  border-radius: var(--border-radius-large);
  cursor: pointer;
  transition: var(--transition-fast);
  display: flex;
  align-items: center;
  justify-content: center;
}

.btn-send:hover:not(:disabled) {
  background: var(--secondary-hover);
  transform: translateY(-1px);
}

.btn-send:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Modal */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.6);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  backdrop-filter: blur(4px);
}

.confirmation-modal {
  background: white;
  border-radius: var(--border-radius-large);
  padding: 2rem;
  max-width: 450px;
  width: 90%;
  box-shadow: var(--box-shadow);
  text-align: center;
}

.modal-icon {
  width: 60px;
  height: 60px;
  background: rgba(220, 53, 69, 0.1);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 1.5rem;
  color: var(--color-error);
  font-size: 1.5rem;
}

.confirmation-modal h3 {
  color: var(--color-heading);
  margin-bottom: 1rem;
  font-size: 1.5rem;
}

.confirmation-modal p {
  color: var(--color-text-secondary);
  margin-bottom: 1.5rem;
  line-height: 1.5;
}

.warning-box {
  background: rgba(255, 193, 7, 0.1);
  border: 1px solid rgba(255, 193, 7, 0.3);
  border-radius: var(--border-radius);
  padding: 1rem;
  margin: 1.5rem 0;
  display: flex;
  gap: 0.75rem;
  text-align: left;
}

.warning-box i {
  color: var(--color-warning);
  margin-top: 0.25rem;
}

.warning-content p {
  margin: 0 0 0.5rem 0;
  font-weight: 600;
}

.warning-content ul {
  margin: 0;
  padding-left: 1.5rem;
}

.warning-content li {
  margin-bottom: 0.25rem;
}

.modal-buttons {
  display: flex;
  gap: 1rem;
  justify-content: center;
}

.btn-cancel,
.btn-confirm {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: var(--border-radius);
  cursor: pointer;
  font-weight: 600;
  transition: var(--transition-fast);
}

.btn-cancel {
  background: var(--color-border);
  color: var(--color-text);
}

.btn-cancel:hover {
  background: var(--color-hover);
}

.btn-confirm {
  background: var(--color-error);
  color: white;
}

.btn-confirm:hover {
  background: #c82333;
}

/* Dark Mode Support */
@media (prefers-color-scheme: dark) {
  .pairing-card,
  .info-tip,
  .chat-section,
  .message-bubble,
  .typing-bubble,
  .confirmation-modal {
    background: var(--background);
    color: var(--color-text);
  }

  .message-input,
  .time-select {
    background: var(--background-secondary);
  }
}

/* Responsive Design */
@media (max-width: 768px) {
  .sync-wrapper {
    padding: 1rem;
  }

  .pairing-header h2 {
    font-size: 2rem;
  }

  .pairing-card {
    padding: 1.5rem;
  }

  .study-image {
    max-width: 100%;
  }

  .chat-section {
    height: 70vh;
  }

  .session-info {
    flex-direction: column;
    gap: 1rem;
  }

  .chat-header {
    padding: 1rem;
  }

  .modal-buttons {
    flex-direction: column;
  }

  .btn-cancel,
  .btn-confirm {
    width: 100%;
  }
}

@media (max-width: 480px) {
  .header-icon {
    width: 60px;
    height: 60px;
    font-size: 1.5rem;
  }

  .pairing-header h2 {
    font-size: 1.75rem;
  }

  .subtitle {
    font-size: 1rem;
  }
}
</style>
