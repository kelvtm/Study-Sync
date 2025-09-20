<!-- <script setup>
import { ref, onMounted } from "vue";
import { io } from "socket.io-client";

const socket = io("http://localhost:3000");
const messages = ref([]);
const newMessage = ref("");

onMounted(() => {
  socket.on("chat message", (msg) => {
    messages.value.push(msg);
  });
});

function sendMessage() {
  if (newMessage.value.trim()) {
    socket.emit("chat message", newMessage.value);
    newMessage.value = "";
  }
}
</script>

<template>
  <div>
    <h2>Pair Session Test</h2>
    <ul>
      <li v-for="(msg, i) in messages" :key="i">{{ msg }}</li>
    </ul>
    <input v-model="newMessage" placeholder="Type message..." />
    <button @click="sendMessage">Send</button>
  </div>
</template> -->

<template>
  <div class="sync-wrapper">
    <h2>Start a Pair Study Session</h2>

    <!-- Time Picker (optional for later use) -->
    <label for="time">Select session length:</label>
    <select v-model="sessionTime" id="time">
      <option value="25">25 mins</option>
      <option value="50">50 mins</option>
      <option value="90">90 mins</option>
    </select>

    <!-- Pairing Button -->
    <button @click="findPartner" class="btn-el">Find Partner</button>

    <!-- Status -->
    <p v-if="statusMessage">{{ statusMessage }}</p>
  </div>
</template>

<script setup>
import { ref } from "vue";
import axios from "axios";

const sessionTime = ref("25"); // default
const statusMessage = ref("");

// temporary: replace with logged-in user from your auth
const userId = localStorage.getItem("userId");

const findPartner = async () => {
  try {
    const res = await axios.post("http://localhost:3000/api/sessions/pair", {
      userId,
    });

    if (res.data.session.status === "waiting") {
      statusMessage.value = `Waiting for a partner...${userId}`;
    } else if (res.data.session.status === "active") {
      statusMessage.value = `Paired successfully! Session started ${userId}🎉`;
      // later: redirect to chat modal
    }
  } catch (err) {
    statusMessage.value = "Error: " + err.message;
  }
};
</script>

<style scoped>
.sync-wrapper {
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
}
</style>
