import { createRouter, createWebHistory } from "vue-router";
import SignIn from "../views/SignIn.vue";
import SignupView from "../views/SignupView.vue";

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: "/",
      name: "home",
      component: SignIn,
    },
    { path: "/signup", name: "signup", component: SignupView },
    {
      path: "/studysync",
      name: "studysync",
      component: () => import("../views/HomeView.vue"),
    },
  ],
});

export default router;
