import { createRouter, createWebHistory } from "vue-router";
import SignIn from "../views/SignIn.vue";
import SignupView from "../views/SignupView.vue";
import HomeView from "../views/HomeView.vue";
import SyncSession from "../views/SyncSession.vue";
import UserProfile from "@/views/UserProfile.vue";
import PeerLeaderboard from "@/views/PeerLeaderboard.vue";
import TaskBreakdown from "@/views/TaskBreakdown.vue";

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: "/",
      name: "signin",
      component: SignIn,
    },
    { path: "/signup", name: "signup", component: SignupView },
    {
      path: "/home",
      name: "home",
      component: HomeView,
    },
    { path: "/sync", name: "sync", component: SyncSession },
    { path: "/profile", name: "profile", component: UserProfile },
    { path: "/leaderboard", name: "leaderboard", component: PeerLeaderboard },
    { path: "/task", name: "task", component: TaskBreakdown },
  ],
});

export default router;
