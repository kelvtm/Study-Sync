import { createRouter, createWebHistory } from "vue-router";
import SignIn from "../views/SignIn.vue";
import SignupView from "../views/SignupView.vue";
import HomeView from "../views/HomeView.vue";
import SyncSession from "../views/SyncSession.vue";

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
  ],
});

export default router;
