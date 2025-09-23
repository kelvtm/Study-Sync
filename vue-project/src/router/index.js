import { createRouter, createWebHistory } from "vue-router";
import SignIn from "../views/SignIn.vue";
import SignupView from "../views/Signup.vue";
import LandingPage from "../views/LandingPage.vue";
import SyncSession from "../views/SyncSession.vue";
import UserProfile from "@/views/UserProfile.vue";
import PeerLeaderboard from "@/views/PeerLeaderboard.vue";
import TaskBreakdown from "@/views/TaskBreakdown.vue";

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: "/signin",
      name: "signin",
      component: SignIn,
    },
    { path: "/signup", name: "signup", component: SignupView },
    {
      path: "/",
      name: "landingpage",
      component: LandingPage,
    },
    { path: "/sync", name: "sync", component: SyncSession },
    { path: "/profile", name: "profile", component: UserProfile },
    { path: "/leaderboard", name: "leaderboard", component: PeerLeaderboard },
    { path: "/task", name: "task", component: TaskBreakdown },
  ],
});

export default router;
