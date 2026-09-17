<script setup>
import { ref, watch } from "vue"

const props = defineProps({
  calendarId: { type: [String, Number], required: true },
  date: { type: String, required: true },
  note: { type: Object, default: null },
})

const body = ref("")
const savedBody = ref("")
const saving = ref(false)
const error = ref("")

watch(
  () => [props.date, props.note?.body],
  () => {
    body.value = props.note?.body || ""
    savedBody.value = body.value
    error.value = ""
  },
  { immediate: true },
)

async function saveNote() {
  saving.value = true
  error.value = ""

  try {
    const response = await fetch(`/api/calendars/${props.calendarId}/notes/${props.date}`, {
      method: "PUT",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ note: { body: body.value } }),
    })

    if (response.status === 204) {
      savedBody.value = ""
      emit("cleared", props.date)
    } else if (!response.ok) {
      throw new Error(await errorMessage(response))
    } else {
      const note = (await response.json()).note
      savedBody.value = note.body
      body.value = note.body
      emit("saved", note)
    }
  } catch (saveError) {
    error.value = saveError.message || "Unable to save note"
  } finally {
    saving.value = false
  }
}

async function errorMessage(response) {
  if (response.status === 401) return "You must be signed in to save notes."
  if (response.status === 403 || response.status === 404) return "You do not have access to this calendar."

  try {
    const payload = await response.json()
    return payload.error || "Unable to save note"
  } catch {
    return "Unable to save note"
  }
}

const emit = defineEmits(["saved", "cleared"])
</script>

<template>
  <section class="note-editor" aria-labelledby="note-editor-title">
    <div class="note-editor-header">
      <div>
        <p class="eyebrow">Daily note</p>
        <h2 id="note-editor-title">{{ date }}</h2>
      </div>
      <span v-if="body !== savedBody && !saving" class="save-state">Unsaved changes</span>
      <span v-else-if="saving" class="save-state">Saving...</span>
      <span v-else class="save-state saved">Saved</span>
    </div>

    <textarea
      v-model="body"
      :disabled="saving"
      rows="6"
      placeholder="Write something for this day..."
      aria-label="Daily note"
    ></textarea>
    <p v-if="error" class="notice error">{{ error }}</p>
    <button type="button" class="save-note" :disabled="saving || body === savedBody" @click="saveNote">
      {{ body.trim() ? "Save note" : "Clear note" }}
    </button>
  </section>
</template>