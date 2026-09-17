import { createApp } from "vue"
import CalendarMonthView from "../components/CalendarMonthView.vue"
import "../styles/calendar.css"

const appElement = document.getElementById("app")

if (appElement) {
  createApp(CalendarMonthView).mount(appElement)
}
