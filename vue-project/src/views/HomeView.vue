<script setup></script>

<template>
  <main style="text-align: center; padding: 2rem">
    <h1>Welcome to Study Sync!</h1>
    <p>Your platform to organize and sync your study sessions.</p>
    <img
      src="https://images.unsplash.com/photo-1513258496099-48168024aec0?auto=format&fit=crop&w=600&q=80"
      alt="Study"
      style="max-width: 400px; width: 100%; border-radius: 8px; margin: 2rem 0"
    />
    <router-link to="/about">
      <button
        style="
          padding: 0.5rem 1.5rem;
          font-size: 1rem;
          border-radius: 4px;
          background: #42b983;
          color: white;
          border: none;
          cursor: pointer;
        "
      >
        Learn More
      </button>
    </router-link>
  </main>
</template>
