import markdownIt from "./assets/vendor/markdown-it-15.0.3.mjs";

const article = document.querySelector("[data-document]");
const github = "https://github.com/KirillShchetinnikov/CuteLauncher-Releases/blob/main/";
const raw = "https://raw.githubusercontent.com/KirillShchetinnikov/CuteLauncher-Releases/main/";
const markdown = markdownIt({ html: false });

function renderDocument(text, source, isFaq) {
  const template = document.createElement("template");
  template.innerHTML = markdown.render(text);
  const content = template.content;
  const title = content.firstElementChild;
  if (title?.tagName !== "H1" || !content.querySelector("h2")) return;
  title.remove();

  const navigation = content.firstElementChild;
  if (navigation?.tagName === "P" && navigation.querySelectorAll("a").length >= 3) {
    navigation.remove();
  }

  for (const link of content.querySelectorAll("a[href]")) {
    const href = link.getAttribute("href");
    if (!href.startsWith("#")) link.href = new URL(href, github + source).href;
  }
  for (const image of content.querySelectorAll("img[src]")) {
    image.src = new URL(image.getAttribute("src"), raw + source).href;
  }

  const sections = document.createDocumentFragment();
  let section;
  for (const node of [...content.children]) {
    if (node.tagName === "H2") {
      section = document.createElement(isFaq ? "details" : "section");
      section.className = isFaq ? "doc-question" : "doc-release";
      sections.append(section);
      if (isFaq) {
        const summary = document.createElement("summary");
        summary.append(...node.childNodes);
        section.append(summary);
        continue;
      }
    }
    (section ?? sections).append(node);
  }
  article.replaceChildren(sections);
}

async function loadDocument() {
  const source = article.dataset.document;
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 8000);
  article.setAttribute("aria-busy", "true");
  try {
    const response = await fetch(raw + source, { signal: controller.signal });
    if (response.ok) {
      renderDocument(await response.text(), source, article.dataset.kind === "faq");
    }
  } catch {
    // Keep the link to the source available when the document cannot be loaded.
  } finally {
    clearTimeout(timeout);
    article.removeAttribute("aria-busy");
  }
}

loadDocument();
