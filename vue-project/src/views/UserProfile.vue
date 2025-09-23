<template>
  <div class="profile-container">
    <!-- Loading State -->
    <div class="loading" v-if="loading">
      <div class="spinner"></div>
      <p>Loading your profile...</p>
    </div>

    <!-- Error State -->
    <div class="error" v-if="error && !loading">
      <div class="error-icon">⚠️</div>
      <h3>Failed to load profile</h3>
      <p>{{ error }}</p>
      <button @click="fetchUserStats" class="retry-btn">Try Again</button>
    </div>

    <!-- Profile Content -->
    <div v-if="!loading && !error && userStats">
      <div class="profile-header">
        <div class="profile-info">
          <div class="avatar">
            {{ userStats.user?.username?.charAt(0).toUpperCase() || "U" }}
          </div>
          <div class="user-details">
            <h1>{{ userStats.user?.username || "Unknown User" }}</h1>
            <p class="email">{{ userStats.user?.email || "" }}</p>
            <p class="member-since">
              Member since {{ formatDate(userStats.user?.createdAt) }}
            </p>
          </div>
        </div>
      </div>

      <div class="stats-grid">
        <!-- Total Study Time -->
        <div class="stat-card primary">
          <div class="stat-icon">⏱️</div>
          <div class="stat-content">
            <h3>{{ formatHours(userStats.stats?.totalStudyMinutes || 0) }}</h3>
            <p>Total Study Time</p>
          </div>
        </div>

        <!-- Completed Sessions -->
        <div class="stat-card success">
          <div class="stat-icon">✅</div>
          <div class="stat-content">
            <h3>{{ userStats.stats?.completedSessions || 0 }}</h3>
            <p>Completed Sessions</p>
          </div>
        </div>

        <!-- Current Streak -->
        <div class="stat-card warning">
          <div class="stat-icon">🔥</div>
          <div class="stat-content">
            <h3>{{ userStats.stats?.currentStreak || 0 }}</h3>
            <p>Day Streak</p>
          </div>
        </div>

        <!-- Longest Session -->
        <div class="stat-card info">
          <div class="stat-icon">🏆</div>
          <div class="stat-content">
            <h3>{{ formatMinutes(userStats.stats?.longestSession || 0) }}</h3>
            <p>Longest Session</p>
          </div>
        </div>

        <!-- Weekly Stats -->
        <div class="stat-card secondary">
          <div class="stat-icon">📅</div>
          <div class="stat-content">
            <h3>{{ formatHours(userStats.stats?.weeklyStudyMinutes || 0) }}</h3>
            <p>This Week</p>
          </div>
        </div>

        <!-- Quit Sessions (if any) -->
        <div
          class="stat-card danger"
          v-if="(userStats.stats?.quitSessions || 0) > 0"
        >
          <div class="stat-icon">⚠️</div>
          <div class="stat-content">
            <h3>{{ userStats.stats?.quitSessions || 0 }}</h3>
            <p>Early Quits</p>
          </div>
        </div>
      </div>

      <!-- Study Progress -->
      <div class="progress-section">
        <h2>Study Progress</h2>

        <div class="progress-card">
          <div class="progress-header">
            <h3>Completion Rate</h3>
            <span class="percentage">{{ completionRate }}%</span>
          </div>
          <div class="progress-bar">
            <div
              class="progress-fill"
              :style="{ width: completionRate + '%' }"
            ></div>
          </div>
          <p class="progress-description">
            {{ userStats.stats?.completedSessions || 0 }} completed out of
            {{ totalSessions }} total sessions
          </p>
        </div>

        <div class="progress-card">
          <div class="progress-header">
            <h3>Weekly Goal Progress</h3>
            <span class="percentage">{{ weeklyProgress }}%</span>
          </div>
          <div class="progress-bar">
            <div
              class="progress-fill weekly"
              :style="{ width: Math.min(weeklyProgress, 100) + '%' }"
            ></div>
          </div>
          <p class="progress-description">
            {{ formatHours(userStats.stats?.weeklyStudyMinutes || 0) }} of 10
            hours weekly goal
          </p>
        </div>
      </div>

      <!-- Achievements -->
      <div class="achievements-section">
        <h2>Achievements</h2>
        <div class="achievements-grid">
          <div
            v-for="achievement in achievements"
            :key="achievement.id"
            :class="['achievement', { unlocked: achievement.unlocked }]"
          >
            <div class="achievement-icon">{{ achievement.icon }}</div>
            <div class="achievement-content">
              <h4>{{ achievement.title }}</h4>
              <p>{{ achievement.description }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty State for No Data -->
    <div v-if="!loading && !error && !userStats" class="empty-state">
      <div class="empty-icon">👤</div>
      <h3>Profile not found</h3>
      <p>Unable to load your profile data.</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from "vue";
import axios from "axios";

// Reactive data
const userStats = ref(null);
const loading = ref(true);
const error = ref("");

// Get user ID from localStorage
const userId = localStorage.getItem("userId");

// Computed properties
const completionRate = computed(() => {
  if (!userStats.value?.stats) return 0;
  const total = totalSessions.value;
  if (total === 0) return 100;
  return Math.round((userStats.value.stats.completedSessions / total) * 100);
});

const totalSessions = computed(() => {
  if (!userStats.value?.stats) return 0;
  return (
    (userStats.value.stats.completedSessions || 0) +
    (userStats.value.stats.quitSessions || 0) +
    (userStats.value.stats.disconnectedSessions || 0)
  );
});

const weeklyProgress = computed(() => {
  if (!userStats.value?.stats) return 0;
  const weeklyMinutes = userStats.value.stats.weeklyStudyMinutes || 0;
  const weeklyGoal = 600; // 10 hours = 600 minutes
  return Math.round((weeklyMinutes / weeklyGoal) * 100);
});

const achievements = computed(() => {
  if (!userStats.value?.stats) return [];

  const stats = userStats.value.stats;

  return [
    {
      id: "first_session",
      title: "First Steps",
      description: "Complete your first study session",
      icon: "🌟",
      unlocked: (stats.completedSessions || 0) >= 1,
    },
    {
      id: "study_warrior",
      title: "Study Warrior",
      description: "Complete 10 study sessions",
      icon: "⚔️",
      unlocked: (stats.completedSessions || 0) >= 10,
    },
    {
      id: "time_master",
      title: "Time Master",
      description: "Study for 10+ hours total",
      icon: "⏰",
      unlocked: (stats.totalStudyMinutes || 0) >= 600,
    },
    {
      id: "streak_master",
      title: "Streak Master",
      description: "Maintain a 7-day study streak",
      icon: "🔥",
      unlocked: (stats.currentStreak || 0) >= 7,
    },
    {
      id: "marathon_runner",
      title: "Marathon Runner",
      description: "Complete a 90+ minute session",
      icon: "🏃‍♂️",
      unlocked: (stats.longestSession || 0) >= 90,
    },
    {
      id: "consistency_king",
      title: "Consistency King",
      description: "Study 20+ hours total",
      icon: "👑",
      unlocked: (stats.totalStudyMinutes || 0) >= 1200,
    },
  ];
});

// Methods
const fetchUserStats = async () => {
  if (!userId) {
    error.value = "Please log in to view your profile";
    loading.value = false;
    return;
  }

  loading.value = true;
  error.value = "";

  try {
    console.log("Fetching stats for user:", userId);
    const response = await axios.get(
      `http://localhost:3000/api/users/${userId}/stats`
    );
    console.log("Received user stats:", response.data);
    userStats.value = response.data;
  } catch (err) {
    console.error("Error fetching user stats:", err);
    if (err.response?.status === 404) {
      error.value = "User not found. Please log in again.";
    } else if (err.response?.status === 401) {
      error.value = "Unauthorized. Please log in again.";
    } else {
      error.value =
        err.response?.data?.message ||
        "Failed to load your stats. Please try again.";
    }
  } finally {
    loading.value = false;
  }
};

const formatHours = (minutes) => {
  if (!minutes || minutes === 0) return "0m";
  if (minutes < 60) return `${minutes}m`;
  const hours = Math.floor(minutes / 60);
  const remainingMinutes = minutes % 60;
  return remainingMinutes > 0 ? `${hours}h ${remainingMinutes}m` : `${hours}h`;
};

const formatMinutes = (minutes) => {
  return `${minutes || 0} min`;
};

const formatDate = (dateString) => {
  if (!dateString) return "Unknown";
  try {
    return new Date(dateString).toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  } catch (e) {
    return "Unknown";
  }
};

// Lifecycle
onMounted(() => {
  console.log("UserProfile component mounted, userId:", userId);
  fetchUserStats();
});
</script>

<style scoped>
.profile-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
}

.profile-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 20px;
  padding: 40px;
  color: white;
  margin-bottom: 30px;
}

.profile-info {
  display: flex;
  align-items: center;
  gap: 20px;
}

.avatar {
  width: 80px;
  height: 80px;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 2rem;
  font-weight: bold;
  backdrop-filter: blur(10px);
}

.user-details h1 {
  margin: 0 0 5px 0;
  font-size: 2rem;
}

.email {
  opacity: 0.9;
  margin: 5px 0;
  font-size: 1.1rem;
}

.member-since {
  opacity: 0.8;
  margin: 5px 0 0 0;
  font-size: 0.9rem;
}

/* Stats Grid */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
  margin-bottom: 40px;
}

.stat-card {
  background: white;
  border-radius: 16px;
  padding: 25px;
  display: flex;
  align-items: center;
  gap: 15px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  border-left: 4px solid;
  transition: transform 0.2s ease;
}

.stat-card:hover {
  transform: translateY(-2px);
}

.stat-card.primary {
  border-left-color: #007bff;
}
.stat-card.success {
  border-left-color: #28a745;
}
.stat-card.warning {
  border-left-color: #ffc107;
}
.stat-card.info {
  border-left-color: #17a2b8;
}
.stat-card.secondary {
  border-left-color: #6c757d;
}
.stat-card.danger {
  border-left-color: #dc3545;
}

.stat-icon {
  font-size: 2.5rem;
}

.stat-content h3 {
  margin: 0 0 5px 0;
  font-size: 2rem;
  color: #333;
}

.stat-content p {
  margin: 0;
  color: #666;
  font-size: 0.9rem;
}

/* Progress Section */
.progress-section {
  margin-bottom: 40px;
}

.progress-section h2 {
  margin-bottom: 20px;
  color: #333;
}

.progress-card {
  background: white;
  border-radius: 16px;
  padding: 25px;
  margin-bottom: 20px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
}

.progress-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 15px;
}

.progress-header h3 {
  margin: 0;
  color: #333;
}

.percentage {
  font-size: 1.2rem;
  font-weight: bold;
  color: #007bff;
}

.progress-bar {
  height: 12px;
  background-color: #e9ecef;
  border-radius: 6px;
  overflow: hidden;
  margin-bottom: 10px;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #007bff, #0056b3);
  border-radius: 6px;
  transition: width 0.3s ease;
}

.progress-fill.weekly {
  background: linear-gradient(90deg, #28a745, #1e7e34);
}

.progress-description {
  color: #666;
  font-size: 0.9rem;
  margin: 0;
}

/* Achievements */
.achievements-section {
  margin-bottom: 40px;
}

.achievements-section h2 {
  margin-bottom: 20px;
  color: #333;
}

.achievements-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
}

.achievement {
  background: white;
  border-radius: 16px;
  padding: 20px;
  display: flex;
  align-items: center;
  gap: 15px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  opacity: 0.5;
  transition: all 0.3s ease;
}

.achievement.unlocked {
  opacity: 1;
  border-left: 4px solid #28a745;
}

.achievement-icon {
  font-size: 2rem;
  filter: grayscale(100%);
}

.achievement.unlocked .achievement-icon {
  filter: none;
}

.achievement-content h4 {
  margin: 0 0 5px 0;
  color: #333;
}

.achievement-content p {
  margin: 0;
  color: #666;
  font-size: 0.9rem;
}

/* Loading, Error, and Empty States */
.loading,
.error,
.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: #666;
}

.error {
  color: #dc3545;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #f3f3f3;
  border-top: 4px solid #667eea;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 20px;
}

@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}

.error-icon,
.empty-icon {
  font-size: 4rem;
  margin-bottom: 20px;
}

.retry-btn {
  background: #667eea;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 8px;
  cursor: pointer;
  margin-top: 15px;
}

.retry-btn:hover {
  background: #5a6fd8;
}

/* Responsive */
@media (max-width: 768px) {
  .profile-info {
    flex-direction: column;
    text-align: center;
  }

  .stats-grid {
    grid-template-columns: 1fr;
  }

  .achievements-grid {
    grid-template-columns: 1fr;
  }
}
</style>
