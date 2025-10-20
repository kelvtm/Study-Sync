<template>
  <div class="auth-container">
    <div class="auth-card">
      <!-- Header -->
      <div class="auth-header">
        <h1 class="auth-title">Welcome Back</h1>
        <p class="auth-subtitle">Sign in with your email or username</p>
      </div>

      <!-- Login Form -->
      <form @submit.prevent="login" class="auth-form">
        <!-- Email/Username Field -->
        <div class="form-group">
          <label for="email" class="form-label">
            <Mail :size="16" />
            Email or Username
          </label>
          <input
            id="email"
            type="text"
            v-model="email"
            placeholder="Enter your email or username"
            class="input-field"
            :class="{ 'input-error': emailError }"
            required
          />
          <span v-if="emailError" class="error-message">{{ emailError }}</span>
        </div>

        <!-- Password Field -->
        <div class="form-group">
          <label for="password" class="form-label">
            <Lock :size="16" />
            Password
          </label>
          <div class="password-input-container">
            <input
              id="password"
              :type="showPassword ? 'text' : 'password'"
              v-model="password"
              placeholder="Enter your password"
              class="input-field"
              :class="{ 'input-error': passwordError }"
              required
            />
            <button
              type="button"
              @click="togglePassword"
              class="password-toggle"
            >
              <EyeOff v-if="showPassword" :size="18" />
              <Eye v-else :size="18" />
            </button>
          </div>
          <span v-if="passwordError" class="error-message">{{
            passwordError
          }}</span>
        </div>

        <!-- Remember Me & Forgot Password -->
        <div class="form-options">
          <label class="checkbox-label">
            <input type="checkbox" v-model="rememberMe" />
            <span class="checkmark"></span>
            Remember me
          </label>
          <a href="#" class="forgot-link">Forgot password?</a>
        </div>

        <!-- Login Button -->
        <button
          type="submit"
          class="btn-primary auth-button"
          :disabled="isLoading"
          :class="{ loading: isLoading }"
        >
          <Loader2 v-if="isLoading" :size="20" class="spinning" />
          <LogIn v-else :size="20" />
          {{ isLoading ? "Signing In..." : "Sign In" }}
        </button>

        <!-- Error/Success Message -->
        <div v-if="message" class="message" :class="messageType">
          <CheckCircle2 v-if="messageType === 'success'" :size="18" />
          <AlertCircle v-else :size="18" />
          {{ message }}
        </div>
      </form>

      <!-- Sign Up Link -->
      <div class="auth-footer">
        <p>Don't have an account?</p>
        <button @click="goToSignup" class="btn-secondary auth-link">
          <UserPlus :size="18" />
          Create Account
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from "vue";
import { useRouter } from "vue-router";
import { API_BASE_URL } from "@/config";
import {
  Mail,
  Lock,
  Eye,
  EyeOff,
  LogIn,
  UserPlus,
  Loader2,
  CheckCircle2,
  AlertCircle,
} from "lucide-vue-next";

const email = ref("");
const password = ref("");
const rememberMe = ref(false);
const showPassword = ref(false);
const message = ref("");
const messageType = ref("");
const isLoading = ref(false);
const emailError = ref("");
const passwordError = ref("");

const router = useRouter();

const validateEmail = () => {
  if (!email.value) {
    emailError.value = "Email or username is required";
    return false;
  } else {
    emailError.value = "";
    return true;
  }
};

const validatePassword = () => {
  if (!password.value) {
    passwordError.value = "Password is required";
    return false;
  } else if (password.value.length < 6) {
    passwordError.value = "Password must be at least 6 characters";
    return false;
  } else {
    passwordError.value = "";
    return true;
  }
};

const togglePassword = () => {
  showPassword.value = !showPassword.value;
};

const login = async () => {
  // Clear previous errors
  emailError.value = "";
  passwordError.value = "";
  message.value = "";

  // Validate inputs
  const isEmailValid = validateEmail();
  const isPasswordValid = validatePassword();

  if (!isEmailValid || !isPasswordValid) {
    return;
  }

  isLoading.value = true;

  try {
    const res = await fetch(`${API_BASE_URL}/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        email: email.value,
        password: password.value,
      }),
    });

    const data = await res.json();

    if (res.ok && data.user) {
      messageType.value = "success";
      message.value = "Login successful! Redirecting...";

      // Store user data
      localStorage.setItem("userId", data.user.id);
      localStorage.setItem("username", data.user.username);

      // Redirect after a brief delay
      setTimeout(() => {
        router.push("/sync");
      }, 1500);
    } else {
      messageType.value = "error";
      message.value = data.message || "Invalid credentials";
    }
  } catch (err) {
    messageType.value = "error";
    message.value = "Network error. Please try again.";
    console.error("Login error:", err);
  } finally {
    isLoading.value = false;
  }
};

const goToSignup = () => {
  router.push("/signup");
};
</script>

<style scoped>
.auth-container {
  min-height: calc(100vh - 80px);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 2rem 1rem;
  background: linear-gradient(
    135deg,
    var(--background) 0%,
    var(--background-secondary) 100%
  );
}

.auth-card {
  background: white;
  border-radius: var(--border-radius-large);
  box-shadow: var(--box-shadow);
  padding: 2.5rem;
  width: 100%;
  max-width: 450px;
  position: relative;
  overflow: hidden;
}

.auth-card::before {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 4px;
  background: linear-gradient(
    90deg,
    var(--primary-color),
    var(--secondary-color)
  );
}

.auth-header {
  text-align: center;
  margin-bottom: 2rem;
}

.auth-title {
  font-size: 2rem;
  font-weight: 700;
  color: var(--color-heading);
  margin-bottom: 0.5rem;
}

.auth-subtitle {
  color: var(--color-text-secondary);
  font-size: 1rem;
}

.auth-form {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.form-label {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 600;
  color: var(--color-text);
  font-size: 0.9rem;
}

.form-label svg {
  color: var(--primary-variant);
}

.input-field {
  padding: 1rem;
  border: 2px solid var(--color-border);
  border-radius: var(--border-radius);
  font-size: 1rem;
  transition: var(--transition-fast);
  background: var(--background-secondary);
  color: var(--color-text);
}

.input-field:focus {
  outline: none;
  border-color: var(--secondary-color);
  box-shadow: 0 0 0 3px rgba(52, 220, 59, 0.1);
}

.input-field.input-error {
  border-color: var(--color-error);
}

.password-input-container {
  position: relative;
}

.password-toggle {
  position: absolute;
  right: 1rem;
  top: 50%;
  transform: translateY(-50%);
  background: none;
  border: none;
  color: var(--color-text-secondary);
  cursor: pointer;
  padding: 0.25rem;
  border-radius: 4px;
  transition: var(--transition-fast);
  display: flex;
  align-items: center;
  justify-content: center;
}

.password-toggle:hover {
  color: var(--color-text);
  background: var(--color-hover);
}

.form-options {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.9rem;
}

.checkbox-label {
  display: flex;
  align-items: center;
  cursor: pointer;
  color: var(--color-text);
}

.checkbox-label input {
  display: none;
}

.checkmark {
  width: 18px;
  height: 18px;
  border: 2px solid var(--color-border);
  border-radius: 4px;
  margin-right: 0.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: var(--transition-fast);
}

.checkbox-label input:checked + .checkmark {
  background: var(--secondary-color);
  border-color: var(--secondary-color);
}

.checkbox-label input:checked + .checkmark::after {
  content: "✓";
  color: white;
  font-size: 12px;
  font-weight: bold;
}

.forgot-link {
  color: var(--secondary-color);
  text-decoration: none;
  font-weight: 500;
  transition: var(--transition-fast);
}

.forgot-link:hover {
  text-decoration: underline;
}

.auth-button {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 1rem 2rem;
  font-size: 1.1rem;
  font-weight: 600;
  border: none;
  border-radius: var(--border-radius);
  cursor: pointer;
  transition: var(--transition-normal);
  background: linear-gradient(
    135deg,
    var(--secondary-color),
    var(--secondary-variant)
  );
  color: white;
  margin-top: 0.5rem;
}

.auth-button:hover:not(:disabled) {
  background: var(--secondary-hover);
  transform: translateY(-1px);
  box-shadow: var(--box-shadow-light);
}

.auth-button:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}

.auth-button.loading {
  pointer-events: none;
}

.spinning {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

.message {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 1rem;
  border-radius: var(--border-radius);
  font-weight: 500;
  margin-top: 0.5rem;
}

.message.success {
  background: rgba(40, 167, 69, 0.1);
  color: var(--color-success);
  border: 1px solid rgba(40, 167, 69, 0.3);
}

.message.error {
  background: rgba(220, 53, 69, 0.1);
  color: var(--color-error);
  border: 1px solid rgba(220, 53, 69, 0.3);
}

.error-message {
  color: var(--color-error);
  font-size: 0.85rem;
  font-weight: 500;
}

.auth-footer {
  text-align: center;
  margin-top: 2rem;
  padding-top: 1.5rem;
  border-top: 1px solid var(--color-border);
}

.auth-footer p {
  color: var(--color-text-secondary);
  margin-bottom: 1rem;
}

.auth-link {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1.5rem;
  background: transparent;
  color: var(--secondary-color);
  border: 2px solid var(--secondary-color);
  border-radius: var(--border-radius);
  text-decoration: none;
  font-weight: 600;
  transition: var(--transition-fast);
  cursor: pointer;
}

.auth-link:hover {
  background: var(--secondary-color);
  color: white;
  transform: translateY(-1px);
}

/* Dark Mode Support */
@media (prefers-color-scheme: dark) {
  .auth-card {
    background: var(--background);
    color: var(--color-text);
  }
}

/* Responsive Design */
@media (max-width: 768px) {
  .auth-container {
    padding: 1rem;
  }

  .auth-card {
    padding: 2rem 1.5rem;
  }

  .form-options {
    flex-direction: column;
    gap: 1rem;
    align-items: flex-start;
  }
}
</style>
