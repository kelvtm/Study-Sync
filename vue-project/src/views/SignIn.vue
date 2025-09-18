<template>
  <div class="home">
    <h2>Login</h2>
    <form @submit.prevent="login">
      <input type="email" v-model="email" placeholder="Email" required /><br />
      <input type="password" v-model="password" placeholder="Password" required /><br />
      <button type="submit">Login</button>
    </form>
    <div v-if="message">{{ message }}</div>

    <!-- ✅ Button to redirect -->
    <button @click="goToSignup">Create Account</button>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from "vue-router"

const email = ref('')
const password = ref('')
const message = ref('')
const router = useRouter()

const login = async () => {
  try {
    const res = await fetch('http://localhost:3000/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: email.value,
        password: password.value,
      }),
    })
    const data = await res.json()
    message.value = data.message || 'Login attempt complete'
     if (res.ok) {
      // ✅ redirect to /about after successful login
      router.push("/studysync")
    }
  } catch (err) {
    message.value = 'Error: ' + err.message
  }
}

const goToSignup = () => {
  router.push("/signup")
}
</script>

<style scoped>
.home {
  max-width: 400px;
  margin: 2rem auto;
  padding: 1rem;
  border: 1px solid #ddd;
  border-radius: 8px;
}

input {
  margin: 0.5rem 0;
  padding: 0.5rem;
  width: 100%;
  box-sizing: border-box;
}

button {
  padding: 0.5rem 1rem;
  cursor: pointer;
}
</style>
