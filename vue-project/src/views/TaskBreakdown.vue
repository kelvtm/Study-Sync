<template>
  <div class="task-breakdown-container">
    <!-- Header -->
    <div class="page-header">
      <h1>Task Breakdown</h1>
      <button @click="showCreateModal = true" class="btn-secondary">
        + Add Course
      </button>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="loading-state">
      <div class="spinner"></div>
      <p>Loading your courses...</p>
    </div>

    <!-- Error State -->
    <div v-if="error && !loading" class="error-state">
      <div class="error-icon">⚠️</div>
      <p>{{ error }}</p>
      <button @click="fetchCourses" class="btn-secondary">Try Again</button>
    </div>

    <!-- Empty State -->
    <div v-if="!loading && !error && courses.length === 0" class="empty-state">
      <div class="empty-icon">📚</div>
      <h3>No courses yet</h3>
      <p>Create your first course to start breaking down your tasks!</p>
      <button @click="showCreateModal = true" class="btn-secondary">
        Create Course
      </button>
    </div>

    <!-- Courses List -->
    <div v-if="!loading && !error && courses.length > 0" class="courses-grid">
      <div v-for="course in courses" :key="course._id" class="course-card">
        <div class="course-header">
          <h2>{{ course.courseName }}</h2>
          <div class="course-actions">
            <span class="submission-date">
              Due: {{ formatDate(course.submissionDate) }}
            </span>
            <button
              @click="deleteCourse(course._id, course.courseName)"
              class="delete-btn"
              title="Delete Course"
            >
              🗑️
            </button>
          </div>
        </div>

        <div class="overall-timer">
          <div
            class="timer-display"
            :class="getTimerClass(course.submissionDate)"
          >
            {{ calculateTimeRemaining(course.submissionDate) }}
          </div>
        </div>

        <!-- Stages -->
        <div class="stages-container">
          <div
            v-for="stage in course.stages"
            :key="stage._id"
            class="stage-card"
          >
            <div class="stage-header">
              <h3>{{ stage.title }}</h3>
              <div class="stage-timer" :class="getTimerClass(stage.endDate)">
                {{ calculateTimeRemaining(stage.endDate) }}
              </div>
            </div>

            <!-- Subtasks -->
            <div class="subtasks-container">
              <div
                v-for="subtask in stage.subtasks"
                :key="subtask._id"
                class="subtask-item"
              >
                <label class="subtask-checkbox">
                  <input
                    type="checkbox"
                    :checked="subtask.isCompleted"
                    @change="toggleSubtask(subtask._id, !subtask.isCompleted)"
                  />
                  <span class="checkmark"></span>
                  <span
                    :class="[
                      'subtask-text',
                      { completed: subtask.isCompleted },
                    ]"
                  >
                    {{ subtask.title }}
                  </span>
                </label>
              </div>

              <!-- Add Subtask -->
              <div class="add-subtask">
                <div v-if="!stage.showAddInput" class="add-subtask-btn">
                  <button
                    @click="stage.showAddInput = true"
                    class="btn-add-subtask"
                  >
                    + Add subtask
                  </button>
                </div>
                <div v-else class="add-subtask-form">
                  <input
                    ref="subtaskInput"
                    v-model="stage.newSubtaskTitle"
                    @keyup.enter="addSubtask(stage)"
                    @keyup.escape="cancelAddSubtask(stage)"
                    placeholder="Enter subtask title..."
                    class="input-field"
                    maxlength="200"
                  />
                  <div class="subtask-form-actions">
                    <button
                      @click="addSubtask(stage)"
                      :disabled="!stage.newSubtaskTitle?.trim()"
                      class="btn-save"
                    >
                      ✓
                    </button>
                    <button @click="cancelAddSubtask(stage)" class="btn-cancel">
                      ✕
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Create Course Modal -->
    <div
      v-if="showCreateModal"
      class="modal-overlay"
      @click.self="closeCreateModal"
    >
      <div class="modal-content">
        <div class="modal-header">
          <h2>Create New Course</h2>
          <button @click="closeCreateModal" class="modal-close">✕</button>
        </div>

        <form @submit.prevent="createCourse" class="create-course-form">
          <div class="form-group">
            <label for="courseName">Course Name</label>
            <input
              id="courseName"
              v-model="createForm.courseName"
              type="text"
              placeholder="Enter course name..."
              class="input-field"
              :class="{ error: createErrors.courseName }"
              maxlength="100"
              required
            />
            <span v-if="createErrors.courseName" class="error-message">
              {{ createErrors.courseName }}
            </span>
          </div>

          <div class="form-group">
            <label for="submissionDate">Submission Date</label>
            <input
              id="submissionDate"
              v-model="createForm.submissionDate"
              type="date"
              :min="minDate"
              class="input-field"
              :class="{ error: createErrors.submissionDate }"
              required
            />
            <span v-if="createErrors.submissionDate" class="error-message">
              {{ createErrors.submissionDate }}
            </span>
            <div class="date-help">Format: DD/MM/YYYY</div>
          </div>

          <div class="modal-actions">
            <button type="button" @click="closeCreateModal" class="btn-cancel">
              Cancel
            </button>
            <button
              type="submit"
              :disabled="creating || !isCreateFormValid"
              class="btn-secondary"
            >
              {{ creating ? "Creating..." : "Create Course" }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <div
      v-if="showDeleteModal"
      class="modal-overlay"
      @click.self="cancelDelete"
    >
      <div class="modal-content small">
        <div class="modal-header">
          <h3>Delete Course</h3>
        </div>
        <p>
          Are you sure you want to delete
          <strong>"{{ deleteCourseName }}"</strong>?
        </p>
        <p class="warning-text">
          This will permanently delete all stages and subtasks.
        </p>
        <div class="modal-actions">
          <button @click="cancelDelete" class="btn-cancel">Cancel</button>
          <button
            @click="confirmDelete"
            :disabled="deleting"
            class="btn-danger"
          >
            {{ deleting ? "Deleting..." : "Delete" }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, nextTick } from "vue";
import axios from "axios";
import { API_BASE_URL } from "@/config";

// Reactive data
const courses = ref([]);
const loading = ref(true);
const error = ref("");
const showCreateModal = ref(false);
const creating = ref(false);
const showDeleteModal = ref(false);
const deleting = ref(false);
const deleteCourseId = ref("");
const deleteCourseName = ref("");

// Get user ID from localStorage
const userId = localStorage.getItem("userId");

// Create form data
const createForm = ref({
  courseName: "",
  submissionDate: "",
});

const createErrors = ref({
  courseName: "",
  submissionDate: "",
});

// Computed properties
const minDate = computed(() => {
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  return tomorrow.toISOString().split("T")[0];
});

const isCreateFormValid = computed(() => {
  return (
    createForm.value.courseName.trim() !== "" &&
    createForm.value.submissionDate !== "" &&
    Object.values(createErrors.value).every((error) => error === "")
  );
});

// Methods
const fetchCourses = async () => {
  if (!userId) {
    error.value = "Please log in to view your courses";
    loading.value = false;
    return;
  }

  loading.value = true;
  error.value = "";

  try {
    console.log("Fetching courses for user:", userId);
    const response = await axios.get(
      `${API_BASE_URL}/api/courses?userId=${userId}`
    );

    courses.value = response.data.courses.map((course) => ({
      ...course,
      stages: course.stages.map((stage) => ({
        ...stage,
        showAddInput: false,
        newSubtaskTitle: "",
      })),
    }));

    console.log("Courses fetched:", courses.value.length);
  } catch (err) {
    console.error("Error fetching courses:", err);
    error.value = err.response?.data?.error || "Failed to load courses";
  } finally {
    loading.value = false;
  }
};

const createCourse = async () => {
  // Clear previous errors
  createErrors.value = { courseName: "", submissionDate: "" };

  // Validate form
  if (!validateCreateForm()) {
    return;
  }

  creating.value = true;

  try {
    console.log("Creating course:", createForm.value);

    const response = await axios.post(`${API_BASE_URL}/api/courses`, {
      userId,
      courseName: createForm.value.courseName.trim(),
      submissionDate: createForm.value.submissionDate,
    });

    console.log("Course created:", response.data);

    // Refresh courses list
    await fetchCourses();

    // Close modal and reset form
    closeCreateModal();
  } catch (err) {
    console.error("Error creating course:", err);

    if (err.response?.status === 400) {
      const message = err.response.data?.error || "";
      if (message.includes("future")) {
        createErrors.value.submissionDate =
          "Submission date must be in the future";
      } else {
        createErrors.value.courseName = message;
      }
    } else {
      createErrors.value.courseName =
        "Failed to create course. Please try again.";
    }
  } finally {
    creating.value = false;
  }
};

const validateCreateForm = () => {
  let isValid = true;

  // Course name validation
  if (!createForm.value.courseName.trim()) {
    createErrors.value.courseName = "Course name is required";
    isValid = false;
  } else if (createForm.value.courseName.trim().length < 3) {
    createErrors.value.courseName = "Course name must be at least 3 characters";
    isValid = false;
  }

  // Date validation
  if (!createForm.value.submissionDate) {
    createErrors.value.submissionDate = "Submission date is required";
    isValid = false;
  } else {
    const selectedDate = new Date(createForm.value.submissionDate);
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    if (selectedDate <= today) {
      createErrors.value.submissionDate =
        "Submission date must be in the future";
      isValid = false;
    }
  }

  return isValid;
};

const deleteCourse = (courseId, courseName) => {
  deleteCourseId.value = courseId;
  deleteCourseName.value = courseName;
  showDeleteModal.value = true;
};

const confirmDelete = async () => {
  deleting.value = true;

  try {
    await axios.delete(
      `${API_BASE_URL}/api/courses/${deleteCourseId.value}?userId=${userId}`
    );

    console.log("Course deleted successfully");

    // Refresh courses list
    await fetchCourses();

    // Close modal
    cancelDelete();
  } catch (err) {
    console.error("Error deleting course:", err);
    error.value = "Failed to delete course. Please try again.";
  } finally {
    deleting.value = false;
  }
};

const cancelDelete = () => {
  showDeleteModal.value = false;
  deleteCourseId.value = "";
  deleteCourseName.value = "";
  deleting.value = false;
};

const addSubtask = async (stage) => {
  const title = stage.newSubtaskTitle?.trim();
  if (!title) return;

  try {
    console.log("Creating subtask:", title);

    const response = await axios.post(`${API_BASE_URL}/api/subtasks`, {
      stageId: stage._id,
      title,
      userId,
    });

    // Add the new subtask to local state
    stage.subtasks.push(response.data.subtask);
    stage.newSubtaskTitle = "";
    stage.showAddInput = false;

    console.log("Subtask created successfully:", response.data.subtask);
  } catch (err) {
    console.error("Error creating subtask:", err);

    // Show error feedback to user
    if (err.response?.status === 400) {
      alert(err.response.data.error);
    } else {
      alert("Failed to create subtask. Please try again.");
    }
  }
};

// const deleteSubtask = async (subtaskId, subtaskTitle, stage) => {
//   if (!confirm(`Are you sure you want to delete "${subtaskTitle}"?`)) {
//     return;
//   }

//   try {
//     console.log("Deleting subtask:", subtaskId);

//     await axios.delete(
//       `http://localhost:3000/api/subtasks/${subtaskId}?userId=${userId}`
//     );

//     // Remove from local state
//     const subtaskIndex = stage.subtasks.findIndex((s) => s._id === subtaskId);
//     if (subtaskIndex > -1) {
//       stage.subtasks.splice(subtaskIndex, 1);
//     }

//     console.log("Subtask deleted successfully");
//   } catch (err) {
//     console.error("Error deleting subtask:", err);

//     if (err.response?.status === 404) {
//       alert("Subtask not found. It may have been already deleted.");
//       // Remove from local state anyway
//       const subtaskIndex = stage.subtasks.findIndex((s) => s._id === subtaskId);
//       if (subtaskIndex > -1) {
//         stage.subtasks.splice(subtaskIndex, 1);
//       }
//     } else {
//       alert("Failed to delete subtask. Please try again.");
//     }
//   }
// };

const toggleSubtask = async (subtaskId, isCompleted) => {
  try {
    console.log("Toggling subtask:", subtaskId, isCompleted);

    const response = await axios.put(
      `${API_BASE_URL}/api/subtasks/${subtaskId}`,
      {
        userId,
        isCompleted,
      }
    );

    // Update local state
    courses.value.forEach((course) => {
      course.stages.forEach((stage) => {
        const subtask = stage.subtasks.find((s) => s._id === subtaskId);
        if (subtask) {
          subtask.isCompleted = isCompleted;
          subtask.completedAt = isCompleted ? new Date().toISOString() : null;
        }
      });
    });

    console.log("Subtask toggled successfully:", response.data.subtask);
  } catch (err) {
    console.error("Error toggling subtask:", err);

    // Revert the change on error and show feedback
    courses.value.forEach((course) => {
      course.stages.forEach((stage) => {
        const subtask = stage.subtasks.find((s) => s._id === subtaskId);
        if (subtask) {
          subtask.isCompleted = !isCompleted; // Revert
        }
      });
    });

    alert("Failed to update subtask. Please try again.");
  }
};

const calculateTimeRemaining = (endDate) => {
  const now = new Date();
  const end = new Date(endDate);
  const diffMs = end.getTime() - now.getTime();

  if (diffMs <= 0) {
    return "Time is up for this task";
  }

  const days = Math.floor(diffMs / (1000 * 60 * 60 * 24));
  const hours = Math.floor((diffMs % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));

  if (days > 0) {
    return `${days} days, ${hours} hours remaining`;
  } else {
    return `${hours} hours remaining`;
  }
};

const getTimerClass = (endDate) => {
  const now = new Date();
  const end = new Date(endDate);
  const diffMs = end.getTime() - now.getTime();
  const totalMs = diffMs;
  const days = diffMs / (1000 * 60 * 60 * 24);

  if (diffMs <= 0) return "expired";
  if (days < 1) return "critical"; // Less than 1 day
  if (days < 3) return "warning"; // Less than 3 days
  return "normal";
};

const formatDate = (dateString) => {
  const date = new Date(dateString);
  return date.toLocaleDateString("en-GB"); // DD/MM/YYYY format
};

const closeCreateModal = () => {
  showCreateModal.value = false;
  createForm.value = { courseName: "", submissionDate: "" };
  createErrors.value = { courseName: "", submissionDate: "" };
  creating.value = false;
};

// Lifecycle
onMounted(() => {
  console.log("TaskBreakdown component mounted, userId:", userId);
  fetchCourses();
});
</script>

<style scoped>
.task-breakdown-container {
  max-width: 1400px;
  margin: 0 auto;
  padding: 20px;
  color: var(--color-text);
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30px;
  padding-bottom: 20px;
  border-bottom: 2px solid var(--color-border);
}

.page-header h1 {
  color: var(--color-heading);
  font-size: 2.5rem;
  margin: 0;
}

/* States */
.loading-state,
.error-state,
.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: var(--color-text-secondary);
}

.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid var(--color-border);
  border-top: 4px solid var(--secondary-color);
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 20px;
}

@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}

.error-icon,
.empty-icon {
  font-size: 4rem;
  margin-bottom: 20px;
}

/* Courses Grid */
.courses-grid {
  display: grid;
  gap: 30px;
}

.course-card {
  background: var(--background-secondary);
  border-radius: var(--border-radius-large);
  padding: 25px;
  box-shadow: var(--box-shadow-light);
  border: 1px solid var(--color-border);
  transition: var(--transition-normal);
}

.course-card:hover {
  box-shadow: var(--box-shadow);
  transform: translateY(-2px);
}

.course-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 20px;
  gap: 15px;
}

.course-header h2 {
  color: var(--color-heading);
  margin: 0;
  font-size: 1.5rem;
  flex: 1;
}

.course-actions {
  display: flex;
  align-items: center;
  gap: 15px;
  flex-shrink: 0;
}

.submission-date {
  color: var(--color-text-secondary);
  font-size: 0.9rem;
  font-weight: 600;
}

.delete-btn {
  background: none;
  border: none;
  cursor: pointer;
  font-size: 1.2rem;
  padding: 5px;
  border-radius: 4px;
  transition: var(--transition-fast);
}

.delete-btn:hover {
  background: var(--color-error);
  transform: scale(1.1);
}

.overall-timer {
  margin-bottom: 25px;
  text-align: center;
}

.timer-display {
  font-size: 1.3rem;
  font-weight: bold;
  padding: 12px 20px;
  border-radius: var(--border-radius);
  transition: var(--transition-fast);
}

.timer-display.normal {
  background: var(--color-success);
  color: white;
}

.timer-display.warning {
  background: var(--color-warning);
  color: #333;
}

.timer-display.critical {
  background: var(--color-error);
  color: white;
}

.timer-display.expired {
  background: #6c757d;
  color: white;
}

/* Stages */
.stages-container {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
}

.stage-card {
  background: var(--background);
  border: 1px solid var(--color-border);
  border-radius: var(--border-radius);
  padding: 20px;
  transition: var(--transition-fast);
}

.stage-card:hover {
  border-color: var(--secondary-color);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.stage-header {
  margin-bottom: 15px;
}

.stage-header h3 {
  color: var(--color-heading);
  margin: 0 0 10px 0;
  font-size: 1.1rem;
}

.stage-timer {
  font-size: 0.9rem;
  font-weight: 600;
  padding: 6px 12px;
  border-radius: 15px;
  display: inline-block;
}

.stage-timer.normal {
  background: var(--color-success);
  color: white;
}
.stage-timer.warning {
  background: var(--color-warning);
  color: #333;
}
.stage-timer.critical {
  background: var(--color-error);
  color: white;
}
.stage-timer.expired {
  background: #6c757d;
  color: white;
}

/* Subtasks */
.subtasks-container {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.subtask-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 2px 0;
  transition: var(--transition-fast);
}

.subtask-item:hover {
  background: rgba(0, 0, 0, 0.02);
  border-radius: 4px;
  padding: 4px 8px;
}

.subtask-item:hover .delete-subtask-btn {
  opacity: 1;
}

@media (prefers-color-scheme: dark) {
  .subtask-item:hover {
    background: rgba(255, 255, 255, 0.05);
  }
}

.subtask-checkbox {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  flex: 1;
}

.subtask-checkbox input[type="checkbox"] {
  display: none;
}

.checkmark {
  width: 18px;
  height: 18px;
  border: 2px solid var(--color-border);
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: var(--transition-fast);
  flex-shrink: 0;
}

.subtask-checkbox input[type="checkbox"]:checked + .checkmark {
  background: var(--secondary-color);
  border-color: var(--secondary-color);
}

.subtask-checkbox input[type="checkbox"]:checked + .checkmark::after {
  content: "✓";
  color: white;
  font-size: 12px;
  font-weight: bold;
}

.subtask-text {
  color: var(--color-text);
  flex: 1;
  transition: var(--transition-fast);
}

.subtask-text.completed {
  text-decoration: line-through;
  color: var(--color-text-secondary);
}
/* 
.delete-subtask-btn {
  background: none;
  border: none;
  color: var(--color-text-secondary);
  cursor: pointer;
  padding: 2px 6px;
  border-radius: 3px;
  font-size: 0.9rem;
  opacity: 0;
  transition: var(--transition-fast);
  flex-shrink: 0;
}

.delete-subtask-btn:hover {
  background: var(--color-error);
  color: white;
  opacity: 1 !important;
} */

.add-subtask {
  margin-top: 10px;
}

.btn-add-subtask {
  background: none;
  border: 1px dashed var(--color-border);
  color: var(--color-text-secondary);
  padding: 8px 12px;
  border-radius: var(--border-radius);
  cursor: pointer;
  width: 100%;
  transition: var(--transition-fast);
}

.btn-add-subtask:hover {
  border-color: var(--secondary-color);
  color: var(--secondary-color);
}

.add-subtask-form {
  display: flex;
  gap: 8px;
  align-items: center;
}

.add-subtask-form .input-field {
  flex: 1;
  padding: 8px 12px;
  font-size: 0.9rem;
}

.subtask-form-actions {
  display: flex;
  gap: 5px;
}

.btn-save,
.btn-cancel {
  width: 30px;
  height: 30px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.9rem;
  transition: var(--transition-fast);
}

.btn-save {
  background: var(--color-success);
  color: white;
}

.btn-save:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-cancel {
  background: var(--color-error);
  color: white;
}

/* Buttons */
.btn-secondary {
  background: var(--secondary-color);
  color: white;
  border: none;
  padding: 12px 24px;
  border-radius: var(--border-radius);
  font-weight: 600;
  cursor: pointer;
  transition: var(--transition-normal);
}

.btn-secondary:hover:not(:disabled) {
  background: var(--secondary-hover);
  transform: translateY(-1px);
}

.btn-secondary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}

.btn-danger {
  background: var(--color-error);
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: var(--border-radius);
  font-weight: 600;
  cursor: pointer;
  transition: var(--transition-fast);
}

.btn-danger:hover:not(:disabled) {
  background: #c82333;
}

.btn-danger:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* Modal */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: var(--background-secondary);
  border-radius: var(--border-radius-large);
  box-shadow: var(--box-shadow);
  max-width: 500px;
  width: 90%;
  max-height: 90vh;
  overflow-y: auto;
}

.modal-content.small {
  max-width: 400px;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 25px;
  border-bottom: 1px solid var(--color-border);
}

.modal-header h2,
.modal-header h3 {
  color: var(--color-heading);
  margin: 0;
}

.modal-close {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  padding: 5px;
  color: var(--color-text-secondary);
  transition: var(--transition-fast);
}

.modal-close:hover {
  color: var(--color-error);
}

.create-course-form {
  padding: 25px;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  font-weight: 600;
  color: var(--color-heading);
}

.input-field {
  width: 100%;
  padding: 12px 16px;
  border: 2px solid var(--color-border);
  border-radius: var(--border-radius);
  font-size: 1rem;
  transition: var(--transition-fast);
  background: var(--background);
  color: var(--color-text);
}

.input-field:focus {
  outline: none;
  border-color: var(--secondary-color);
  box-shadow: 0 0 0 3px rgba(52, 220, 59, 0.1);
}

.input-field.error {
  border-color: var(--color-error);
  background: rgba(220, 53, 69, 0.05);
}

.error-message {
  color: var(--color-error);
  font-size: 0.8rem;
  font-weight: 500;
  margin-top: 5px;
  display: block;
}

.date-help {
  font-size: 0.8rem;
  color: var(--color-text-secondary);
  margin-top: 5px;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 15px;
  margin-top: 25px;
}

.warning-text {
  color: var(--color-error);
  font-size: 0.9rem;
  margin: 10px 0;
}

/* Responsive */
@media (max-width: 768px) {
  .course-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 10px;
  }

  .course-actions {
    align-self: stretch;
    justify-content: space-between;
  }

  .stages-container {
    grid-template-columns: 1fr;
  }

  .page-header {
    flex-direction: column;
    gap: 15px;
    align-items: stretch;
  }
}
</style>
