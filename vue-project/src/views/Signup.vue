<template>
  <div class="auth-container">
    <div class="auth-card">
      <!-- Header -->
      <div class="auth-header">
        <h1 class="auth-title">Join StudySync</h1>
        <p class="auth-subtitle">
          Create your account and start studying with peers
        </p>
      </div>

      <!-- Signup Form -->
      <form @submit.prevent="signup" class="auth-form">
        <!-- Email Field -->
        <div class="form-group">
          <label for="email" class="form-label">
            <Mail :size="16" />
            Email Address
          </label>
          <input
            id="email"
            type="email"
            v-model="email"
            placeholder="Enter your email"
            class="input-field"
            :class="{ 'input-error': emailError }"
            required
          />
          <span v-if="emailError" class="error-message">{{ emailError }}</span>
        </div>

        <!-- Username Field -->
        <div class="form-group">
          <label for="username" class="form-label">
            <User :size="16" />
            Username
          </label>
          <input
            id="username"
            type="text"
            v-model="username"
            placeholder="Choose a unique username"
            class="input-field"
            :class="{ 'input-error': usernameError }"
            required
          />
          <span v-if="usernameError" class="error-message">{{
            usernameError
          }}</span>
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
              placeholder="Create a strong password"
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

          <!-- Password Strength Indicator -->
          <div v-if="password" class="password-strength">
            <div class="strength-bar">
              <div
                class="strength-fill"
                :class="passwordStrength.level"
                :style="{ width: passwordStrength.percentage + '%' }"
              ></div>
            </div>
            <div class="strength-text">
              <span :class="passwordStrength.level">
                {{ passwordStrength.text }}
              </span>
              <span class="strength-requirements">
                {{ passwordStrength.requirements }}
              </span>
            </div>
          </div>

          <span v-if="passwordError" class="error-message">{{
            passwordError
          }}</span>
        </div>

        <!-- Confirm Password Field -->
        <div class="form-group">
          <label for="confirmPassword" class="form-label">
            <ShieldCheck :size="16" />
            Confirm Password
          </label>
          <div class="password-input-container">
            <input
              id="confirmPassword"
              :type="showConfirmPassword ? 'text' : 'password'"
              v-model="confirmPassword"
              placeholder="Confirm your password"
              class="input-field"
              :class="{
                'input-error': confirmPasswordError,
                'input-success':
                  confirmPassword &&
                  !confirmPasswordError &&
                  confirmPassword === password,
              }"
              required
            />
            <button
              type="button"
              @click="toggleConfirmPassword"
              class="password-toggle"
            >
              <EyeOff v-if="showConfirmPassword" :size="18" />
              <Eye v-else :size="18" />
            </button>
          </div>
          <span v-if="confirmPasswordError" class="error-message">{{
            confirmPasswordError
          }}</span>
          <span
            v-else-if="confirmPassword && confirmPassword === password"
            class="success-message"
          >
            <Check :size="14" />
            Passwords match
          </span>
        </div>

        <!-- Terms and Conditions -->
        <div class="form-group">
          <label class="checkbox-label">
            <input type="checkbox" v-model="acceptTerms" required />
            <span class="checkmark"></span>
            I agree to the
            <a href="#" class="terms-link">Terms of Service</a>
            and
            <a href="#" class="terms-link">Privacy Policy</a>
          </label>
          <span v-if="termsError" class="error-message">{{ termsError }}</span>
        </div>

        <!-- Signup Button -->
        <button
          type="submit"
          class="btn-primary auth-button"
          :disabled="isLoading"
          :class="{ loading: isLoading }"
        >
          <Loader2 v-if="isLoading" :size="20" class="spinning" />
          <UserPlus v-else :size="20" />
          {{ isLoading ? "Creating Account..." : "Create Account" }}
        </button>

        <!-- Error/Success Message -->
        <div v-if="message" class="message" :class="messageType">
          <CheckCircle2 v-if="messageType === 'success'" :size="18" />
          <AlertCircle v-else :size="18" />
          {{ message }}
        </div>
      </form>

      <!-- Sign In Link -->
      <div class="auth-footer">
        <p>Already have an account?</p>
        <button @click="goToSignin" class="btn-secondary auth-link">
          <LogIn :size="18" />
          Sign In
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch } from "vue";
import { useRouter } from "vue-router";
import { API_BASE_URL } from "@/config";
import {
  Mail,
  User,
  Lock,
  Eye,
  EyeOff,
  ShieldCheck,
  Check,
  UserPlus,
  LogIn,
  Loader2,
  CheckCircle2,
  AlertCircle,
} from "lucide-vue-next";

// Form data
const email = ref("");
const username = ref("");
const password = ref("");
const confirmPassword = ref("");
const acceptTerms = ref(false);

// UI state
const showPassword = ref(false);
const showConfirmPassword = ref(false);
const isLoading = ref(false);

// Error states
const emailError = ref("");
const usernameError = ref("");
const passwordError = ref("");
const confirmPasswordError = ref("");
const termsError = ref("");

// Message state
const message = ref("");
const messageType = ref("");

// Password strength
const passwordStrength = ref({
  level: "weak",
  percentage: 0,
  text: "",
  requirements: "",
});

const router = useRouter();

// Client-side validation functions
const validateEmail = () => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!email.value) {
    emailError.value = "Email is required";
    return false;
  } else if (!emailRegex.test(email.value)) {
    emailError.value = "Please enter a valid email address";
    return false;
  } else {
    emailError.value = "";
    return true;
  }
};

const validateUsername = () => {
  if (!username.value) {
    usernameError.value = "Username is required";
    return false;
  } else if (username.value.trim().length < 3) {
    usernameError.value = "Username must be at least 3 characters";
    return false;
  } else if (!/^[a-zA-Z0-9_]+$/.test(username.value.trim())) {
    usernameError.value =
      "Username can only contain letters, numbers, and underscores";
    return false;
  } else {
    usernameError.value = "";
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

const validatePasswordMatch = () => {
  if (!confirmPassword.value) {
    confirmPasswordError.value = "Please confirm your password";
    return false;
  } else if (password.value !== confirmPassword.value) {
    confirmPasswordError.value = "Passwords do not match";
    return false;
  } else {
    confirmPasswordError.value = "";
    return true;
  }
};

const validateTerms = () => {
  if (!acceptTerms.value) {
    termsError.value = "You must accept the terms and conditions";
    return false;
  } else {
    termsError.value = "";
    return true;
  }
};

// Password strength checking
const checkPasswordStrength = () => {
  const pwd = password.value;
  let score = 0;
  let requirements = [];

  if (pwd.length >= 8) {
    score += 1;
  } else {
    requirements.push("8+ characters");
  }

  if (/[a-z]/.test(pwd)) {
    score += 1;
  } else {
    requirements.push("lowercase");
  }

  if (/[A-Z]/.test(pwd)) {
    score += 1;
  } else {
    requirements.push("uppercase");
  }

  if (/[0-9]/.test(pwd)) {
    score += 1;
  } else {
    requirements.push("numbers");
  }

  if (/[^A-Za-z0-9]/.test(pwd)) {
    score += 1;
  } else {
    requirements.push("special characters");
  }

  // Update password strength
  if (score <= 2) {
    passwordStrength.value = {
      level: "weak",
      percentage: 20,
      text: "Weak",
      requirements:
        requirements.length > 0 ? `Missing: ${requirements.join(", ")}` : "",
    };
  } else if (score === 3) {
    passwordStrength.value = {
      level: "medium",
      percentage: 60,
      text: "Medium",
      requirements:
        requirements.length > 0 ? `Missing: ${requirements.join(", ")}` : "",
    };
  } else if (score >= 4) {
    passwordStrength.value = {
      level: "strong",
      percentage: 100,
      text: "Strong",
      requirements: "Good password!",
    };
  }
};

// Toggle password visibility
const togglePassword = () => {
  showPassword.value = !showPassword.value;
};

const toggleConfirmPassword = () => {
  showConfirmPassword.value = !showConfirmPassword.value;
};

// Watch password changes for strength checking
watch(password, () => {
  if (password.value) {
    checkPasswordStrength();
  }
  // Also revalidate password match when password changes
  if (confirmPassword.value) {
    validatePasswordMatch();
  }
});

// Watch confirm password for match validation
watch(confirmPassword, validatePasswordMatch);

// Form submission
const signup = async () => {
  // Clear previous messages
  message.value = "";
  messageType.value = "";

  // Validate all fields
  const isEmailValid = validateEmail();
  const isUsernameValid = validateUsername();
  const isPasswordValid = validatePassword();
  const isPasswordMatchValid = validatePasswordMatch();
  const areTermsValid = validateTerms();

  if (
    !isEmailValid ||
    !isUsernameValid ||
    !isPasswordValid ||
    !isPasswordMatchValid ||
    !areTermsValid
  ) {
    return;
  }

  isLoading.value = true;

  try {
    const res = await fetch(`${API_BASE_URL}/api/signup`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        email: email.value,
        username: username.value.trim(),
        password: password.value,
      }),
    });

    const data = await res.json();

    if (res.ok) {
      messageType.value = "success";
      message.value = "Account created successfully! Redirecting to login...";

      // Clear form
      email.value = "";
      username.value = "";
      password.value = "";
      confirmPassword.value = "";
      acceptTerms.value = false;

      // Redirect after delay
      setTimeout(() => {
        router.push("/signin");
      }, 2000);
    } else {
      messageType.value = "error";
      message.value = data.message || "Failed to create account";

      // Handle specific server errors
      if (data.message === "Email already exists") {
        emailError.value = "This email is already registered";
      }
      if (data.message === "Username already taken") {
        usernameError.value = "This username is already taken";
      }
    }
  } catch (err) {
    messageType.value = "error";
    message.value = "Network error. Please try again.";
  } finally {
    isLoading.value = false;
  }
};

const goToSignin = () => {
  router.push("/signin");
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
  max-width: 500px;
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
  line-height: 1.4;
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

.input-field.input-success {
  border-color: var(--color-success);
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

.error-message {
  color: var(--color-error);
  font-size: 0.85rem;
  font-weight: 500;
}

.success-message {
  color: var(--color-success);
  font-size: 0.85rem;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 0.25rem;
}

/* Password Strength Indicator */
.password-strength {
  margin-top: 0.5rem;
}

.strength-bar {
  width: 100%;
  height: 4px;
  background: var(--color-border);
  border-radius: 2px;
  overflow: hidden;
  margin-bottom: 0.5rem;
}

.strength-fill {
  height: 100%;
  transition: var(--transition-normal);
  border-radius: 2px;
}

.strength-fill.weak {
  background: var(--color-error);
}

.strength-fill.medium {
  background: var(--color-warning);
}

.strength-fill.strong {
  background: var(--color-success);
}

.strength-text {
  display: flex;
  justify-content: space-between;
  font-size: 0.8rem;
}

.strength-text .weak {
  color: var(--color-error);
  font-weight: 600;
}

.strength-text .medium {
  color: var(--color-warning);
  font-weight: 600;
}

.strength-text .strong {
  color: var(--color-success);
  font-weight: 600;
}

.strength-requirements {
  color: var(--color-text-secondary);
  font-style: italic;
}

/* Checkbox Styling */
.checkbox-label {
  display: flex;
  align-items: flex-start;
  cursor: pointer;
  color: var(--color-text);
  line-height: 1.5;
  gap: 0.5rem;
}

.checkbox-label input {
  display: none;
}

.checkmark {
  width: 18px;
  height: 18px;
  min-width: 18px;
  border: 2px solid var(--color-border);
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: var(--transition-fast);
  margin-top: 2px;
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

.terms-link {
  color: var(--secondary-color);
  text-decoration: none;
  font-weight: 500;
  transition: var(--transition-fast);
}

.terms-link:hover {
  text-decoration: underline;
}

/* Auth Button */
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
  background: var(--color-border);
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

/* Messages */
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

/* Auth Footer */
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
    max-width: 100%;
  }

  .auth-title {
    font-size: 1.75rem;
  }

  .strength-text {
    flex-direction: column;
    gap: 0.25rem;
  }
}

@media (max-width: 480px) {
  .auth-card {
    padding: 1.5rem 1rem;
  }
}
</style>
