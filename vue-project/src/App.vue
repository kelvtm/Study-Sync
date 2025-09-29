<template>
  <div id="app">
    <!-- Top Header Bar -->
    <header class="top-header">
      <div class="header-content">
        <!-- Hamburger Menu Button -->
        <button
          class="hamburger-btn"
          @click="toggleNav"
          :class="{ active: navOpen }"
        >
          <span></span>
          <span></span>
          <span></span>
        </button>

        <!-- App Title -->
        <div class="app-title">
          <h1><span style="color: var(--secondary-color)">Study</span>Sync</h1>
        </div>

        <!-- Notification Icon (bigger) -->
        <button class="notification-btn">
          <i class="fas fa-bell"></i>
        </button>
      </div>
    </header>

    <!-- Slide-out Navigation -->
    <nav class="slide-nav" :class="{ open: navOpen }">
      <div class="nav-content">
        <!-- User Icon and profile grouped together -->
        <div class="user-profile-section">
          <i class="fas fa-user-circle user-icon"></i>
          <RouterLink to="/profile" @click="closeNav">
            <i class="fas fa-user"></i>
            Profile
          </RouterLink>
        </div>

        <div class="nav-divider"></div>

        <!-- Other Navigation Links -->
        <div class="nav-links">
          <RouterLink to="/sync" @click="closeNav">
            <i class="fas fa-home"></i>
            Home
          </RouterLink>
          <RouterLink to="/leaderboard" @click="closeNav">
            <i class="fas fa-trophy"></i>
            Leaderboard
          </RouterLink>
          <RouterLink to="/task" @click="closeNav">
            <i class="fas fa-tasks"></i>
            Task Breakdown
          </RouterLink>
        </div>
      </div>
    </nav>

    <!-- Overlay -->
    <div
      class="nav-overlay"
      :class="{ active: navOpen }"
      @click="closeNav"
    ></div>

    <!-- Main Content Area -->
    <main class="main-content">
      <RouterView />
    </main>
  </div>
</template>

<script setup>
import { RouterLink, RouterView } from "vue-router";
import { ref } from "vue";

const navOpen = ref(false);

const toggleNav = () => {
  navOpen.value = !navOpen.value;
};

const closeNav = () => {
  navOpen.value = false;
};
</script>

<style scoped>
#app {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

/* Top Header Bar */
.top-header {
  background: var(--background-secondary);
  border-bottom: 2px solid var(--color-border);
  box-shadow: var(--box-shadow-light);
  z-index: 1000;
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  height: 80px; /* Bigger header */
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 1.5rem;
  height: 100%;
  max-width: 1200px;
  margin: 0 auto;
}

/* Hamburger Button */
.hamburger-btn {
  background: none;
  border: none;
  cursor: pointer;
  padding: 8px;
  display: flex;
  flex-direction: column;
  justify-content: space-around;
  width: 32px;
  height: 32px;
  transition: var(--transition-normal);
}

.hamburger-btn span {
  display: block;
  height: 3px;
  width: 100%;
  background: var(--color-text);
  border-radius: 2px;
  transition: var(--transition-fast);
  transform-origin: center;
}

.hamburger-btn.active span:nth-child(1) {
  transform: rotate(45deg) translate(6px, 6px);
}

.hamburger-btn.active span:nth-child(2) {
  opacity: 0;
}

.hamburger-btn.active span:nth-child(3) {
  transform: rotate(-45deg) translate(6px, -6px);
}

/* App Title */
.app-title h1 {
  font-size: 2rem; /* Bigger title */
  font-weight: 700;
  color: var(--color-heading);
  letter-spacing: 1px;
}

/* Notification Button (bigger) */
.notification-btn {
  background: none;
  border: 2px solid var(--color-border);
  border-radius: var(--border-radius);
  color: var(--color-text);
  cursor: pointer;
  padding: 12px;
  font-size: 1.5rem; /* Bigger notification icon */
  transition: var(--transition-fast);
  min-width: 50px;
  height: 50px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.notification-btn:hover {
  background-color: var(--color-hover);
  border-color: var(--color-border-hover);
  transform: translateY(-1px);
}

/* Slide-out Navigation */
.slide-nav {
  position: fixed;
  top: 0;
  left: -300px;
  width: 300px;
  height: 100vh;
  background: var(--background-secondary);
  border-right: 2px solid var(--color-border);
  box-shadow: var(--box-shadow);
  transition: var(--transition-normal);
  z-index: 1100;
  overflow-y: auto;
}

.slide-nav.open {
  left: 0;
}

.nav-content {
  padding: 100px 0 2rem 0; /* Account for header height */
}

/* User and Home Section */
.user-profile-section {
  padding: 0 1.5rem 1rem 1.5rem;
  display: flex;
  align-items: center;
  gap: 1rem;
  border-bottom: 1px solid var(--color-border);
  margin-bottom: 1rem;
}

.user-icon {
  font-size: 2.5rem;
  color: var(--primary-variant);
}

.user-profile-section a {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 1rem;
  text-decoration: none;
  color: var(--color-text);
  border-radius: var(--border-radius);
  transition: var(--transition-fast);
  font-weight: 600;
  font-size: 1.1rem;
  flex: 1;
}

.user-profile-section a:hover {
  background-color: var(--color-hover);
}

/* Navigation Links */
.nav-links {
  padding: 0 1.5rem;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.nav-links a {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.875rem 1rem;
  text-decoration: none;
  color: var(--color-text);
  border-radius: var(--border-radius);
  transition: var(--transition-fast);
  font-weight: 500;
  letter-spacing: 0.5px;
}

.nav-links a:hover {
  background-color: var(--color-hover);
  transform: translateX(4px);
}

.nav-links a.router-link-exact-active {
  background-color: var(--primary-color);
  color: var(--on-primary);
  font-weight: 600;
}

.nav-links a.router-link-exact-active:hover {
  background-color: var(--primary-color);
  transform: translateX(4px);
}

.nav-links a i {
  width: 20px;
  text-align: center;
}

/* Navigation Overlay */
.nav-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: rgba(0, 0, 0, 0.5);
  z-index: 1050;
  opacity: 0;
  visibility: hidden;
  transition: var(--transition-normal);
}

.nav-overlay.active {
  opacity: 1;
  visibility: visible;
}

/* Main Content */
.main-content {
  flex: 1;
  margin-top: 80px; /* Account for fixed header */
  padding: 2rem 1.5rem;
  max-width: 1200px;
  margin-left: auto;
  margin-right: auto;
  width: 100%;
}

/* Responsive Design */
@media (max-width: 768px) {
  .header-content {
    padding: 0 1rem;
  }

  .app-title h1 {
    font-size: 1.5rem;
  }

  .slide-nav {
    width: 280px;
    left: -280px;
  }

  .main-content {
    padding: 1.5rem 1rem;
  }
}

@media (min-width: 1024px) {
  .header-content {
    padding: 0 2rem;
  }

  .main-content {
    padding: 2rem;
  }
}

/* Dark mode adjustments */
@media (prefers-color-scheme: dark) {
  .slide-nav {
    background: var(--background);
  }

  .top-header {
    background: var(--background);
  }
}
</style>
