<script setup>
import { computed, onMounted, ref, watch } from "vue"
import DayNoteEditor from "./DayNoteEditor.vue"
import CalendarManagementPanel from "./CalendarManagementPanel.vue"
import { apiFetch } from "../services/api"

const calendars = ref([])
const selectedCalendarId = ref("")
const viewMode = ref("month")
const defaultViewMode = ref("month")
const displayedMonth = ref(monthStart(new Date()))
const displayedWeek = ref(weekStart(new Date()))
const selectedDate = ref(isoDate(new Date()))
const notes = ref({})
const loading = ref(false)
const error = ref("")
const theme = ref("light")
const currentUser = ref(null)
const authenticated = ref(false)
const authLoading = ref(true)
const authEmail = ref("")
const authMessage = ref("")
const managementOpen = ref(false)
const noteDrawerOpen = ref(false)

const periodLabel = computed(() => viewMode.value === "month"
  ? displayedMonth.value.toLocaleDateString(undefined, { month: "long", year: "numeric" })
  : `${displayedWeek.value.toLocaleDateString(undefined, { month: "short", day: "numeric" })} - ${addDays(displayedWeek.value, 6).toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" })}`)

const days = computed(() => {
  const firstDay = displayedMonth.value
  const gridStart = addDays(firstDay, -firstDay.getDay())
  const lastDay = new Date(firstDay.getFullYear(), firstDay.getMonth() + 1, 0)
  const gridEnd = addDays(lastDay, 6 - lastDay.getDay())
  const result = []

  for (let day = gridStart; day <= gridEnd; day = addDays(day, 1)) {
    result.push({
      date: isoDate(day),
      dayNumber: day.getDate(),
      inMonth: day.getMonth() === firstDay.getMonth(),
    })
  }

  return result
})

const visibleDays = computed(() => viewMode.value === "month" ? days.value : weekDays.value)

const weekDays = computed(() => Array.from({ length: 7 }, (_, index) => {
  const date = addDays(displayedWeek.value, index)
  return { date: isoDate(date), dayNumber: date.getDate(), inMonth: true }
}))

const selectedCalendar = computed(() => calendars.value.find((calendar) => String(calendar.id) === String(selectedCalendarId.value)))

onMounted(() => {
  initializeTheme()
  initializeViewMode()
  checkSession()
})
watch([selectedCalendarId, displayedMonth, displayedWeek, viewMode], loadNotes)

function initializeTheme() {
  const savedTheme = localStorage.getItem("notebook-calendar-theme")
  theme.value = savedTheme || (window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light")
  applyTheme()
}

function toggleTheme() {
  theme.value = theme.value === "light" ? "dark" : "light"
  localStorage.setItem("notebook-calendar-theme", theme.value)
  applyTheme()
}

function applyTheme() {
  document.documentElement.dataset.theme = theme.value
}

function initializeViewMode() {
  const savedViewMode = localStorage.getItem("notebook-calendar-view-mode")
  if (savedViewMode === "month" || savedViewMode === "week") {
    defaultViewMode.value = savedViewMode
    viewMode.value = savedViewMode
  }
}

async function checkSession() {
  try {
    const magicLinkToken = new URLSearchParams(window.location.search).get("magic_link")
    const response = magicLinkToken
      ? await apiFetch(`/api/auth/magic_links/${encodeURIComponent(magicLinkToken)}`)
      : await apiFetch("/api/auth/session")
    if (!response.ok) throw new Error("Not authenticated")
    if (magicLinkToken) {
      window.location.replace(window.location.pathname)
      return
    }
    currentUser.value = (await response.json()).user
    authenticated.value = true
    await loadCalendars()
    managementOpen.value = calendars.value.length === 0
  } catch (sessionError) {
    authenticated.value = false
    if (new URLSearchParams(window.location.search).has("magic_link")) {
      authMessage.value = sessionError.message || "This login link is invalid or expired."
      window.history.replaceState({}, "", window.location.pathname)
    }
  } finally {
    authLoading.value = false
  }
}

async function requestMagicLink() {
  authMessage.value = ""
  try {
    const response = await apiFetch("/api/auth/magic_links", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: authEmail.value }),
    })
    if (!response.ok) throw new Error("Unable to request a login link")
    authMessage.value = "If the email is valid, a login link has been sent."
  } catch (authError) {
    authMessage.value = authError.message
  }
}

async function logout() {
  await apiFetch("/api/auth/session", { method: "DELETE" })
  authenticated.value = false
  currentUser.value = null
  calendars.value = []
  selectedCalendarId.value = ""
}

async function loadCalendars() {
  try {
    const response = await apiFetch("/api/calendars")
    if (response.status === 401) {
      authenticated.value = false
      return
    }
    if (!response.ok) throw new Error("Unable to load calendars")

    calendars.value = (await response.json()).calendars
    if (calendars.value.length > 0 && !selectedCalendarId.value) {
      selectedCalendarId.value = String(calendars.value[0].id)
    }
  } catch (loadError) {
    error.value = loadError.message
  }
}

async function loadNotes() {
  if (!selectedCalendarId.value) {
    notes.value = {}
    return
  }

  loading.value = true
  error.value = ""

  try {
    const rangeStart = visibleDays.value[0].date
    const rangeEnd = visibleDays.value[visibleDays.value.length - 1].date
    const query = new URLSearchParams({ start_date: rangeStart, end_date: rangeEnd })
    const response = await fetch(`/api/calendars/${selectedCalendarId.value}/notes?${query}`)
    if (!response.ok) throw new Error("Unable to load notes")

    notes.value = Object.fromEntries((await response.json()).notes.map((note) => [note.date, note]))
  } catch (loadError) {
    error.value = loadError.message
  } finally {
    loading.value = false
  }
}

function moveMonth(offset) {
  displayedMonth.value = new Date(displayedMonth.value.getFullYear(), displayedMonth.value.getMonth() + offset, 1)
}

function moveWeek(offset) {
  displayedWeek.value = addDays(displayedWeek.value, offset * 7)
}

function goToCurrentMonth() {
  displayedMonth.value = monthStart(new Date())
}

function goToCurrentWeek() {
  displayedWeek.value = weekStart(new Date())
}

function selectView(mode) {
  viewMode.value = mode
  if (mode === "week") {
    displayedWeek.value = weekStart(parseDate(selectedDate.value))
  } else {
    displayedMonth.value = monthStart(parseDate(selectedDate.value))
  }
}

function setDefaultView(mode) {
  defaultViewMode.value = mode
  localStorage.setItem("notebook-calendar-view-mode", mode)
}

function monthStart(date) {
  return new Date(date.getFullYear(), date.getMonth(), 1)
}

function weekStart(date) {
  return addDays(new Date(date.getFullYear(), date.getMonth(), date.getDate()), -date.getDay())
}

function parseDate(value) {
  const [year, month, day] = value.split("-").map(Number)
  return new Date(year, month - 1, day)
}

function addDays(date, amount) {
  const result = new Date(date)
  result.setDate(result.getDate() + amount)
  return result
}

function isoDate(date) {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, "0")
  const day = String(date.getDate()).padStart(2, "0")
  return `${year}-${month}-${day}`
}

function updateNote(note) {
  notes.value = { ...notes.value, [note.date]: note }
}

function clearNote(date) {
  const updatedNotes = { ...notes.value }
  delete updatedNotes[date]
  notes.value = updatedNotes
}

function selectDate(date) {
  selectedDate.value = date
  noteDrawerOpen.value = true
}
</script>

<template>
  <main class="calendar-app">
    <header class="calendar-header">
      <div>
        <p class="eyebrow">The Notebook Calendar</p>
        <h1>{{ periodLabel }}</h1>
      </div>
      <div v-if="authenticated" class="calendar-header-actions">
        <label v-if="calendars.length" class="calendar-selector" aria-label="Select calendar">
          <span class="sr-only">Calendar</span>
          <select v-model="selectedCalendarId">
            <option v-for="calendar in calendars" :key="calendar.id" :value="String(calendar.id)">
              {{ calendar.name }}
            </option>
          </select>
        </label>
        <button
          type="button"
          class="manage-button"
          aria-controls="calendar-management-drawer"
          :aria-expanded="managementOpen"
          aria-label="Open settings"
          title="Open settings"
          @click="managementOpen = true"
        >
          <span aria-hidden="true" class="settings-icon">&#9881;</span>
        </button>
      </div>
    </header>

    <section v-if="authLoading" class="notice">Checking your session...</section>
    <section v-else-if="!authenticated" class="auth-panel">
      <p class="eyebrow">The Notebook Calendar</p>
      <h2>Sign in with a magic link</h2>
      <form @submit.prevent="requestMagicLink">
        <label>Email<input v-model="authEmail" type="email" required autocomplete="email" placeholder="you@example.com"></label>
        <button type="submit">Send login link</button>
      </form>
      <p v-if="authMessage" class="management-message">{{ authMessage }}</p>
    </section>

    <template v-else>
      <p v-if="error" class="notice error">{{ error }}</p>
      <div v-if="managementOpen" class="drawer-backdrop" @click="managementOpen = false"></div>
      <aside
        v-if="managementOpen"
        id="calendar-management-drawer"
        class="drawer management-drawer"
        aria-label="Settings"
      >
        <div class="drawer-heading">
          <div>
            <h2>Settings</h2>
          </div>
          <button type="button" class="drawer-close" aria-label="Close calendar management" @click="managementOpen = false">Close</button>
        </div>
        <CalendarManagementPanel
          :calendars="calendars"
          :selected-calendar-id="selectedCalendarId"
          :current-user="currentUser"
          :theme="theme"
          :view-mode="defaultViewMode"
          @changed="loadCalendars"
          @created="managementOpen = false"
          @logout="logout"
          @select-view="setDefaultView"
          @toggle-theme="toggleTheme"
        />
      </aside>
      <p v-if="!calendars.length" class="notice">Create a calendar to get started.</p>

    <section v-if="calendars.length" class="calendar-panel" :aria-label="`${viewMode} calendar`">
      <nav class="calendar-toolbar" :aria-label="`${viewMode} navigation`">
        <div class="view-switcher" aria-label="Calendar view">
          <button type="button" :class="{ active: viewMode === 'month' }" @click="selectView('month')">Month</button>
          <button type="button" :class="{ active: viewMode === 'week' }" @click="selectView('week')">Week</button>
        </div>
        <button
          v-if="viewMode === 'month'"
          type="button"
          class="calendar-nav-arrow"
          aria-label="Previous month"
          title="Previous month"
          @click="moveMonth(-1)"
        >&#8592;</button>
        <button v-else type="button" class="calendar-nav-arrow" aria-label="Previous week" title="Previous week" @click="moveWeek(-1)">&#8592;</button>
        <button v-if="viewMode === 'month'" type="button" @click="goToCurrentMonth">Today</button>
        <button v-else type="button" @click="goToCurrentWeek">Today</button>
        <button
          v-if="viewMode === 'month'"
          type="button"
          class="calendar-nav-arrow"
          aria-label="Next month"
          title="Next month"
          @click="moveMonth(1)"
        >&#8594;</button>
        <button v-else type="button" class="calendar-nav-arrow" aria-label="Next week" title="Next week" @click="moveWeek(1)">&#8594;</button>
        <span v-if="loading" class="loading-status">Loading notes...</span>
      </nav>

      <div class="weekday-row" aria-hidden="true">
        <span v-for="weekday in ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']" :key="weekday">{{ weekday }}</span>
      </div>
      <div class="month-grid" :class="{ 'week-grid': viewMode === 'week' }">
        <button
          v-for="day in visibleDays"
          :key="day.date"
          type="button"
          class="calendar-day"
          :class="{ 'outside-month': !day.inMonth, today: day.date === isoDate(new Date()), selected: day.date === selectedDate }"
          :aria-label="`${day.date}${notes[day.date] ? ', has note' : ''}`"
          :aria-pressed="day.date === selectedDate"
          @click="selectDate(day.date)"
        >
          <span>{{ day.dayNumber }}</span>
          <span v-if="notes[day.date]" class="note-preview" :title="notes[day.date].body">{{ notes[day.date].body }}</span>
        </button>
      </div>
      <p class="selected-date">Selected: <strong>{{ selectedDate }}</strong></p>
    </section>

    <div v-if="noteDrawerOpen && selectedCalendarId && calendars.length" class="drawer-backdrop" @click="noteDrawerOpen = false"></div>
    <aside v-if="noteDrawerOpen && selectedCalendarId && calendars.length" class="drawer note-drawer" aria-label="Daily note editor">
      <div class="drawer-heading">
        <div>
          <p class="eyebrow">Focused day</p>
          <h2>{{ selectedDate }}</h2>
        </div>
        <button type="button" class="drawer-close" aria-label="Close daily note" @click="noteDrawerOpen = false">Close</button>
      </div>
      <DayNoteEditor
        :calendar-id="selectedCalendarId"
        :date="selectedDate"
        :note="notes[selectedDate]"
        @saved="updateNote"
        @cleared="clearNote"
      />
    </aside>
    </template>
  </main>
</template>