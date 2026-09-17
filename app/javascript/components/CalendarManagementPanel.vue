<script setup>
import { computed, ref, watch } from "vue"

const props = defineProps({
  calendars: { type: Array, required: true },
  selectedCalendarId: { type: [String, Number], default: "" },
  currentUser: { type: Object, required: true },
})

const emit = defineEmits(["changed", "select"])
const name = ref("")
const rename = ref("")
const memberEmail = ref("")
const members = ref([])
const loading = ref(false)
const error = ref("")
const message = ref("")

const selectedCalendar = computed(() => props.calendars.find((calendar) => String(calendar.id) === String(props.selectedCalendarId)))
const isOwner = computed(() => selectedCalendar.value?.created_by_id === props.currentUser.id)

watch(selectedCalendar, () => {
  rename.value = selectedCalendar.value?.name || ""
  if (isOwner.value) loadMembers()
  else members.value = []
}, { immediate: true })

async function createCalendar() {
  await request("/api/calendars", {
    method: "POST",
    body: JSON.stringify({ calendar: { name: name.value } }),
  }, "Calendar created")
  name.value = ""
}

async function renameCalendar() {
  if (!selectedCalendar.value) return
  await request(`/api/calendars/${selectedCalendar.value.id}`, {
    method: "PATCH",
    body: JSON.stringify({ calendar: { name: rename.value } }),
  }, "Calendar renamed")
}

async function deleteCalendar() {
  if (!selectedCalendar.value || !window.confirm(`Delete ${selectedCalendar.value.name}?`)) return

  await request(`/api/calendars/${selectedCalendar.value.id}`, { method: "DELETE" }, "Calendar deleted")
}

async function loadMembers() {
  if (!selectedCalendar.value) return
  try {
    const response = await fetch(`/api/calendars/${selectedCalendar.value.id}/members`, { headers: { Accept: "application/json" } })
    if (!response.ok) throw new Error("Unable to load members")
    members.value = (await response.json()).members
  } catch (loadError) {
    error.value = loadError.message
  }
}

async function addMember() {
  if (!selectedCalendar.value) return
  await request(`/api/calendars/${selectedCalendar.value.id}/members`, {
    method: "POST",
    body: JSON.stringify({ email: memberEmail.value }),
  }, "Member added")
  memberEmail.value = ""
  await loadMembers()
}

async function removeMember(userId) {
  if (!selectedCalendar.value) return
  await request(`/api/calendars/${selectedCalendar.value.id}/members/${userId}`, { method: "DELETE" }, "Member removed")
  await loadMembers()
}

async function request(url, options, successMessage) {
  loading.value = true
  error.value = ""
  message.value = ""
  try {
    const response = await fetch(url, {
      ...options,
      headers: { Accept: "application/json", "Content-Type": "application/json", ...(options.headers || {}) },
    })
    if (!response.ok) throw new Error(await responseError(response))
    message.value = successMessage
    emit("changed")
  } catch (requestError) {
    error.value = requestError.message || "The request failed"
  } finally {
    loading.value = false
  }
}

async function responseError(response) {
  if (response.status === 401) return "You must be signed in."
  if (response.status === 403) return "You do not have permission for this action."
  try {
    const payload = await response.json()
    return payload.error || Object.values(payload.errors || {}).flat().join(", ") || "The request failed"
  } catch {
    return "The request failed"
  }
}
</script>

<template>
  <section class="management-panel" aria-label="Calendar management">
    <div class="management-row create-calendar">
      <label>
        New calendar
        <input v-model="name" type="text" placeholder="Calendar name" @keyup.enter="createCalendar">
      </label>
      <button type="button" :disabled="loading || !name.trim()" @click="createCalendar">Create</button>
    </div>

    <template v-if="selectedCalendar">
      <div class="management-row">
        <label>
          Selected calendar
          <select :value="selectedCalendarId" @change="emit('select', $event.target.value)">
            <option v-for="calendar in calendars" :key="calendar.id" :value="String(calendar.id)">{{ calendar.name }}</option>
          </select>
        </label>
        <label v-if="isOwner">
          Rename
          <input v-model="rename" type="text" @keyup.enter="renameCalendar">
        </label>
        <button v-if="isOwner" type="button" :disabled="loading || !rename.trim()" @click="renameCalendar">Rename</button>
        <button v-if="isOwner" type="button" class="danger-action" :disabled="loading" @click="deleteCalendar">Delete</button>
      </div>

      <div v-if="isOwner" class="member-management">
        <div class="management-row">
          <label>
            Add member
            <input v-model="memberEmail" type="email" placeholder="person@example.com" @keyup.enter="addMember">
          </label>
          <button type="button" :disabled="loading || !memberEmail.trim()" @click="addMember">Add member</button>
        </div>
        <ul class="member-list">
          <li v-for="member in members" :key="member.user_id">
            <span>{{ member.email }} <small>{{ member.role }}</small></span>
            <button v-if="member.role !== 'owner'" type="button" class="danger-action" :disabled="loading" @click="removeMember(member.user_id)">Remove</button>
          </li>
        </ul>
      </div>
    </template>

    <p v-if="message" class="management-message">{{ message }}</p>
    <p v-if="error" class="notice error">{{ error }}</p>
  </section>
</template>