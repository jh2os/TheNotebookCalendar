<script setup>
import { computed, onMounted, ref, watch } from "vue"
import DayNoteEditor from "./DayNoteEditor.vue"

const calendars = ref([])
const selectedCalendarId = ref("")
const displayedMonth = ref(monthStart(new Date()))
const selectedDate = ref(isoDate(new Date()))
const notes = ref({})
const loading = ref(false)
const error = ref("")

const monthLabel = computed(() => displayedMonth.value.toLocaleDateString(undefined, {
  month: "long",
  year: "numeric",
}))

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

const selectedCalendar = computed(() => calendars.value.find((calendar) => String(calendar.id) === String(selectedCalendarId.value)))

onMounted(loadCalendars)
watch([selectedCalendarId, displayedMonth], loadNotes)

async function loadCalendars() {
  try {
    const response = await fetch("/api/calendars", { headers: { Accept: "application/json" } })
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
    const rangeStart = days.value[0].date
    const rangeEnd = days.value[days.value.length - 1].date
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

function goToCurrentMonth() {
  displayedMonth.value = monthStart(new Date())
}

function monthStart(date) {
  return new Date(date.getFullYear(), date.getMonth(), 1)
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
</script>

<template>
  <main class="calendar-app">
    <header class="calendar-header">
      <div>
        <p class="eyebrow">The Notebook Calendar</p>
        <h1>{{ monthLabel }}</h1>
      </div>
      <label v-if="calendars.length" class="calendar-selector">
        Calendar
        <select v-model="selectedCalendarId">
          <option v-for="calendar in calendars" :key="calendar.id" :value="String(calendar.id)">
            {{ calendar.name }}
          </option>
        </select>
      </label>
    </header>

    <p v-if="error" class="notice error">{{ error }}</p>
    <p v-else-if="!calendars.length" class="notice">No calendars are available.</p>

    <section v-else class="calendar-panel" aria-label="Monthly calendar">
      <nav class="calendar-toolbar" aria-label="Month navigation">
        <button type="button" @click="moveMonth(-1)">Previous month</button>
        <button type="button" @click="goToCurrentMonth">Today</button>
        <button type="button" @click="moveMonth(1)">Next month</button>
        <span v-if="loading" class="loading-status">Loading notes...</span>
      </nav>

      <div class="weekday-row" aria-hidden="true">
        <span v-for="weekday in ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']" :key="weekday">{{ weekday }}</span>
      </div>
      <div class="month-grid">
        <button
          v-for="day in days"
          :key="day.date"
          type="button"
          class="calendar-day"
          :class="{ 'outside-month': !day.inMonth, today: day.date === isoDate(new Date()), selected: day.date === selectedDate }"
          :aria-label="`${day.date}${notes[day.date] ? ', has note' : ''}`"
          :aria-pressed="day.date === selectedDate"
          @click="selectedDate = day.date"
        >
          <span>{{ day.dayNumber }}</span>
          <span v-if="notes[day.date]" class="note-indicator" aria-label="Has note"></span>
        </button>
      </div>
      <p class="selected-date">Selected: <strong>{{ selectedDate }}</strong></p>
    </section>

    <DayNoteEditor
      v-if="selectedCalendarId"
      :calendar-id="selectedCalendarId"
      :date="selectedDate"
      :note="notes[selectedDate]"
      @saved="updateNote"
      @cleared="clearNote"
    />
  </main>
</template>