<template>
  <div class="home-wrapper">
    <img
      class="image-1"
      src="https://media.istockphoto.com/id/2225813956/photo/group-of-students-collaborating-during-study-session-in-library-setting.jpg?s=612x612&w=0&k=20&c=Ueo8vMnxvbvPFy6Oefc4HBaAv1G1haGnZ-EGmLIqCuo="
      alt="Students studying"
    />
    <h2>Helping students solve procrastination by studying with peers</h2>
    <button @click="goToIn" class="/signin">Login</button>
    <button @click="goToUp" class="/signup">sign up</button>
  </div>
</template>

<script setup>
import { useRouter } from "vue-router";
const router = useRouter();

const goToIn = () => {
  router.push("/signin");
};
const goToUp = () => {
  router.push("/signup");
};
</script>

<style scoped>
.home-wrapper {
  display: flex;
  flex-direction: column; /* stack image and text */
  align-items: center; /* horizontal centring */
  height: 100vh; /* full screen height */
  text-align: center; /* centre the h2 text */
}

.image-1 {
  max-width: 400px;
  width: 100%;
  height: auto;
  margin-bottom: 20px; /* space between image and heading */
}

h2 {
  font-size: 1.5rem;
  color: #333;
}

.btn-el {
  background-color: var(--secondary-color); /* green */
  /* border: none; */
  font-family: "Nunito", serif;
  font-weight: 400;
  color: var(--primary-color);
  font-style: normal;
  padding: 10px 20px;
  border-radius: 5px;
  cursor: pointer;
}
</style>
