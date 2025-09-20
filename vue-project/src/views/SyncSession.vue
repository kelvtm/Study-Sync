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
        <h3>Study Session with {{ partnerEmail }}</h3>
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
              message.userId === userId ? "You" : partnerEmail
            }}</span>
            <span class="timestamp">{{ formatTime(message.timestamp) }}</span>
          </div>
          <div class="message-content">{{ message.message }}</div>
        </div>

        <div v-if="partnerTyping" class="typing-indicator">
          {{ partnerEmail }} is typing...
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
const messages = ref([]);
const newMessage = ref("");
const partnerTyping = ref(false);
const messagesContainer = ref(null);

// Socket and user info
let socket = null;
const userId = localStorage.getItem("userId");
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
    alert("Study session has ended");
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

    // Find partner's email
    const partner = session.participants.find((p) => p._id !== userId);
    partnerEmail.value = partner ? partner.email : "Unknown";

    activeSession.value = {
      id: sessionId,
      ...session,
    };

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

// End session
const endSession = async () => {
  if (!activeSession.value) return;

  try {
    await axios.put(
      `http://localhost:3000/api/sessions/${activeSession.value.id}/end`,
      {
        userId,
      }
    );
    resetSession();
  } catch (error) {
    console.error("Error ending session:", error);
  }
};

// Reset session state
const resetSession = () => {
  activeSession.value = null;
  partnerEmail.value = "";
  messages.value = [];
  newMessage.value = "";
  partnerTyping.value = false;
  isSearching.value = false;
  statusMessage.value = "";
};

// Scroll to bottom of messages
const scrollToBottom = () => {
  nextTick(() => {
    if (messagesContainer.value) {
      messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight;
    }
  });
};

// Format timestamp
const formatTime = (timestamp) => {
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

.chat-header h3 {
  margin: 0;
  color: #333;
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
</style>
