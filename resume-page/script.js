// Fill in job durations (e.g. "1 yr 9 mos") from each date's data-start/data-end.
// The count is inclusive of both months, like LinkedIn.
function formatDuration(start, end) {
  const [sy, sm] = start.split("-").map(Number);
  const [ey, em] = end.split("-").map(Number);
  const total = (ey - sy) * 12 + (em - sm) + 1;
  const years = Math.floor(total / 12);
  const months = total % 12;
  const parts = [];
  if (years) parts.push(`${years} yr${years > 1 ? "s" : ""}`);
  if (months) parts.push(`${months} mo${months > 1 ? "s" : ""}`);
  return parts.join(" ");
}

document.querySelectorAll(".job").forEach((job) => {
  const date = job.querySelector(".date[data-start][data-end]");
  const slot = job.querySelector(".duration");
  if (date && slot) {
    slot.textContent = formatDuration(date.dataset.start, date.dataset.end);
  }
});

// Cycle a highlight through "Build / Learn / Ship / Repeat".
const words = document.querySelectorAll("#motto span:not(.dash)");
const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
if (words.length && !reduceMotion) {
  let i = 0;
  setInterval(() => {
    words.forEach((w, n) => w.classList.toggle("is-active", n === i));
    i = (i + 1) % words.length;
  }, 1200);
}
