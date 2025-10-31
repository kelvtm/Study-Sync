// vue-project/src/config.js
// For microservices, use relative URLs - Nginx handles proxying

const API_BASE_URL = import.meta.env.VITE_API_URL || "";
const SOCKET_URL = import.meta.env.VITE_SOCKET_URL || "";

export { API_BASE_URL, SOCKET_URL };
