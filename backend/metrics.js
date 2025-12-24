// metrics.js - Place this in your backend directory
import promClient from "prom-client";

// Create a Registry to register all metrics
const register = new promClient.Registry();

// Add default Node.js metrics (memory, CPU, etc.)
promClient.collectDefaultMetrics({
  register,
  prefix: "studysync_nodejs_",
});

// ===== CUSTOM METRICS =====

// 1. HTTP Request Duration Histogram
// Tracks how long requests take, grouped by method, route, and status
const httpRequestDuration = new promClient.Histogram({
  name: "studysync_http_request_duration_seconds",
  help: "Duration of HTTP requests in seconds",
  labelNames: ["method", "route", "status_code"],
  buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5], // Response time buckets in seconds
});

// 2. HTTP Request Counter
// Counts total requests by method, route, and status
const httpRequestTotal = new promClient.Counter({
  name: "studysync_http_requests_total",
  help: "Total number of HTTP requests",
  labelNames: ["method", "route", "status_code"],
});

// 3. Active Socket.IO Connections Gauge
// Shows current number of connected users
const activeSocketConnections = new promClient.Gauge({
  name: "studysync_active_socket_connections",
  help: "Number of active Socket.IO connections",
});

// 4. Socket.IO Messages Counter
// Tracks messages sent through Socket.IO
const socketMessagesTotal = new promClient.Counter({
  name: "studysync_socket_messages_total",
  help: "Total number of Socket.IO messages",
  labelNames: ["event_type"], // e.g., 'send_message', 'join_session'
});

// 5. Active Study Sessions Gauge
// Shows how many study sessions are currently active
const activeStudySessions = new promClient.Gauge({
  name: "studysync_active_study_sessions",
  help: "Number of currently active study sessions",
});

// 6. User Registrations Counter
const userRegistrations = new promClient.Counter({
  name: "studysync_user_registrations_total",
  help: "Total number of user registrations",
});

// 7. MongoDB Connection Status
const mongoConnectionStatus = new promClient.Gauge({
  name: "studysync_mongodb_connected",
  help: "MongoDB connection status (1 = connected, 0 = disconnected)",
});

// Register all custom metrics
register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestTotal);
register.registerMetric(activeSocketConnections);
register.registerMetric(socketMessagesTotal);
register.registerMetric(activeStudySessions);
register.registerMetric(userRegistrations);
register.registerMetric(mongoConnectionStatus);

// ===== MIDDLEWARE =====

// Express middleware to automatically track HTTP requests
export const metricsMiddleware = (req, res, next) => {
  const start = Date.now();

  // Capture the original end function
  const originalEnd = res.end;

  // Override res.end to record metrics when response is sent
  res.end = function (...args) {
    const duration = (Date.now() - start) / 1000; // Convert to seconds
    const route = req.route ? req.route.path : req.path;

    // Record duration
    httpRequestDuration.observe(
      { method: req.method, route, status_code: res.statusCode },
      duration
    );

    // Increment counter
    httpRequestTotal.inc({
      method: req.method,
      route,
      status_code: res.statusCode,
    });

    // Call the original end function
    originalEnd.apply(res, args);
  };

  next();
};

// ===== METRIC UPDATERS =====

// Function to update Socket.IO connection count
export const updateSocketConnections = (count) => {
  activeSocketConnections.set(count);
};

// Function to increment Socket.IO message count
export const incrementSocketMessages = (eventType) => {
  socketMessagesTotal.inc({ event_type: eventType });
};

// Function to update active study sessions
export const updateActiveStudySessions = async (Session) => {
  try {
    const count = await Session.countDocuments({ status: "active" });
    activeStudySessions.set(count);
  } catch (error) {
    console.error("Error updating active sessions metric:", error);
  }
};

// Function to increment user registrations
export const incrementUserRegistrations = () => {
  userRegistrations.inc();
};

// Function to update MongoDB connection status
export const updateMongoStatus = (isConnected) => {
  mongoConnectionStatus.set(isConnected ? 1 : 0);
};

// Export the registry so we can expose metrics
export default register;
