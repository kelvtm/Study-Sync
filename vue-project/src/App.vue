<template>
  <div id="app">
    <!-- Show header and nav only for authenticated pages -->
    <template v-if="!isPublicPage">
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
            <h1>
              <span style="color: var(--secondary-color)">Study</span>Sync
            </h1>
          </div>

          <!-- Notification Icon (bigger) -->
          <button class="notification-btn" @click="toggleNotifications">
            <i class="fas fa-bell"></i>
            <span v-if="unreadCount > 0" class="notification-badge">{{
              unreadCount
            }}</span>
          </button>
        </div>
      </header>

      <!-- Notification Dropdown -->
      <div v-if="notificationsOpen" class="notifications-dropdown">
        <div class="notifications-header">
          <h3>Notifications</h3>
          <button @click="markAllAsRead" class="mark-read-btn">
            Mark all read
          </button>
        </div>

        <div class="notifications-list">
          <div v-if="notifications.length === 0" class="empty-notifications">
            <i class="fas fa-bell-slash"></i>
            <p>No notifications yet</p>
          </div>

          <div
            v-for="notification in notifications"
            :key="notification._id"
            :class="['notification-item', { unread: !notification.isRead }]"
            @click="handleNotificationClick(notification)"
          >
            <div class="notification-icon">
              <i :class="getNotificationIcon(notification.type)"></i>
            </div>
            <div class="notification-content">
              <p class="notification-message">{{ notification.message }}</p>
              <span class="notification-time">{{
                formatNotificationTime(notification.createdAt)
              }}</span>
            </div>
            <button
              @click.stop="deleteNotification(notification._id)"
              class="delete-notification-btn"
            >
              ✕
            </button>
          </div>
        </div>
      </div>

      <!-- Overlay for notifications -->
      <div
        v-if="notificationsOpen"
        class="notifications-overlay"
        @click="closeNotifications"
      ></div>

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
    </template>

    <!-- Main Content Area -->
    <main :class="isPublicPage ? 'public-content' : 'main-content'">
      <RouterView />
    </main>
  </div>
</template>

<script setup>
import { RouterLink, RouterView, useRouter, useRoute } from "vue-router";
import { ref, computed, onMounted, watch } from "vue";
import axios from "axios";

const router = useRouter();
const route = useRoute();
const navOpen = ref(false);
const notificationsOpen = ref(false);

// Real notifications from API
const notifications = ref([]);
const userId = localStorage.getItem("userId");

// Define public pages (pages without header/nav)
const publicPages = ["/", "/signin", "/signup"];

// Computed property to check if current page is public
const isPublicPage = computed(() => {
  return publicPages.includes(route.path);
});

// Watch route changes to close nav/notifications
watch(
  () => route.path,
  () => {
    closeNav();
    closeNotifications();
  }
);

// Computed property for unread notification count
const unreadCount = computed(() => {
  return notifications.value.filter((n) => !n.isRead).length;
});

// Fetch notifications from API
const fetchNotifications = async () => {
  if (!userId) return;

  try {
    const response = await axios.get(
      `http://localhost:3000/api/notifications?userId=${userId}`
    );
    notifications.value = response.data.notifications;
    console.log("Notifications fetched:", notifications.value.length);
  } catch (error) {
    console.error("Error fetching notifications:", error);
  }
};

// Mark notification as read
const markAsRead = async (notificationId) => {
  try {
    await axios.put(
      `http://localhost:3000/api/notifications/${notificationId}/read`,
      {
        userId,
      }
    );

    const notification = notifications.value.find(
      (n) => n._id === notificationId
    );
    if (notification) {
      notification.isRead = true;
      notification.readAt = new Date().toISOString();
    }
  } catch (error) {
    console.error("Error marking notification as read:", error);
  }
};

const toggleNav = () => {
  navOpen.value = !navOpen.value;
  if (navOpen.value) {
    notificationsOpen.value = false;
  }
};

const closeNav = () => {
  navOpen.value = false;
};

const toggleNotifications = () => {
  notificationsOpen.value = !notificationsOpen.value;
  if (notificationsOpen.value) {
    navOpen.value = false;
    fetchNotifications();
  }
};

const closeNotifications = () => {
  notificationsOpen.value = false;
};

const handleNotificationClick = async (notification) => {
  await markAsRead(notification._id);
  router.push("/task");
  closeNotifications();
};

const markAllAsRead = async () => {
  try {
    await axios.put("http://localhost:3000/api/notifications/read-all", {
      userId,
    });

    notifications.value.forEach((n) => {
      n.isRead = true;
      n.readAt = new Date().toISOString();
    });
  } catch (error) {
    console.error("Error marking all as read:", error);
  }
};

const deleteNotification = async (notificationId) => {
  try {
    await axios.delete(
      `http://localhost:3000/api/notifications/${notificationId}?userId=${userId}`
    );

    const index = notifications.value.findIndex(
      (n) => n._id === notificationId
    );
    if (index > -1) {
      notifications.value.splice(index, 1);
    }
  } catch (error) {
    console.error("Error deleting notification:", error);
  }
};

const getNotificationIcon = (type) => {
  const icons = {
    deadline: "fas fa-clock",
    success: "fas fa-check-circle",
    warning: "fas fa-exclamation-triangle",
    info: "fas fa-info-circle",
  };
  return icons[type] || "fas fa-bell";
};

const formatNotificationTime = (timestamp) => {
  const date = new Date(timestamp);
  const now = new Date();
  const diffMs = now - date;
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 1) return "Just now";
  if (diffMins < 60) return `${diffMins}m ago`;
  if (diffHours < 24) return `${diffHours}h ago`;
  if (diffDays < 7) return `${diffDays}d ago`;
  return date.toLocaleDateString();
};

// Fetch notifications on mount and set up auto-refresh
onMounted(() => {
  if (!isPublicPage.value) {
    fetchNotifications();

    setInterval(() => {
      if (!isPublicPage.value) {
        fetchNotifications();
      }
    }, 30000);
  }
});
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
  height: 80px;
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
  font-size: 2rem;
  font-weight: 700;
  color: var(--color-heading);
  letter-spacing: 1px;
}

/* Notification Button */
.notification-btn {
  background: none;
  border: 2px solid var(--color-border);
  border-radius: var(--border-radius);
  color: var(--color-text);
  cursor: pointer;
  padding: 12px;
  font-size: 1.5rem;
  transition: var(--transition-fast);
  min-width: 50px;
  height: 50px;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
}

.notification-btn:hover {
  background-color: var(--color-hover);
  border-color: var(--color-border-hover);
  transform: translateY(-1px);
}

.notification-badge {
  position: absolute;
  top: 5px;
  right: 5px;
  background: var(--color-error);
  color: white;
  font-size: 0.7rem;
  font-weight: bold;
  padding: 2px 6px;
  border-radius: 10px;
  min-width: 18px;
  text-align: center;
}

/* Notifications Dropdown */
.notifications-dropdown {
  position: fixed;
  top: 90px;
  right: 20px;
  width: 400px;
  max-height: 500px;
  background: var(--background-secondary);
  border: 2px solid var(--color-border);
  border-radius: var(--border-radius-large);
  box-shadow: var(--box-shadow);
  z-index: 1100;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.notifications-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px 20px;
  border-bottom: 1px solid var(--color-border);
  background: var(--background);
}

.notifications-header h3 {
  margin: 0;
  color: var(--color-heading);
  font-size: 1.1rem;
}

.mark-read-btn {
  background: none;
  border: none;
  color: var(--secondary-color);
  cursor: pointer;
  font-size: 0.85rem;
  font-weight: 600;
  padding: 4px 8px;
  border-radius: 4px;
  transition: var(--transition-fast);
}

.mark-read-btn:hover {
  background: rgba(52, 220, 59, 0.1);
}

.notifications-list {
  overflow-y: auto;
  max-height: 420px;
}

.empty-notifications {
  text-align: center;
  padding: 40px 20px;
  color: var(--color-text-secondary);
}

.empty-notifications i {
  font-size: 3rem;
  margin-bottom: 10px;
  opacity: 0.5;
}

.notification-item {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  padding: 15px 20px;
  border-bottom: 1px solid var(--color-border);
  cursor: pointer;
  transition: var(--transition-fast);
  position: relative;
}

.notification-item:hover {
  background: var(--color-hover);
}

.notification-item.unread {
  background: rgba(52, 220, 59, 0.05);
}

.notification-item.unread::before {
  content: "";
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 4px;
  background: var(--secondary-color);
}

.notification-icon {
  flex-shrink: 0;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: rgba(52, 220, 59, 0.1);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--secondary-color);
  font-size: 1rem;
}

.notification-content {
  flex: 1;
}

.notification-message {
  margin: 0 0 5px 0;
  color: var(--color-text);
  font-size: 0.9rem;
  line-height: 1.4;
}

.notification-time {
  font-size: 0.75rem;
  color: var(--color-text-secondary);
}

.delete-notification-btn {
  flex-shrink: 0;
  background: none;
  border: none;
  color: var(--color-text-secondary);
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 0.9rem;
  opacity: 0;
  transition: var(--transition-fast);
}

.notification-item:hover .delete-notification-btn {
  opacity: 1;
}

.delete-notification-btn:hover {
  background: var(--color-error);
  color: white;
}

.notifications-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: transparent;
  z-index: 1050;
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
  padding: 100px 0 2rem 0;
}

/* User and Profile Section */
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

.nav-divider {
  height: 1px;
  background: var(--color-border);
  margin: 0 1.5rem 1rem;
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

/* Public Content (for landing, signin, signup) */
.public-content {
  flex: 1;
  min-height: 100vh;
  width: 100%;
  padding: 0;
  margin: 0;
}

/* Main Content (for authenticated pages) */
.main-content {
  flex: 1;
  margin-top: 80px;
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

  .notifications-dropdown {
    right: 10px;
    width: calc(100vw - 20px);
    max-width: 400px;
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

  .notifications-dropdown {
    background: var(--background);
  }
}
</style>
