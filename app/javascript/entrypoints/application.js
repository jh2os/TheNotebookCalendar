import { createApp, ref } from "vue"

const appElement = document.getElementById("app")

if (appElement) {
  createApp({
    setup() {
      const status = ref("Checking Rails...")

      fetch("/up")
        .then((response) => {
          if (!response.ok) throw new Error("Health check failed")
          status.value = "Rails is connected"
        })
        .catch(() => {
          status.value = "Rails is unavailable"
        })

      return { status }
    },
    template: `
      <section>
        <h1>The Notebook Calendar</h1>
        <p>{{ status }}</p>
      </section>
    `,
  }).mount(appElement)
}
