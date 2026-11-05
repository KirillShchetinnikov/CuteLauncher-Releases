const gallery = document.querySelector("[data-gallery]");
const styles = [...gallery.querySelectorAll("[data-style]")];
const controls = gallery.querySelector(".gallery-controls");
const enlarge = gallery.querySelector("[data-enlarge]");
const preview = enlarge.querySelector("img");
const title = gallery.querySelector("[data-style-title]");
const detail = gallery.querySelector("[data-style-detail]");
const position = gallery.querySelector("[data-position]");
const lightbox = document.querySelector("[data-lightbox]");
const lightboxImage = lightbox.querySelector("img");
let active = 0;

function selectStyle(index) {
  styles[active].removeAttribute("aria-current");
  active = (index + styles.length) % styles.length;
  const style = styles[active];

  style.setAttribute("aria-current", "true");
  preview.alt = style.dataset.alt;
  preview.src = style.href;
  enlarge.href = style.href;
  title.textContent = style.querySelector("strong").textContent;
  detail.textContent = style.querySelector("small").textContent;
  position.textContent = String(active + 1).padStart(2, "0");
}

function plainClick(event) {
  return !(event.metaKey || event.ctrlKey || event.shiftKey || event.altKey);
}

styles.forEach((style, index) => {
  style.addEventListener("click", (event) => {
    if (!plainClick(event)) return;
    event.preventDefault();
    selectStyle(index);
  });
});

controls.querySelectorAll("[data-step]").forEach((button) => {
  button.addEventListener("click", () => selectStyle(active + Number(button.dataset.step)));
});
controls.hidden = false;

if (typeof lightbox.showModal === "function") {
  enlarge.addEventListener("click", (event) => {
    if (!plainClick(event)) return;
    event.preventDefault();
    lightboxImage.src = enlarge.href;
    lightboxImage.alt = preview.alt;
    lightbox.showModal();
  });

  lightbox.querySelector("[data-close]").addEventListener("click", () => lightbox.close());
  lightbox.addEventListener("click", (event) => {
    if (event.target === lightbox) lightbox.close();
  });
}
