<template>
  <div class="profile-container">
    <div class="profile-header">
      <div class="profile-info">
        <div class="avatar">
          {{ userStats?.user?.username?.charAt(0).toUpperCase() || "U" }}
        </div>
        <div class="user-details">
          <h1>{{ userStats?.user?.username || "Loading..." }}</h1>
          <p class="email">{{ userStats?.user?.email }}</p>
          <p class="member-since">
            Member since {{ formatDate(userStats?.user?.createdAt) }}
          </p>
        </div>
      </div>
    </div>

    <div class="stats-grid" v-if="userStats">
      <!-- Total Study Time -->
      <div class="stat-card primary">
        <div class="stat-icon">⏱️</div>
        <div class="stat-content">
          <h3>{{ formatHours(userStats.stats.totalStudyMinutes) }}</h3>
          <p>Total Study Time</p>
        </div>
      </div>

      <!-- Completed Sessions -->
      <div class="stat-card success">
        <div class="stat-icon">✅</div>
        <div class="stat-content">
          <h3>{{ userStats.stats.completedSessions }}</h3>
          <p>Completed Sessions</p>
        </div>
      </div>

      <!-- Current Streak -->
      <div class="stat-card warning">
        <div class="stat-icon">🔥</div>
        <div class="stat-content">
          <h3>{{ userStats.stats.currentStreak }}</h3>
          <p>Day Streak</p>
        </div>
      </div>

      <!-- Longest Session -->
      <div class="stat-card info">
        <div class="stat-icon">🏆</div>
        <div class="stat-content">
          <h3>{{ formatMinutes(userStats.stats.longestSession) }}</h3>
          <p>Longest Session</p>
        </div>
      </div>

      <!-- Weekly Stats -->
      <div class="stat-card secondary">
        <div class="stat-icon">📅</div>
        <div class="stat-content">
          <h3>{{ formatHours(userStats.stats.weeklyStudyMinutes) }}</h3>
          <p>This Week</p>
        </div>
      </div>

      <!-- Quit Sessions (if any) -->
      <div class="stat-card danger" v-if="userStats.stats.quitSessions > 0">
        <div class="stat-icon">⚠️</div>
        <div class="stat-content">
          <h3>{{ userStats.stats.quitSessions }}</h3>
          <p>Early Quits</p>
        </div>
      </div>
    </div>

    <!-- Study Progress -->
    <div class="progress-section" v-if="userStats">
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
          {{ userStats.stats.completedSessions }} completed out of
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
          {{ formatHours(userStats.stats.weeklyStudyMinutes) }} of 10 hours
          weekly goal
        </p>
      </div>
    </div>

    <!-- Achievements -->
    <div class="achievements-section" v-if="userStats">
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

    <div class="loading" v-if="loading">Loading your stats...</div>

    <div class="error" v-if="error">
      {{ error }}
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
  if (!userStats.value) return 0;
  const total = totalSessions.value;
  if (total === 0) return 100;
  return Math.round((userStats.value.stats.completedSessions / total) * 100);
});

const totalSessions = computed(() => {
  if (!userStats.value) return 0;
  return (
    userStats.value.stats.completedSessions +
    userStats.value.stats.quitSessions +
    userStats.value.stats.disconnectedSessions
  );
});

const weeklyProgress = computed(() => {
  if (!userStats.value) return 0;
  const weeklyMinutes = userStats.value.stats.weeklyStudyMinutes;
  const weeklyGoal = 600; // 10 hours = 600 minutes
  return Math.round((weeklyMinutes / weeklyGoal) * 100);
});

const achievements = computed(() => {
  if (!userStats.value) return [];

  const stats = userStats.value.stats;

  return [
    {
      id: "first_session",
      title: "First Steps",
      description: "Complete your first study session",
      icon: "🌟",
      unlocked: stats.completedSessions >= 1,
    },
    {
      id: "study_warrior",
      title: "Study Warrior",
      description: "Complete 10 study sessions",
      icon: "⚔️",
      unlocked: stats.completedSessions >= 10,
    },
    {
      id: "time_master",
      title: "Time Master",
      description: "Study for 10+ hours total",
      icon: "⏰",
      unlocked: stats.totalStudyMinutes >= 600,
    },
    {
      id: "streak_master",
      title: "Streak Master",
      description: "Maintain a 7-day study streak",
      icon: "🔥",
      unlocked: stats.currentStreak >= 7,
    },
    {
      id: "marathon_runner",
      title: "Marathon Runner",
      description: "Complete a 90+ minute session",
      icon: "🏃‍♂️",
      unlocked: stats.longestSession >= 90,
    },
    {
      id: "consistency_king",
      title: "Consistency King",
      description: "Study 20+ hours total",
      icon: "👑",
      unlocked: stats.totalStudyMinutes >= 1200,
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

  try {
    const response = await axios.get(
      `http://localhost:3000/api/users/${userId}/stats`
    );
    userStats.value = response.data;
  } catch (err) {
    console.error("Error fetching user stats:", err);
    error.value = "Failed to load your stats. Please try again.";
  } finally {
    loading.value = false;
  }
};

const formatHours = (minutes) => {
  if (minutes < 60) return `${minutes}m`;
  const hours = Math.floor(minutes / 60);
  const remainingMinutes = minutes % 60;
  return remainingMinutes > 0 ? `${hours}h ${remainingMinutes}m` : `${hours}h`;
};

const formatMinutes = (minutes) => {
  return `${minutes} min`;
};

const formatDate = (dateString) => {
  if (!dateString) return "";
  return new Date(dateString).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });
};

// Lifecycle
onMounted(() => {
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

/* Loading and Error */
.loading,
.error {
  text-align: center;
  padding: 40px;
  color: #666;
}

.error {
  color: #dc3545;
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
