import request from "supertest";
import mongoose from "mongoose";
import dotenv from "dotenv";

// Load environment variables (kept simple, relying on server.js to load the right .env file)
dotenv.config();

// We'll test against your actual server
const BASE_URL = process.env.TEST_API_URL || "http://localhost:3001";

// Test data
const testUser = {
  email: `test_${Date.now()}@example.com`,
  username: `tuser_${Date.now()}`,
  password: "Test123456",
};

describe("StudySync API Tests", () => {
  let userId;

  // ==========================================
  // HEALTH CHECK TESTS
  // ==========================================
  describe("GET /api/health", () => {
    it("should return status ok", async () => {
      const startTime = Date.now();

      const response = await request(BASE_URL)
        .get("/api/health")
        .expect("Content-Type", /json/)
        .expect(200);

      const responseTime = Date.now() - startTime;

      expect(response.body).toHaveProperty("status", "ok");
      expect(responseTime).toBeLessThan(1000); // Should respond within 1 second

      console.log(`✅ Health check response time: ${responseTime}ms`);
    });
  });

  // ==========================================
  // SIGNUP TESTS
  // ==========================================
  describe("POST /api/signup", () => {
    it("should create a new user account", async () => {
      const startTime = Date.now();

      const response = await request(BASE_URL)
        .post("/api/signup") // <-- FIXED ROUTE
        .send(testUser)
        .expect("Content-Type", /json/)
        .expect(201);

      const responseTime = Date.now() - startTime;

      expect(response.body).toHaveProperty(
        "message",
        "Account created successfully"
      );
      expect(response.body).toHaveProperty("user");
      expect(response.body.user).toHaveProperty("email", testUser.email);
      expect(response.body.user).toHaveProperty("username", testUser.username);
      expect(response.body.user).toHaveProperty("id");
      expect(response.body.user).not.toHaveProperty("password"); // Password should not be returned

      userId = response.body.user.id;

      console.log(`✅ Signup response time: ${responseTime}ms`);
    }, 10000); // 10 second timeout for database operations

    it("should reject duplicate email", async () => {
      const response = await request(BASE_URL)
        .post("/api/signup") // <-- FIXED ROUTE
        .send(testUser)
        .expect("Content-Type", /json/)
        .expect(400);

      expect(response.body).toHaveProperty("message", "Email already exists");
    });

    it("should reject invalid username (too short)", async () => {
      const response = await request(BASE_URL)
        .post("/api/signup") // <-- FIXED ROUTE
        .send({
          email: "newuser@example.com",
          username: "ab",
          password: "Test123456",
        })
        .expect("Content-Type", /json/)
        .expect(400);

      expect(response.body).toHaveProperty(
        "message",
        "Username must be at least 3 characters"
      );
    });

    it("should reject invalid password (too short)", async () => {
      const response = await request(BASE_URL)
        .post("/api/signup") // <-- FIXED ROUTE
        .send({
          email: "newuser2@example.com",
          username: "validuser",
          password: "12345",
        })
        .expect("Content-Type", /json/)
        .expect(400);

      expect(response.body).toHaveProperty(
        "message",
        "Password must be at least 6 characters"
      );
    });
  });

  // ==========================================
  // LOGIN TESTS
  // ==========================================
  describe("POST /api/login", () => {
    it("should login with email", async () => {
      const startTime = Date.now();

      const response = await request(BASE_URL)
        .post("/api/login") // <-- FIXED ROUTE
        .send({
          email: testUser.email,
          password: testUser.password,
        })
        .expect("Content-Type", /json/)
        .expect(200);

      const responseTime = Date.now() - startTime;

      expect(response.body).toHaveProperty("message", "Login successful!");
      expect(response.body).toHaveProperty("user");
      expect(response.body.user).toHaveProperty("email", testUser.email);
      expect(response.body.user).not.toHaveProperty("password"); // Password should not be returned

      console.log(`✅ Login (email) response time: ${responseTime}ms`);
    }, 10000);

    it("should login with username", async () => {
      const startTime = Date.now();

      const response = await request(BASE_URL)
        .post("/api/login") // <-- FIXED ROUTE
        .send({
          email: testUser.username, // Using username in email field
          password: testUser.password,
        })
        .expect("Content-Type", /json/)
        .expect(200);

      const responseTime = Date.now() - startTime;

      expect(response.body).toHaveProperty("message", "Login successful!");
      expect(response.body.user).toHaveProperty("username", testUser.username);

      console.log(`✅ Login (username) response time: ${responseTime}ms`);
    }, 10000);

    it("should reject invalid credentials", async () => {
      const response = await request(BASE_URL)
        .post("/api/login") // <-- FIXED ROUTE
        .send({
          email: testUser.email,
          password: "WrongPassword123",
        })
        .expect("Content-Type", /json/)
        .expect(401);

      expect(response.body).toHaveProperty("message", "Invalid credentials");
    });

    it("should reject non-existent user", async () => {
      const response = await request(BASE_URL)
        .post("/api/login") // <-- FIXED ROUTE
        .send({
          email: "nonexistent@example.com",
          password: "Password123",
        })
        .expect("Content-Type", /json/)
        .expect(401);

      expect(response.body).toHaveProperty("message", "Invalid credentials");
    });
  });

  // ==========================================
  // USER STATS TESTS
  // ==========================================
  describe("GET /api/users/:userId/stats", () => {
    it("should get user stats", async () => {
      const startTime = Date.now();

      // This test relies on the successful signup from the previous block
      if (!userId) {
        throw new Error("Test setup failed: userId not set after signup.");
      }

      const response = await request(BASE_URL)
        .get(`/api/users/${userId}/stats`)
        .expect("Content-Type", /json/)
        .expect(200);

      const responseTime = Date.now() - startTime;

      expect(response.body).toHaveProperty("stats");
      expect(response.body).toHaveProperty("user");
      expect(response.body.stats).toHaveProperty("totalStudyMinutes");
      expect(response.body.stats).toHaveProperty("completedSessions");
      expect(response.body.user).toHaveProperty("username", testUser.username);

      console.log(`✅ Get stats response time: ${responseTime}ms`);
    });

    it("should return 404 for non-existent user", async () => {
      const fakeId = "507f1f77bcf86cd799439011"; // Valid MongoDB ObjectId format

      const response = await request(BASE_URL)
        .get(`/api/users/${fakeId}/stats`)
        .expect("Content-Type", /json/)
        .expect(404);

      expect(response.body).toHaveProperty("message", "User not found");
    });
  });

  // ==========================================
  // LEADERBOARD TESTS
  // ==========================================
  describe("GET /api/leaderboard", () => {
    it("should get leaderboard", async () => {
      const startTime = Date.now();

      const response = await request(BASE_URL)
        .get("/api/leaderboard")
        .expect("Content-Type", /json/)
        .expect(200);

      const responseTime = Date.now() - startTime;

      expect(response.body).toHaveProperty("leaderboard");
      expect(Array.isArray(response.body.leaderboard)).toBe(true);

      // If there are users, check structure
      if (response.body.leaderboard.length > 0) {
        const firstUser = response.body.leaderboard[0];
        expect(firstUser).toHaveProperty("rank");
        expect(firstUser).toHaveProperty("username");
        expect(firstUser).toHaveProperty("weeklyStudyMinutes");
      }

      console.log(`✅ Leaderboard response time: ${responseTime}ms`);
      console.log(
        `   Total users on leaderboard: ${response.body.leaderboard.length}`
      );
    });
  });

  // ==========================================
  // PERFORMANCE TESTS
  // ==========================================
  describe("Performance Tests", () => {
    it("should handle multiple concurrent requests", async () => {
      const requests = [];
      const numRequests = 10;

      const startTime = Date.now();

      // Create 10 concurrent requests
      for (let i = 0; i < numRequests; i++) {
        requests.push(request(BASE_URL).get("/api/health").expect(200));
      }

      await Promise.all(requests);

      const totalTime = Date.now() - startTime;
      const avgTime = totalTime / numRequests;

      console.log(
        `✅ ${numRequests} concurrent requests completed in ${totalTime}ms`
      );
      console.log(`   Average response time: ${avgTime.toFixed(2)}ms`);

      expect(avgTime).toBeLessThan(500); // Average should be under 500ms
    });
  });

  // ==========================================
  // CLEANUP
  // ==========================================
  afterAll(async () => {
    // 💡 IMPROVEMENT: If userId was set, delete the user from the database.
    if (userId) {
      // You'll need to expose a direct DB connection or a cleanup endpoint
      try {
        // Replace 'User' with your actual Mongoose model name
        // This part needs your server to expose the Mongoose connection or a cleanup endpoint
        // console.log(`🧹 Attempted to clean up test user with ID: ${userId}`);
      } catch (error) {
        // Handle error (e.g., model isn't available in this scope)
        console.error("Cleanup failed:", error.message);
      }
    }
    console.log("✅ All tests completed!");
  });
});
