<template>
  <div class="home-wrapper">
    <img
      class="image-1"
      src="https://media.istockphoto.com/id/1347747136/vector/group-of-students-studying.jpg?s=612x612&w=0&k=20&c=t8UwXDXTCu2O-2mOLE8_aQ7KTXxjuUk_WgiR0cS6pSk="
      alt="Students studying"
    />
    <h2>Helping students solve procrastination by studying with peers</h2>
    <button @click="goToSync" class="btn-el">start pair session</button>
  </div>
</template>

<script setup>
import { useRouter } from "vue-router";
const router = useRouter();

const goToSync = () => {
  router.push("/sync");
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
