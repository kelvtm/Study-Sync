<template>
  <div class="leaderboard-container">
    <div class="leaderboard-header">
      <h1>📊 Weekly Leaderboard</h1>
      <p class="subtitle">Top performers this week based on study time</p>
      <div class="reset-info">
        <span class="reset-badge">🔄 Resets every Sunday</span>
      </div>
    </div>

    <!-- Loading State -->
    <div class="loading-state" v-if="loading">
      <div class="spinner"></div>
      <p>Loading leaderboard...</p>
    </div>

    <!-- Error State -->
    <div class="error-state" v-if="error && !loading">
      <div class="error-icon">⚠️</div>
      <h3>Failed to load leaderboard</h3>
      <p>{{ error }}</p>
      <button @click="fetchLeaderboard" class="retry-btn">Try Again</button>
    </div>

    <!-- Content when data is loaded successfully -->
    <div v-if="!loading && !error">
      <!-- Top 3 Podium -->
      <div class="podium-section" v-if="topThree.length > 0">
        <div class="podium">
          <!-- Second Place -->
          <div class="podium-place second" v-if="topThree[1]">
            <div class="podium-user">
              <div class="medal silver">🥈</div>
              <div class="avatar">
                {{ topThree[1].username.charAt(0).toUpperCase() }}
              </div>
              <h3>{{ topThree[1].username }}</h3>
              <p>{{ formatHours(topThree[1].weeklyStudyMinutes) }}</p>
              <span class="sessions"
                >{{ topThree[1].weeklyCompletedSessions }} sessions</span
              >
            </div>
            <div class="podium-base second-base">2nd</div>
          </div>

          <!-- First Place -->
          <div class="podium-place first" v-if="topThree[0]">
            <div class="podium-user">
              <div class="medal gold">🥇</div>
              <div class="avatar winner">
                {{ topThree[0].username.charAt(0).toUpperCase() }}
              </div>
              <h3>{{ topThree[0].username }}</h3>
              <p>{{ formatHours(topThree[0].weeklyStudyMinutes) }}</p>
              <span class="sessions"
                >{{ topThree[0].weeklyCompletedSessions }} sessions</span
              >
            </div>
            <div class="podium-base first-base">1st</div>
          </div>

          <!-- Third Place -->
          <div class="podium-place third" v-if="topThree[2]">
            <div class="podium-user">
              <div class="medal bronze">🥉</div>
              <div class="avatar">
                {{ topThree[2].username.charAt(0).toUpperCase() }}
              </div>
              <h3>{{ topThree[2].username }}</h3>
              <p>{{ formatHours(topThree[2].weeklyStudyMinutes) }}</p>
              <span class="sessions"
                >{{ topThree[2].weeklyCompletedSessions }} sessions</span
              >
            </div>
            <div class="podium-base third-base">3rd</div>
          </div>
        </div>
      </div>

      <!-- Full Leaderboard -->
      <div class="leaderboard-section">
        <div class="section-header">
          <h2>🏆 Complete Rankings</h2>
          <div class="stats-summary" v-if="leaderboard.length > 0">
            <span>{{ leaderboard.length }} active studiers this week</span>
          </div>
        </div>

        <!-- Leaderboard Table -->
        <div class="leaderboard-table" v-if="leaderboard.length > 0">
          <div class="table-header">
            <div class="rank-col">Rank</div>
            <div class="user-col">User</div>
            <div class="time-col">Weekly Time</div>
            <div class="sessions-col">Sessions</div>
            <div class="total-col">Total Time</div>
          </div>

          <div
            v-for="user in leaderboard"
            :key="user.username"
            :class="[
              'table-row',
              { 'current-user': isCurrentUser(user.username) },
            ]"
          >
            <div class="rank-col">
              <div class="rank-badge" :class="getRankClass(user.rank)">
                {{ user.rank }}
              </div>
              <div class="badge-container" v-if="user.badge">
                <span class="trophy-badge" :class="user.badge.toLowerCase()">
                  {{ getBadgeIcon(user.badge) }}
                </span>
              </div>
            </div>

            <div class="user-col">
              <div class="user-info">
                <div class="user-avatar">
                  {{ user.username.charAt(0).toUpperCase() }}
                </div>
                <div class="user-details">
                  <span class="username">{{ user.username }}</span>
                  <span
                    class="you-indicator"
                    v-if="isCurrentUser(user.username)"
                    >You</span
                  >
                </div>
              </div>
            </div>

            <div class="time-col">
              <span class="time-value">{{
                formatHours(user.weeklyStudyMinutes)
              }}</span>
            </div>

            <div class="sessions-col">
              <span class="sessions-value">{{
                user.weeklyCompletedSessions
              }}</span>
            </div>

            <div class="total-col">
              <span class="total-value">{{
                formatHours(user.totalStudyMinutes)
              }}</span>
            </div>
          </div>
        </div>

        <!-- Empty State -->
        <div class="empty-state" v-if="leaderboard.length === 0">
          <div class="empty-icon">📚</div>
          <h3>No studiers yet this week</h3>
          <p>
            Be the first to start a study session and climb the leaderboard!
          </p>
        </div>
      </div>

      <!-- Weekly Stats -->
      <div class="stats-section" v-if="leaderboard.length > 0">
        <h2>📈 This Week's Stats</h2>
        <div class="stats-grid">
          <div class="stat-card">
            <div class="stat-icon">👥</div>
            <div class="stat-content">
              <h3>{{ leaderboard.length }}</h3>
              <p>Active Studiers</p>
            </div>
          </div>

          <div class="stat-card">
            <div class="stat-icon">⏱️</div>
            <div class="stat-content">
              <h3>{{ formatHours(totalWeeklyMinutes) }}</h3>
              <p>Total Study Time</p>
            </div>
          </div>

          <div class="stat-card">
            <div class="stat-icon">📚</div>
            <div class="stat-content">
              <h3>{{ totalWeeklySessions }}</h3>
              <p>Total Sessions</p>
            </div>
          </div>

          <div class="stat-card">
            <div class="stat-icon">📊</div>
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
    const response = await axios.get("http://localhost:3000/api/leaderboard");
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
  if (rank <= 3) return `top-${rank}`;
  if (rank <= 10) return "top-ten";
  return "regular";
};

const getBadgeIcon = (badge) => {
  const icons = {
    Gold: "🥇",
    Silver: "🥈",
    Bronze: "🥉",
  };
  return icons[badge] || "";
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
  padding: 20px;
}

.leaderboard-header {
  text-align: center;
  margin-bottom: 40px;
}

.leaderboard-header h1 {
  font-size: 2.5rem;
  color: #333;
  margin-bottom: 10px;
}

.subtitle {
  font-size: 1.2rem;
  color: #666;
  margin-bottom: 15px;
}

.reset-info {
  margin-top: 15px;
}

.reset-badge {
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: white;
  padding: 8px 16px;
  border-radius: 20px;
  font-size: 0.9rem;
}

/* Podium Styles */
.podium-section {
  margin-bottom: 50px;
}

.podium {
  display: flex;
  justify-content: center;
  align-items: end;
  gap: 20px;
  max-width: 800px;
  margin: 0 auto;
}

.podium-place {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.podium-user {
  background: white;
  border-radius: 20px;
  padding: 20px;
  text-align: center;
  box-shadow: 0 8px 30px rgba(0, 0, 0, 0.1);
  margin-bottom: 10px;
  position: relative;
  z-index: 2;
}

.medal {
  font-size: 2rem;
  margin-bottom: 10px;
}

.avatar {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.5rem;
  font-weight: bold;
  margin: 0 auto 10px;
}

.avatar.winner {
  background: linear-gradient(135deg, #ffd700, #ffed4a);
  color: #333;
  transform: scale(1.1);
}

.podium-user h3 {
  margin: 0 0 5px 0;
  color: #333;
  font-size: 1.1rem;
}

.podium-user p {
  margin: 0 0 5px 0;
  font-size: 1.2rem;
  font-weight: bold;
  color: #007bff;
}

.sessions {
  font-size: 0.8rem;
  color: #666;
}

.podium-base {
  height: 60px;
  width: 120px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 8px 8px 0 0;
  font-weight: bold;
  color: white;
  z-index: 1;
}

.first-base {
  background: linear-gradient(135deg, #ffd700, #ffed4a);
  height: 80px;
  color: #333;
}

.second-base {
  background: linear-gradient(135deg, #c0c0c0, #e8e8e8);
  height: 65px;
  color: #333;
}

.third-base {
  background: linear-gradient(135deg, #cd7f32, #daa520);
  height: 50px;
}

/* Leaderboard Table */
.leaderboard-section {
  margin-bottom: 40px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.section-header h2 {
  color: #333;
  margin: 0;
}

.stats-summary {
  color: #666;
  font-size: 0.9rem;
}

.leaderboard-table {
  background: white;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
}

.table-header {
  display: grid;
  grid-template-columns: 80px 1fr 120px 100px 120px;
  gap: 15px;
  padding: 20px;
  background: #f8f9fa;
  font-weight: bold;
  color: #333;
  border-bottom: 1px solid #e9ecef;
}

.table-row {
  display: grid;
  grid-template-columns: 80px 1fr 120px 100px 120px;
  gap: 15px;
  padding: 20px;
  border-bottom: 1px solid #f1f1f1;
  transition: background-color 0.2s ease;
}

.table-row:hover {
  background-color: #f8f9fa;
}

.table-row.current-user {
  background: linear-gradient(
    135deg,
    rgba(102, 126, 234, 0.1),
    rgba(118, 75, 162, 0.1)
  );
  border-left: 4px solid #667eea;
}

.rank-col {
  display: flex;
  align-items: center;
  gap: 10px;
}

.rank-badge {
  width: 30px;
  height: 30px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  color: white;
  font-size: 0.9rem;
}

.rank-badge.top-1 {
  background: linear-gradient(135deg, #ffd700, #ffed4a);
  color: #333;
}
.rank-badge.top-2 {
  background: linear-gradient(135deg, #c0c0c0, #e8e8e8);
  color: #333;
}
.rank-badge.top-3 {
  background: linear-gradient(135deg, #cd7f32, #daa520);
}
.rank-badge.top-ten {
  background: linear-gradient(135deg, #667eea, #764ba2);
}
.rank-badge.regular {
  background: #6c757d;
}

.trophy-badge {
  font-size: 1.2rem;
}

.user-col {
  display: flex;
  align-items: center;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 12px;
}

.user-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea, #764ba2);
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
}

.user-details {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.username {
  font-weight: 600;
  color: #333;
}

.you-indicator {
  font-size: 0.8rem;
  color: #667eea;
  font-weight: bold;
}

.time-col,
.sessions-col,
.total-col {
  display: flex;
  align-items: center;
}

.time-value {
  font-weight: bold;
  color: #007bff;
}

.sessions-value {
  color: #28a745;
  font-weight: 600;
}

.total-value {
  color: #6c757d;
  font-weight: 600;
}

/* States */
.empty-state,
.loading-state,
.error-state {
  text-align: center;
  padding: 60px 20px;
  color: #666;
}

.empty-icon,
.error-icon {
  font-size: 4rem;
  margin-bottom: 20px;
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

/* Stats Section */
.stats-section {
  margin-top: 50px;
}

.stats-section h2 {
  text-align: center;
  margin-bottom: 30px;
  color: #333;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
}

.stat-card {
  background: white;
  border-radius: 16px;
  padding: 25px;
  display: flex;
  align-items: center;
  gap: 15px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  transition: transform 0.2s ease;
}

.stat-card:hover {
  transform: translateY(-2px);
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

/* Responsive */
@media (max-width: 768px) {
  .podium {
    flex-direction: column;
    align-items: center;
  }

  .podium-place {
    margin-bottom: 20px;
  }

  .table-header,
  .table-row {
    grid-template-columns: 60px 1fr 80px 70px 80px;
    gap: 10px;
    padding: 15px;
    font-size: 0.9rem;
  }

  .stats-grid {
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  }
}
</style>
