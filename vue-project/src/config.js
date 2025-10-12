// vue-project/src/config.js
const API_BASE_URL =
  import.meta.env.MODE === "production"
    ? "https://jettoner.xyz"
    : "http://localhost:3000";

const SOCKET_URL =
  import.meta.env.MODE === "production"
    ? "https://jettoner.xyz"
    : "http://localhost:3000";

export { API_BASE_URL, SOCKET_URL };
