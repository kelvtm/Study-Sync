<script setup>
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
</template>
