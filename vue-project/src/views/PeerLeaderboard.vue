<template>
  <div class="leaderboard-container">
    <!-- Header -->
    <div class="leaderboard-header">
      <div class="header-content">
        <div class="header-icon">
          <Trophy :size="36" />
        </div>
        <div class="header-text">
          <h1>Weekly Leaderboard</h1>
          <p class="subtitle">Top performers this week based on study time</p>
        </div>
      </div>
      <div class="reset-badge">
        <RotateCcw :size="16" />
        Resets every Sunday
      </div>
    </div>

    <!-- Loading State -->
    <div class="loading-state" v-if="loading">
      <Loader2 :size="50" class="spinning" />
      <p>Loading leaderboard...</p>
    </div>

    <!-- Error State -->
    <div class="error-state" v-if="error && !loading">
      <div class="error-icon">
        <AlertTriangle :size="32" />
      </div>
      <h3>Failed to load leaderboard</h3>
      <p>{{ error }}</p>
      <button @click="fetchLeaderboard" class="retry-btn">
        <RefreshCw :size="18" />
        Try Again
      </button>
    </div>

    <!-- Content -->
    <div v-if="!loading && !error" class="leaderboard-content">
      <!-- Top 3 Podium -->
      <div class="podium-section" v-if="topThree.length > 0">
        <h2 class="section-title">
          <Award :size="24" />
          Top Performers
        </h2>
        <div class="podium">
          <!-- Second Place -->
          <div class="podium-place second" v-if="topThree[1]">
            <div class="medal-badge silver">
              <Medal :size="24" />
            </div>
            <div class="podium-card">
              <div class="rank-number">2</div>
              <div class="user-avatar silver">
                {{ topThree[1].username.charAt(0).toUpperCase() }}
              </div>
              <h3>{{ topThree[1].username }}</h3>
              <div class="study-time">
                {{ formatHours(topThree[1].weeklyStudyMinutes) }}
              </div>
              <div class="sessions-count">
                <CheckCircle :size="16" />
                {{ topThree[1].weeklyCompletedSessions }} sessions
              </div>
            </div>
            <div class="podium-base silver-base"></div>
          </div>

          <!-- First Place -->
          <div class="podium-place first" v-if="topThree[0]">
            <div class="medal-badge gold">
              <Crown :size="28" />
            </div>
            <div class="podium-card winner">
              <div class="rank-number winner">1</div>
              <div class="user-avatar gold">
                {{ topThree[0].username.charAt(0).toUpperCase() }}
              </div>
              <h3>{{ topThree[0].username }}</h3>
              <div class="study-time">
                {{ formatHours(topThree[0].weeklyStudyMinutes) }}
              </div>
              <div class="sessions-count">
                <CheckCircle :size="16" />
                {{ topThree[0].weeklyCompletedSessions }} sessions
              </div>
            </div>
            <div class="podium-base gold-base"></div>
          </div>

          <!-- Third Place -->
          <div class="podium-place third" v-if="topThree[2]">
            <div class="medal-badge bronze">
              <Award :size="22" />
            </div>
            <div class="podium-card">
              <div class="rank-number">3</div>
              <div class="user-avatar bronze">
                {{ topThree[2].username.charAt(0).toUpperCase() }}
              </div>
              <h3>{{ topThree[2].username }}</h3>
              <div class="study-time">
                {{ formatHours(topThree[2].weeklyStudyMinutes) }}
              </div>
              <div class="sessions-count">
                <CheckCircle :size="16" />
                {{ topThree[2].weeklyCompletedSessions }} sessions
              </div>
            </div>
            <div class="podium-base bronze-base"></div>
          </div>
        </div>
      </div>

      <!-- Full Rankings -->
      <div class="rankings-section">
        <div class="section-header">
          <h2 class="section-title">
            <List :size="24" />
            Complete Rankings
          </h2>
          <div class="participants-count" v-if="leaderboard.length > 0">
            <Users :size="18" />
            {{ leaderboard.length }} active studiers
          </div>
        </div>

        <!-- Leaderboard Table -->
        <div class="rankings-table" v-if="leaderboard.length > 0">
          <div class="table-header">
            <div class="col-rank">Rank</div>
            <div class="col-user">Student</div>
            <div class="col-time">Weekly Time</div>
            <div class="col-sessions">Sessions</div>
            <div class="col-total">Total Time</div>
          </div>

          <div
            v-for="user in leaderboard"
            :key="user.username"
            :class="[
              'table-row',
              { 'current-user': isCurrentUser(user.username) },
            ]"
          >
            <div class="col-rank">
              <div class="rank-badge" :class="getRankClass(user.rank)">
                <Crown v-if="user.rank === 1" :size="18" />
                <Medal
                  v-else-if="user.rank === 2 || user.rank === 3"
                  :size="16"
                />
                <span v-else>{{ user.rank }}</span>
              </div>
            </div>

            <div class="col-user">
              <div class="user-info">
                <div class="user-avatar">
                  <User :size="20" />
                </div>
                <div class="user-details">
                  <span class="username">{{ user.username }}</span>
                  <span class="you-badge" v-if="isCurrentUser(user.username)">
                    <Star :size="12" :fill="'currentColor'" />
                    You
                  </span>
                </div>
              </div>
            </div>

            <div class="col-time">
              <div class="time-display">
                <Clock :size="16" />
                {{ formatHours(user.weeklyStudyMinutes) }}
              </div>
            </div>

            <div class="col-sessions">
              <div class="sessions-display">
                <CheckCircle2 :size="16" />
                {{ user.weeklyCompletedSessions }}
              </div>
            </div>

            <div class="col-total">
              <div class="total-display">
                {{ formatHours(user.totalStudyMinutes) }}
              </div>
            </div>
          </div>
        </div>

        <!-- Empty State -->
        <div class="empty-state" v-if="leaderboard.length === 0">
          <div class="empty-icon">
            <UserX :size="32" />
          </div>
          <h3>No studiers yet this week</h3>
          <p>
            Be the first to start a study session and climb the leaderboard!
          </p>
        </div>
      </div>

      <!-- Weekly Stats -->
      <div class="stats-section" v-if="leaderboard.length > 0">
        <h2 class="section-title">
          <TrendingUp :size="24" />
          This Week's Statistics
        </h2>
        <div class="stats-grid">
          <div class="stat-card">
            <div class="stat-icon primary">
              <Users :size="28" />
            </div>
            <div class="stat-content">
              <h3>{{ leaderboard.length }}</h3>
              <p>Active Studiers</p>
            </div>
          </div>

          <div class="stat-card">
            <div class="stat-icon secondary">
              <Clock :size="28" />
            </div>
            <div class="stat-content">
              <h3>{{ formatHours(totalWeeklyMinutes) }}</h3>
              <p>Total Study Time</p>
            </div>
          </div>

          <div class="stat-card">
            <div class="stat-icon success">
              <BookOpen :size="28" />
            </div>
            <div class="stat-content">
              <h3>{{ totalWeeklySessions }}</h3>
              <p>Total Sessions</p>
            </div>
          </div>

          <div class="stat-card">
            <div class="stat-icon info">
              <BarChart3 :size="28" />
            </div>
            <div class="stat-content">
              <h3>{{ averageSessionTime }}m</h3>
              <p>Avg Session Length</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from "vue";
import axios from "axios";
import { API_BASE_URL } from "@/config";
import {
  Trophy,
  Crown,
  Medal,
  Award,
  RotateCcw,
  Loader2,
  AlertTriangle,
  RefreshCw,
  CheckCircle,
  CheckCircle2,
  List,
  Users,
  User,
  Star,
  Clock,
  UserX,
  TrendingUp,
  BookOpen,
  BarChart3,
} from "lucide-vue-next";

// Reactive data
const leaderboard = ref([]);
const loading = ref(true);
const error = ref("");

// Get current user info
const currentUsername = localStorage.getItem("username");

// Computed properties
const topThree = computed(() => {
  return leaderboard.value.slice(0, 3);
});

const totalWeeklyMinutes = computed(() => {
  return leaderboard.value.reduce(
    (total, user) => total + (user.weeklyStudyMinutes || 0),
    0
  );
});

const totalWeeklySessions = computed(() => {
  return leaderboard.value.reduce(
    (total, user) => total + (user.weeklyCompletedSessions || 0),
    0
  );
});

const averageSessionTime = computed(() => {
  if (totalWeeklySessions.value === 0) return 0;
  return Math.round(totalWeeklyMinutes.value / totalWeeklySessions.value);
});

// Methods
const fetchLeaderboard = async () => {
  loading.value = true;
  error.value = "";

  try {
    console.log("Fetching leaderboard...");
    const response = await axios.get(`${API_BASE_URL}/api/leaderboard`);
    console.log("Received leaderboard response:", response.data);

    if (response.data && response.data.leaderboard) {
      leaderboard.value = response.data.leaderboard;
    } else {
      leaderboard.value = [];
    }
  } catch (err) {
    console.error("Error fetching leaderboard:", err);
    if (err.response?.status === 500) {
      error.value = "Server error. Please try again later.";
    } else if (err.response?.data?.message) {
      error.value = err.response.data.message;
    } else if (err.code === "ECONNREFUSED" || err.code === "ERR_NETWORK") {
      error.value =
        "Cannot connect to server. Make sure the backend is running.";
    } else {
      error.value = "Failed to load leaderboard. Please try again.";
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

const getRankClass = (rank) => {
  if (rank === 1) return "gold";
  if (rank === 2) return "silver";
  if (rank === 3) return "bronze";
  if (rank <= 10) return "top-ten";
  return "regular";
};

const isCurrentUser = (username) => {
  return username === currentUsername;
};

// Lifecycle
onMounted(() => {
  console.log("Leaderboard component mounted");
  console.log("Current username:", currentUsername);
  fetchLeaderboard();
});
</script>

<style scoped>
.leaderboard-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 1.5rem;
  min-height: calc(100vh - 80px);
}

/* Header */
.leaderboard-header {
  background: linear-gradient(
    135deg,
    var(--primary-color),
    var(--primary-variant)
  );
  border-radius: var(--border-radius-large);
  padding: 2rem;
  margin-bottom: 2rem;
  box-shadow: var(--box-shadow-light);
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 1.5rem;
}

.header-content {
  display: flex;
  align-items: center;
  gap: 1.5rem;
}

.header-icon {
  width: 70px;
  height: 70px;
  background: var(--secondary-color);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  box-shadow: var(--box-shadow);
}

.header-text h1 {
  margin: 0 0 0.5rem 0;
  font-size: 2.5rem;
  font-weight: 700;
  color: var(--on-primary);
}

.subtitle {
  margin: 0;
  color: var(--on-primary);
  opacity: 0.9;
  font-size: 1.1rem;
}

.reset-badge {
  background: var(--secondary-color);
  color: white;
  padding: 0.75rem 1.5rem;
  border-radius: var(--border-radius-large);
  font-weight: 600;
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  box-shadow: var(--box-shadow-light);
}

/* Loading & Error States */
.loading-state,
.error-state {
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

.error-state {
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
  margin-bottom: 1.5rem;
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

/* Content */
.leaderboard-content {
  display: flex;
  flex-direction: column;
  gap: 2rem;
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

/* Podium Section */
.podium-section {
  background: var(--background-secondary);
  border-radius: var(--border-radius-large);
  padding: 2rem;
  box-shadow: var(--box-shadow-light);
}

.podium {
  display: flex;
  justify-content: center;
  align-items: flex-end;
  gap: 1.5rem;
  max-width: 900px;
  margin: 0 auto;
  flex-wrap: wrap;
}

.podium-place {
  display: flex;
  flex-direction: column;
  align-items: center;
  position: relative;
}

.medal-badge {
  position: absolute;
  top: -15px;
  left: 50%;
  transform: translateX(-50%);
  width: 50px;
  height: 50px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 10;
  box-shadow: var(--box-shadow);
  color: white;
}

.medal-badge.gold {
  background: linear-gradient(135deg, #ffd700, #ffed4e);
  color: #333;
}

.medal-badge.silver {
  background: linear-gradient(135deg, #c0c0c0, #e8e8e8);
  color: #666;
}

.medal-badge.bronze {
  background: linear-gradient(135deg, #cd7f32, #daa520);
}

.podium-card {
  background: white;
  border-radius: var(--border-radius-large);
  padding: 2rem 1.5rem;
  text-align: center;
  box-shadow: var(--box-shadow);
  margin-bottom: 0.5rem;
  min-width: 200px;
  transition: var(--transition-fast);
}

.podium-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 30px rgba(0, 0, 0, 0.15);
}

.podium-card.winner {
  border: 3px solid #ffd700;
}

.rank-number {
  position: absolute;
  top: 10px;
  right: 10px;
  width: 30px;
  height: 30px;
  background: var(--color-border);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 0.9rem;
  color: var(--color-text);
}

.rank-number.winner {
  background: linear-gradient(135deg, #ffd700, #ffed4e);
  color: #333;
}

.user-avatar {
  width: 70px;
  height: 70px;
  border-radius: 50%;
  background: linear-gradient(
    135deg,
    var(--primary-color),
    var(--primary-variant)
  );
  color: var(--on-primary);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.8rem;
  font-weight: 700;
  margin: 1.5rem auto 1rem;
  box-shadow: var(--box-shadow-light);
}

.user-avatar.gold {
  background: linear-gradient(135deg, #ffd700, #ffed4e);
  color: #333;
  transform: scale(1.1);
}

.user-avatar.silver {
  background: linear-gradient(135deg, #c0c0c0, #e8e8e8);
  color: #666;
}

.user-avatar.bronze {
  background: linear-gradient(135deg, #cd7f32, #daa520);
  color: white;
}

.podium-card h3 {
  margin: 0 0 0.75rem 0;
  color: var(--color-heading);
  font-size: 1.2rem;
  font-weight: 600;
}

.study-time {
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--secondary-color);
  margin-bottom: 0.5rem;
}

.sessions-count {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  color: var(--color-text-secondary);
  font-size: 0.9rem;
}

.sessions-count svg {
  color: var(--color-success);
}

.podium-base {
  width: 100%;
  height: 60px;
  border-radius: var(--border-radius) var(--border-radius) 0 0;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  color: white;
  font-size: 1.2rem;
}

.gold-base {
  background: linear-gradient(135deg, #ffd700, #ffed4e);
  height: 80px;
  color: #333;
}

.silver-base {
  background: linear-gradient(135deg, #c0c0c0, #e8e8e8);
  height: 65px;
  color: #666;
}

.bronze-base {
  background: linear-gradient(135deg, #cd7f32, #daa520);
  height: 50px;
}

.podium-place.first {
  order: 2;
}

.podium-place.second {
  order: 1;
}

.podium-place.third {
  order: 3;
}

/* Rankings Section */
.rankings-section {
  background: white;
  border-radius: var(--border-radius-large);
  padding: 2rem;
  box-shadow: var(--box-shadow-light);
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
  flex-wrap: wrap;
  gap: 1rem;
}

.participants-count {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: var(--color-text-secondary);
  font-weight: 600;
}

.participants-count svg {
  color: var(--primary-variant);
}

/* Table */
.rankings-table {
  overflow-x: auto;
}

.table-header {
  display: grid;
  grid-template-columns: 80px 1fr 140px 110px 130px;
  gap: 1rem;
  padding: 1rem 1.5rem;
  background: var(--background-secondary);
  border-radius: var(--border-radius);
  font-weight: 600;
  color: var(--color-text);
  margin-bottom: 0.5rem;
}

.table-row {
  display: grid;
  grid-template-columns: 80px 1fr 140px 110px 130px;
  gap: 1rem;
  padding: 1.25rem 1.5rem;
  border-bottom: 1px solid var(--color-border);
  transition: var(--transition-fast);
  align-items: center;
}

.table-row:hover {
  background: var(--background-secondary);
  border-radius: var(--border-radius);
}

.table-row.current-user {
  background: linear-gradient(
    135deg,
    rgba(52, 220, 59, 0.1),
    rgba(164, 170, 81, 0.1)
  );
  border-left: 4px solid var(--secondary-color);
  border-radius: var(--border-radius);
}

.col-rank {
  display: flex;
  align-items: center;
  justify-content: center;
}

.rank-badge {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  color: white;
  font-size: 1rem;
  box-shadow: var(--box-shadow-light);
}

.rank-badge.gold {
  background: linear-gradient(135deg, #ffd700, #ffed4e);
  color: #333;
}

.rank-badge.silver {
  background: linear-gradient(135deg, #c0c0c0, #e8e8e8);
  color: #666;
}

.rank-badge.bronze {
  background: linear-gradient(135deg, #cd7f32, #daa520);
}

.rank-badge.top-ten {
  background: linear-gradient(
    135deg,
    var(--primary-color),
    var(--primary-variant)
  );
}

.rank-badge.regular {
  background: var(--color-border);
  color: var(--color-text);
}

.col-user {
  display: flex;
  align-items: center;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.user-info .user-avatar {
  width: 45px;
  height: 45px;
  background: linear-gradient(
    135deg,
    var(--primary-color),
    var(--primary-variant)
  );
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--on-primary);
  margin: 0;
}

.user-details {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.username {
  font-weight: 600;
  color: var(--color-heading);
}

.you-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  background: var(--secondary-color);
  color: white;
  padding: 0.15rem 0.5rem;
  border-radius: var(--border-radius);
  font-size: 0.75rem;
  font-weight: 600;
}

.col-time,
.col-sessions,
.col-total {
  display: flex;
  align-items: center;
}

.time-display,
.sessions-display,
.total-display {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 600;
}

.time-display {
  color: var(--secondary-color);
}

.time-display svg {
  color: var(--primary-variant);
}

.sessions-display {
  color: var(--color-success);
}

.total-display {
  color: var(--color-text-secondary);
}

/* Empty State */
.empty-state {
  text-align: center;
  padding: 4rem 2rem;
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

/* Stats Section */
.stats-section {
  background: var(--background-secondary);
  border-radius: var(--border-radius-large);
  padding: 2rem;
  box-shadow: var(--box-shadow-light);
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 1.5rem;
}

.stat-card {
  background: white;
  border-radius: var(--border-radius-large);
  padding: 1.5rem;
  display: flex;
  align-items: center;
  gap: 1rem;
  box-shadow: var(--box-shadow-light);
  transition: var(--transition-fast);
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: var(--box-shadow);
}

.stat-icon {
  width: 60px;
  height: 60px;
  border-radius: var(--border-radius);
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  flex-shrink: 0;
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

.stat-icon.info {
  background: linear-gradient(135deg, var(--color-info), #117a8b);
}

.stat-content h3 {
  margin: 0 0 0.25rem 0;
  font-size: 1.8rem;
  font-weight: 700;
  color: var(--color-heading);
}

.stat-content p {
  margin: 0;
  color: var(--color-text-secondary);
  font-size: 0.9rem;
}

/* Dark Mode Support */
@media (prefers-color-scheme: dark) {
  .podium-card,
  .rankings-section,
  .stat-card {
    background: var(--background);
  }

  .podium-section,
  .stats-section {
    background: var(--background-secondary);
  }
}

/* Responsive Design */
@media (max-width: 1024px) {
  .table-header,
  .table-row {
    grid-template-columns: 70px 1fr 120px 90px 110px;
    gap: 0.75rem;
    padding: 1rem;
  }
}

@media (max-width: 768px) {
  .leaderboard-container {
    padding: 1rem;
  }

  .leaderboard-header {
    flex-direction: column;
    text-align: center;
    padding: 1.5rem;
  }

  .header-content {
    flex-direction: column;
  }

  .header-text h1 {
    font-size: 2rem;
  }

  .podium {
    flex-direction: column;
    align-items: center;
  }

  .podium-place {
    order: initial !important;
    margin-bottom: 1.5rem;
  }

  .podium-base {
    display: none;
  }

  .table-header {
    display: none;
  }

  .table-row {
    grid-template-columns: 1fr;
    gap: 1rem;
    padding: 1.5rem;
    border: 1px solid var(--color-border);
    border-radius: var(--border-radius);
    margin-bottom: 1rem;
  }

  .col-rank,
  .col-user,
  .col-time,
  .col-sessions,
  .col-total {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .col-rank::before {
    content: "Rank:";
    font-weight: 600;
    color: var(--color-text);
  }

  .col-time::before {
    content: "Weekly Time:";
    font-weight: 600;
    color: var(--color-text);
  }

  .col-sessions::before {
    content: "Sessions:";
    font-weight: 600;
    color: var(--color-text);
  }

  .col-total::before {
    content: "Total Time:";
    font-weight: 600;
    color: var(--color-text);
  }

  .stats-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 480px) {
  .header-icon {
    width: 60px;
    height: 60px;
  }

  .header-text h1 {
    font-size: 1.75rem;
  }

  .subtitle {
    font-size: 1rem;
  }

  .podium-card {
    min-width: 180px;
    padding: 1.5rem 1rem;
  }

  .user-avatar {
    width: 60px;
    height: 60px;
    font-size: 1.5rem;
  }
}
</style>
