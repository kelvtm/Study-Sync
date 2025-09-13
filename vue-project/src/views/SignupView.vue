<template>
  <div>
    <h2>Create Account</h2>
    <form @submit.prevent="signup">
      <input type="email" v-model="email" placeholder="Email" required /><br />
      <input
        type="password"
        v-model="password"
        placeholder="Password"
        required
      /><br />
      <button type="submit">Sign Up</button>
    </form>
    <div>{{ message }}</div>
  </div>
</template>

<script setup>
import { ref } from "vue";
import { useRouter } from "vue-router";

const email = ref("");
const password = ref("");
const message = ref("");
const router = useRouter();

const signup = async () => {
  try {
    const res = await fetch("http://localhost:3000/signup", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: email.value, password: password.value }),
    });
    const data = await res.json();
    message.value = data.message;

    if (res.ok) {
      // after signup, redirect to login
      router.push("/");
    }
  } catch (err) {
    message.value = "Error: " + err.message;
  }
};
</script>
