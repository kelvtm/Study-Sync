<template>
  <div class="landing-page">
    <!-- Hero Section -->
    <section class="hero-section">
      <div class="hero-content">
        <!-- Main Heading -->
        <div class="hero-text">
          <h1 class="main-title">
            Transform Your Study Habits with
            <span class="highlight">Peer Collaboration</span>
          </h1>
          <p class="subtitle">
            Break free from procrastination and achieve academic success through
            structured study sessions with motivated peers
          </p>
        </div>

        <!-- Call-to-Action Buttons -->
        <div class="cta-buttons">
          <button @click="goToUp" class="btn-primary cta-primary">
            <i class="fas fa-rocket"></i>
            Get Started Free
          </button>
          <button @click="goToIn" class="btn-secondary cta-secondary">
            <i class="fas fa-sign-in-alt"></i>
            Sign In
          </button>
        </div>

        <!-- Feature Highlights -->
        <div class="feature-highlights">
          <div class="feature-item">
            <i class="fas fa-users"></i>
            <span>Study Groups</span>
          </div>
          <div class="feature-item">
            <i class="fas fa-target"></i>
            <span>Goal Tracking</span>
          </div>
          <div class="feature-item">
            <i class="fas fa-trophy"></i>
            <span>Leaderboards</span>
          </div>
        </div>
      </div>

      <!-- Hero Image -->
      <div class="hero-image">
        <div class="image-container">
          <img
            src="https://media.istockphoto.com/id/2225813956/photo/group-of-students-collaborating-during-study-session-in-library-setting.jpg?s=612x612&w=0&k=20&c=Ueo8vMnxvbvPFy6Oefc4HBaAv1G1haGnZ-EGmLIqCuo="
            alt="Students collaborating in study session"
            class="main-image"
          />
          <div class="image-overlay"></div>
          <div class="floating-stats">
            <div class="stat-item">
              <div class="stat-number">2.5k+</div>
              <div class="stat-label">Active Students</div>
            </div>
            <div class="stat-item">
              <div class="stat-number">85%</div>
              <div class="stat-label">Success Rate</div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Benefits Section -->
    <section class="benefits-section">
      <div class="benefits-grid">
        <div class="benefit-card">
          <div class="benefit-icon">
            <i class="fas fa-clock"></i>
          </div>
          <h3>Beat Procrastination</h3>
          <p>
            Structured study sessions with accountability partners keep you
            focused and motivated
          </p>
        </div>

        <div class="benefit-card">
          <div class="benefit-icon">
            <i class="fas fa-graduation-cap"></i>
          </div>
          <h3>Improve Grades</h3>
          <p>
            Collaborative learning helps you understand concepts better and
            retain information longer
          </p>
        </div>

        <div class="benefit-card">
          <div class="benefit-icon">
            <i class="fas fa-handshake"></i>
          </div>
          <h3>Build Connections</h3>
          <p>
            Connect with like-minded students and build lasting study
            partnerships
          </p>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { useRouter } from "vue-router";

const router = useRouter();

const goToIn = () => {
  router.push("/signin");
};

const goToUp = () => {
  router.push("/signup");
};
</script>

<style scoped>
.landing-page {
  min-height: 100vh;
  background: linear-gradient(
    135deg,
    var(--background) 0%,
    var(--background-secondary) 100%
  );
}

/* Hero Section */
.hero-section {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 4rem;
  align-items: center;
  padding: 4rem 2rem;
  max-width: 1400px;
  margin: 0 auto;
  min-height: 90vh;
}

.hero-content {
  display: flex;
  flex-direction: column;
  gap: 2.5rem;
}

/* Hero Text */
.main-title {
  font-size: clamp(2.5rem, 5vw, 4rem);
  font-weight: 800;
  line-height: 1.2;
  color: var(--color-heading);
  margin-bottom: 1rem;
}

.highlight {
  color: var(--secondary-color);
  position: relative;
}

.highlight::after {
  content: "";
  position: absolute;
  bottom: -4px;
  left: 0;
  width: 100%;
  height: 4px;
  background: linear-gradient(
    90deg,
    var(--secondary-color),
    var(--secondary-variant)
  );
  border-radius: 2px;
}

.subtitle {
  font-size: 1.25rem;
  color: var(--color-text-secondary);
  line-height: 1.6;
  max-width: 500px;
}

/* CTA Buttons */
.cta-buttons {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
}

.cta-primary,
.cta-secondary {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 1rem 2rem;
  font-size: 1.1rem;
  font-weight: 600;
  border-radius: var(--border-radius);
  border: none;
  cursor: pointer;
  transition: var(--transition-normal);
  text-decoration: none;
  min-width: 180px;
  justify-content: center;
}

.cta-primary {
  background: linear-gradient(
    135deg,
    var(--secondary-color),
    var(--secondary-variant)
  );
  color: white;
  box-shadow: var(--box-shadow-light);
}

.cta-primary:hover {
  background: var(--secondary-hover);
  transform: translateY(-2px);
  box-shadow: var(--box-shadow);
}

.cta-secondary {
  background: transparent;
  color: var(--color-text);
  border: 2px solid var(--color-border);
}

.cta-secondary:hover {
  background: var(--color-hover);
  border-color: var(--color-border-hover);
  transform: translateY(-1px);
}

/* Feature Highlights */
.feature-highlights {
  display: flex;
  gap: 2rem;
  margin-top: 1rem;
}

.feature-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1rem;
  background: var(--background-secondary);
  border-radius: var(--border-radius);
  color: var(--color-text);
  font-weight: 500;
  box-shadow: var(--box-shadow-light);
}

.feature-item i {
  color: var(--primary-variant);
  font-size: 1.1rem;
}

/* Hero Image */
.hero-image {
  display: flex;
  justify-content: center;
  align-items: center;
}

.image-container {
  position: relative;
  max-width: 500px;
  width: 100%;
}

.main-image {
  width: 100%;
  height: auto;
  border-radius: var(--border-radius-large);
  box-shadow: var(--box-shadow);
  transition: var(--transition-normal);
}

.main-image:hover {
  transform: scale(1.02);
}

.image-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(
    135deg,
    rgba(176, 226, 90, 0.1),
    rgba(196, 44, 60, 0.1)
  );
  border-radius: var(--border-radius-large);
  pointer-events: none;
}

/* Floating Stats */
.floating-stats {
  position: absolute;
  bottom: -20px;
  right: -20px;
  display: flex;
  gap: 1rem;
}

.stat-item {
  background: white;
  padding: 1rem 1.5rem;
  border-radius: var(--border-radius);
  box-shadow: var(--box-shadow);
  text-align: center;
  min-width: 100px;
}

.stat-number {
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--secondary-color);
}

.stat-label {
  font-size: 0.8rem;
  color: var(--color-text-secondary);
  margin-top: 0.25rem;
}

/* Benefits Section */
.benefits-section {
  padding: 4rem 2rem;
  background: var(--background-secondary);
}

.benefits-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 2rem;
  max-width: 1200px;
  margin: 0 auto;
}

.benefit-card {
  background: white;
  padding: 2rem;
  border-radius: var(--border-radius-large);
  box-shadow: var(--box-shadow-light);
  text-align: center;
  transition: var(--transition-normal);
}

.benefit-card:hover {
  transform: translateY(-4px);
  box-shadow: var(--box-shadow);
}

.benefit-icon {
  width: 60px;
  height: 60px;
  background: linear-gradient(
    135deg,
    var(--primary-color),
    var(--primary-variant)
  );
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 1.5rem;
}

.benefit-icon i {
  font-size: 1.5rem;
  color: var(--on-primary);
}

.benefit-card h3 {
  font-size: 1.5rem;
  font-weight: 600;
  color: var(--color-heading);
  margin-bottom: 1rem;
}

.benefit-card p {
  color: var(--color-text-secondary);
  line-height: 1.6;
}

/* Responsive Design */
@media (max-width: 1024px) {
  .hero-section {
    grid-template-columns: 1fr;
    gap: 3rem;
    padding: 3rem 1.5rem;
    text-align: center;
  }

  .feature-highlights {
    justify-content: center;
    flex-wrap: wrap;
  }

  .floating-stats {
    position: static;
    justify-content: center;
    margin-top: 2rem;
  }
}

@media (max-width: 768px) {
  .hero-section {
    padding: 2rem 1rem;
  }

  .cta-buttons {
    flex-direction: column;
    align-items: center;
  }

  .cta-primary,
  .cta-secondary {
    width: 100%;
    max-width: 300px;
  }

  .feature-highlights {
    flex-direction: column;
    align-items: center;
  }

  .benefits-grid {
    grid-template-columns: 1fr;
    gap: 1.5rem;
  }
}

/* Dark Mode Support */
@media (prefers-color-scheme: dark) {
  .benefit-card {
    background: var(--background);
    color: var(--color-text);
  }

  .stat-item {
    background: var(--background);
    color: var(--color-text);
  }
}
</style>
