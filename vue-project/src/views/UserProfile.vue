<template>
  <div class="profile-container">
    <!-- Loading State -->
    <div class="loading" v-if="loading">
      <Loader2 :size="50" class="spinning" />
      <p>Loading your profile...</p>
    </div>

    <!-- Error State -->
    <div class="error-state" v-if="error && !loading">
      <div class="error-icon">
        <AlertTriangle :size="32" />
      </div>
      <h3>Failed to load profile</h3>
      <p>{{ error }}</p>
      <button @click="fetchUserStats" class="retry-btn">
        <RefreshCw :size="18" />
        Try Again
      </button>
    </div>

    <!-- Profile Content -->
    <div v-if="!loading && !error && userStats" class="profile-content">
      <!-- Profile Header -->
      <div class="profile-header">
        <div class="profile-banner">
          <div class="banner-decoration"></div>
        </div>
        <div class="profile-info">
          <div class="avatar-container">
            <div class="avatar">
              <User :size="48" />
            </div>
            <div class="avatar-badge">
              <Zap :size="14" :fill="'currentColor'" />
            </div>
          </div>
          <div class="user-details">
            <h1 class="username">
              {{ userStats.user?.username || "Unknown User" }}
            </h1>
            <p class="email">
              <Mail :size="16" />
              {{ userStats.user?.email || "" }}
            </p>
            <p class="member-since">
              <Calendar :size="16" />
              Member since {{ formatDate(userStats.user?.createdAt) }}
            </p>
          </div>
        </div>
      </div>

      <!-- Quick Stats Overview -->
      <div class="stats-overview">
        <div class="overview-card">
          <div class="overview-icon">
            <Clock :size="28" />
          </div>
          <div class="overview-content">
            <h3>{{ formatHours(userStats.stats?.totalStudyMinutes || 0) }}</h3>
            <p>Total Study Time</p>
          </div>
        </div>
        <div class="overview-card">
          <div class="overview-icon success">
            <CheckCircle2 :size="28" />
          </div>
          <div class="overview-content">
            <h3>{{ userStats.stats?.completedSessions || 0 }}</h3>
            <p>Completed Sessions</p>
          </div>
        </div>
        <div class="overview-card">
          <div class="overview-icon fire">
            <Flame :size="28" />
          </div>
          <div class="overview-content">
            <h3>{{ userStats.stats?.currentStreak || 0 }}</h3>
            <p>Day Streak</p>
          </div>
        </div>
      </div>

      <!-- Detailed Stats Grid -->
      <div class="section">
        <h2 class="section-title">
          <BarChart3 :size="24" />
          Detailed Statistics
        </h2>
        <div class="stats-grid">
          <div class="stat-card">
            <div class="stat-header">
              <div class="stat-icon primary">
                <Timer :size="24" />
              </div>
              <span class="stat-badge">Record</span>
            </div>
            <div class="stat-content">
              <h3>{{ formatMinutes(userStats.stats?.longestSession || 0) }}</h3>
              <p>Longest Session</p>
            </div>
          </div>

          <div class="stat-card">
            <div class="stat-header">
              <div class="stat-icon secondary">
                <CalendarDays :size="24" />
              </div>
              <span class="stat-badge">This Week</span>
            </div>
            <div class="stat-content">
              <h3>
                {{ formatHours(userStats.stats?.weeklyStudyMinutes || 0) }}
              </h3>
              <p>Weekly Study Time</p>
            </div>
          </div>

          <div class="stat-card">
            <div class="stat-header">
              <div class="stat-icon success">
                <Percent :size="24" />
              </div>
              <span class="stat-badge">Rate</span>
            </div>
            <div class="stat-content">
              <h3>{{ completionRate }}%</h3>
              <p>Completion Rate</p>
            </div>
          </div>

          <div
            class="stat-card"
            v-if="(userStats.stats?.quitSessions || 0) > 0"
          >
            <div class="stat-header">
              <div class="stat-icon warning">
                <AlertCircle :size="24" />
              </div>
              <span class="stat-badge">Needs Work</span>
            </div>
            <div class="stat-content">
              <h3>{{ userStats.stats?.quitSessions || 0 }}</h3>
              <p>Early Quits</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Progress Section -->
      <div class="section">
        <h2 class="section-title">
          <TrendingUp :size="24" />
          Study Progress
        </h2>

        <div class="progress-cards">
          <div class="progress-card">
            <div class="progress-header">
              <div class="progress-info">
                <h3>Completion Rate</h3>
                <p>
                  {{ userStats.stats?.completedSessions || 0 }} completed out of
                  {{ totalSessions }} sessions
                </p>
              </div>
              <div
                class="progress-percentage"
                :class="getProgressClass(completionRate)"
              >
                {{ completionRate }}%
              </div>
            </div>
            <div class="progress-bar">
              <div
                class="progress-fill"
                :style="{ width: completionRate + '%' }"
              ></div>
            </div>
          </div>

          <div class="progress-card">
            <div class="progress-header">
              <div class="progress-info">
                <h3>Weekly Goal Progress</h3>
                <p>
                  {{ formatHours(userStats.stats?.weeklyStudyMinutes || 0) }} of
                  10 hours goal
                </p>
              </div>
              <div
                class="progress-percentage weekly"
                :class="getProgressClass(weeklyProgress)"
              >
                {{ weeklyProgress }}%
              </div>
            </div>
            <div class="progress-bar">
              <div
                class="progress-fill weekly"
                :style="{ width: Math.min(weeklyProgress, 100) + '%' }"
              ></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Achievements Section -->
      <div class="section">
        <h2 class="section-title">
          <Award :size="24" />
          Achievements
        </h2>
        <div class="achievements-grid">
          <div
            v-for="achievement in achievements"
            :key="achievement.id"
            :class="['achievement-card', { unlocked: achievement.unlocked }]"
          >
            <div class="achievement-icon">{{ achievement.icon }}</div>
            <div class="achievement-content">
              <h4>{{ achievement.title }}</h4>
              <p>{{ achievement.description }}</p>
              <div v-if="achievement.unlocked" class="unlocked-badge">
                <Check :size="14" />
                Unlocked
              </div>
              <div v-else class="locked-badge">
                <Lock :size="14" />
                Locked
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Empty State -->
    <div v-if="!loading && !error && !userStats" class="empty-state">
      <div class="empty-icon">
        <UserX :size="32" />
      </div>
      <h3>Profile not found</h3>
      <p>Unable to load your profile data.</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from "vue";
import axios from "axios";
import { API_BASE_URL } from "@/config";
import {
  Loader2,
  AlertTriangle,
  RefreshCw,
  User,
  Zap,
  Mail,
  Calendar,
  Clock,
  CheckCircle2,
  Flame,
  BarChart3,
  Timer,
  CalendarDays,
  Percent,
  AlertCircle,
  TrendingUp,
  Award,
  Check,
  Lock,
  UserX,
} from "lucide-vue-next";

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
      icon: "🏃",
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
      `${API_BASE_URL}/api/users/${userId}/stats`
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

const getProgressClass = (percentage) => {
  if (percentage >= 80) return "excellent";
  if (percentage >= 60) return "good";
  if (percentage >= 40) return "average";
  return "needs-work";
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
  padding: 1.5rem;
  min-height: calc(100vh - 80px);
}

/* Loading State */
.loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 4rem 2rem;
  color: var(--color-text);
}

.spinning {
  animation: spin 1s linear infinite;
  margin-bottom: 1rem;
  color: var(--secondary-color);
}

@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}

/* Error State */
.error-state {
  text-align: center;
  padding: 4rem 2rem;
  background: var(--background-secondary);
  border-radius: var(--border-radius-large);
  box-shadow: var(--box-shadow-light);
}

.error-icon {
  width: 80px;
  height: 80px;
  background: rgba(220, 53, 69, 0.1);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 1.5rem;
  color: var(--color-error);
}

.error-state h3 {
  color: var(--color-heading);
  margin-bottom: 1rem;
}

.error-state p {
  color: var(--color-text-secondary);
  margin-bottom: 1.5rem;
}

.retry-btn {
  background: var(--secondary-color);
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: var(--border-radius);
  cursor: pointer;
  font-weight: 600;
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  transition: var(--transition-fast);
}

.retry-btn:hover {
  background: var(--secondary-hover);
  transform: translateY(-1px);
}

/* Profile Header */
.profile-header {
  background: white;
  border-radius: var(--border-radius-large);
  overflow: hidden;
  margin-bottom: 2rem;
  box-shadow: var(--box-shadow-light);
}

.profile-banner {
  height: 120px;
  background: linear-gradient(
    135deg,
    var(--primary-color),
    var(--primary-variant)
  );
  position: relative;
}

.banner-decoration {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 40px;
  background: white;
  border-radius: 50% 50% 0 0 / 100% 100% 0 0;
}

.profile-info {
  display: flex;
  align-items: center;
  gap: 2rem;
  padding: 0 2rem 2rem 2rem;
  margin-top: -40px;
  position: relative;
}

.avatar-container {
  position: relative;
}

.avatar {
  width: 100px;
  height: 100px;
  background: linear-gradient(
    135deg,
    var(--secondary-color),
    var(--secondary-variant)
  );
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
  border: 4px solid white;
}

.avatar-badge {
  position: absolute;
  bottom: 5px;
  right: 5px;
  width: 28px;
  height: 28px;
  background: var(--color-success);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  border: 3px solid white;
}

.user-details {
  flex: 1;
}

.username {
  margin: 0 0 0.5rem 0;
  font-size: 2rem;
  font-weight: 700;
  color: var(--color-heading);
}

.email,
.member-since {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin: 0.5rem 0;
  color: var(--color-text-secondary);
  font-size: 0.95rem;
}

.email svg,
.member-since svg {
  color: var(--primary-variant);
}

/* Stats Overview */
.stats-overview {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.overview-card {
  background: var(--background-secondary);
  border-radius: var(--border-radius-large);
  padding: 1.5rem;
  display: flex;
  align-items: center;
  gap: 1rem;
  border: 2px solid var(--color-border);
  transition: var(--transition-fast);
}

.overview-card:hover {
  transform: translateY(-2px);
  border-color: var(--primary-variant);
  box-shadow: var(--box-shadow-light);
}

.overview-icon {
  width: 60px;
  height: 60px;
  background: linear-gradient(
    135deg,
    var(--primary-color),
    var(--primary-variant)
  );
  border-radius: var(--border-radius);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--on-primary);
}

.overview-icon.success {
  background: linear-gradient(135deg, var(--color-success), #1e7e34);
}

.overview-icon.fire {
  background: linear-gradient(135deg, #ff6b6b, #ee5a24);
}

.overview-content h3 {
  margin: 0 0 0.25rem 0;
  font-size: 1.8rem;
  font-weight: 700;
  color: var(--color-heading);
}

.overview-content p {
  margin: 0;
  color: var(--color-text-secondary);
  font-size: 0.9rem;
}

/* Section */
.section {
  margin-bottom: 2rem;
}

.section-title {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--color-heading);
  margin-bottom: 1.5rem;
}

.section-title svg {
  color: var(--primary-variant);
}

/* Stats Grid */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 1.5rem;
}

.stat-card {
  background: white;
  border-radius: var(--border-radius-large);
  padding: 1.5rem;
  box-shadow: var(--box-shadow-light);
  transition: var(--transition-fast);
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: var(--box-shadow);
}

.stat-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.stat-icon {
  width: 45px;
  height: 45px;
  border-radius: var(--border-radius);
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
}

.stat-icon.primary {
  background: linear-gradient(
    135deg,
    var(--primary-color),
    var(--primary-variant)
  );
}

.stat-icon.secondary {
  background: linear-gradient(
    135deg,
    var(--secondary-color),
    var(--secondary-variant)
  );
}

.stat-icon.success {
  background: linear-gradient(135deg, var(--color-success), #1e7e34);
}

.stat-icon.warning {
  background: linear-gradient(135deg, var(--color-warning), #e0a800);
}

.stat-badge {
  background: var(--background-secondary);
  color: var(--color-text);
  padding: 0.25rem 0.75rem;
  border-radius: var(--border-radius);
  font-size: 0.75rem;
  font-weight: 600;
}

.stat-content h3 {
  margin: 0 0 0.5rem 0;
  font-size: 2rem;
  font-weight: 700;
  color: var(--color-heading);
}

.stat-content p {
  margin: 0;
  color: var(--color-text-secondary);
  font-size: 0.9rem;
}

/* Progress Cards */
.progress-cards {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.progress-card {
  background: white;
  border-radius: var(--border-radius-large);
  padding: 2rem;
  box-shadow: var(--box-shadow-light);
}

.progress-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 1.5rem;
  gap: 1rem;
}

.progress-info h3 {
  margin: 0 0 0.5rem 0;
  font-size: 1.2rem;
  font-weight: 600;
  color: var(--color-heading);
}

.progress-info p {
  margin: 0;
  color: var(--color-text-secondary);
  font-size: 0.9rem;
}

.progress-percentage {
  font-size: 1.8rem;
  font-weight: 700;
  padding: 0.5rem 1rem;
  border-radius: var(--border-radius);
  white-space: nowrap;
}

.progress-percentage.excellent {
  background: rgba(40, 167, 69, 0.1);
  color: var(--color-success);
}

.progress-percentage.good {
  background: rgba(52, 220, 59, 0.1);
  color: var(--secondary-color);
}

.progress-percentage.average {
  background: rgba(255, 193, 7, 0.1);
  color: var(--color-warning);
}

.progress-percentage.needs-work {
  background: rgba(220, 53, 69, 0.1);
  color: var(--color-error);
}

.progress-bar {
  height: 12px;
  background: var(--color-border);
  border-radius: 6px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(
    90deg,
    var(--primary-color),
    var(--primary-variant)
  );
  border-radius: 6px;
  transition: width 0.8s ease;
}

.progress-fill.weekly {
  background: linear-gradient(
    90deg,
    var(--secondary-color),
    var(--secondary-variant)
  );
}

/* Achievements */
.achievements-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 1.5rem;
}

.achievement-card {
  background: var(--background-secondary);
  border-radius: var(--border-radius-large);
  padding: 1.5rem;
  display: flex;
  gap: 1rem;
  border: 2px solid var(--color-border);
  transition: var(--transition-fast);
  opacity: 0.6;
}

.achievement-card.unlocked {
  opacity: 1;
  background: white;
  border-color: var(--secondary-color);
  box-shadow: var(--box-shadow-light);
}

.achievement-card:hover {
  transform: translateY(-2px);
}

.achievement-icon {
  font-size: 2.5rem;
  filter: grayscale(100%);
  flex-shrink: 0;
}

.achievement-card.unlocked .achievement-icon {
  filter: none;
}

.achievement-content {
  flex: 1;
}

.achievement-content h4 {
  margin: 0 0 0.5rem 0;
  color: var(--color-heading);
  font-size: 1.1rem;
}

.achievement-content p {
  margin: 0 0 0.75rem 0;
  color: var(--color-text-secondary);
  font-size: 0.9rem;
  line-height: 1.4;
}

.unlocked-badge,
.locked-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  padding: 0.25rem 0.75rem;
  border-radius: var(--border-radius);
  font-size: 0.75rem;
  font-weight: 600;
}

.unlocked-badge {
  background: rgba(40, 167, 69, 0.1);
  color: var(--color-success);
}

.locked-badge {
  background: var(--background);
  color: var(--color-text-secondary);
}

/* Empty State */
.empty-state {
  text-align: center;
  padding: 4rem 2rem;
  background: var(--background-secondary);
  border-radius: var(--border-radius-large);
  box-shadow: var(--box-shadow-light);
}

.empty-icon {
  width: 80px;
  height: 80px;
  background: var(--color-border);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 1.5rem;
  color: var(--color-text-secondary);
}

.empty-state h3 {
  color: var(--color-heading);
  margin-bottom: 1rem;
}

.empty-state p {
  color: var(--color-text-secondary);
}

/* Dark Mode Support */
@media (prefers-color-scheme: dark) {
  .profile-header,
  .stat-card,
  .progress-card {
    background: var(--background);
  }

  .achievement-card.unlocked {
    background: var(--background);
  }

  .banner-decoration {
    background: var(--background);
  }

  .avatar {
    border-color: var(--background);
  }

  .avatar-badge {
    border-color: var(--background);
  }
}

/* Responsive Design */
@media (max-width: 768px) {
  .profile-container {
    padding: 1rem;
  }

  .profile-info {
    flex-direction: column;
    text-align: center;
    padding: 0 1.5rem 1.5rem;
  }

  .stats-overview {
    grid-template-columns: 1fr;
  }

  .stats-grid {
    grid-template-columns: 1fr;
  }

  .achievements-grid {
    grid-template-columns: 1fr;
  }

  .progress-header {
    flex-direction: column;
    align-items: flex-start;
  }

  .progress-percentage {
    align-self: flex-end;
  }
}
</style>
