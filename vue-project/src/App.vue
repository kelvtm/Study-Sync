<script setup>
import { RouterLink, RouterView } from "vue-router";
import HelloWorld from "./components/HelloWorld.vue";
</script>

<template>
  <header>
    <div class="wrapper">
      <h1 class="heading">
        <span style="color: var(--secondary-color)">Study</span>
        Sync
      </h1>
      <HelloWorld
        msg="Helping students solve procastition by studying with peers"
      />

      <nav>
        <RouterLink to="/">Home</RouterLink>
        <RouterLink to="/about">Task Deasline</RouterLink>
        <RouterLink to="/about">Peer Charts</RouterLink>
        <RouterLink to="/about">Task Completion</RouterLink>
      </nav>
    </div>
  </header>

  <RouterView />
</template>

<style>
nav {
  /* z-index: 10; */
  /* position: fixed; */
  /* font-family: "Oswald", sans-serif; */
  /* font-size: 24px; */
  /* white-space: nowrap; */
  letter-spacing: 3px;
  display: flex;
  flex-direction: column;
  gap: 15px;
  padding: 25px;
  /* width: 100vw; */
  /* background: rgb(255 255 255 / 50%); */
}

nav a.router-link-exact-active {
  color: var(--color-text);
}

nav a.router-link-exact-active:hover {
  background-color: transparent;
}

nav a {
  display: inline-block;
  padding: 0 1rem;
  border-left: 1px solid var(--color-border);
}

nav a:first-of-type {
  border: 0;
}

@media (min-width: 1024px) {
  header {
    display: flex;
    place-items: center;
  }
}
</style>
