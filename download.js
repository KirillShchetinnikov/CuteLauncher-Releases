const latestReleaseApi = "https://api.github.com/repos/KirillShchetinnikov/CuteLauncher-Releases/releases/latest";
const releaseAssetPrefix = "https://github.com/KirillShchetinnikov/CuteLauncher-Releases/releases/download/";
let downloadPending = false;

async function downloadUniversalApk(event) {
  if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
  event.preventDefault();
  if (downloadPending) return;

  const link = event.currentTarget;
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 5000);
  let destination = link.href;
  downloadPending = true;
  link.setAttribute("aria-busy", "true");

  try {
    const response = await fetch(latestReleaseApi, { cache: "no-cache", signal: controller.signal });
    if (response.ok) {
      const release = await response.json();
      const apk = release.assets.find((asset) =>
        asset.state === "uploaded" &&
        /^CuteLauncher-.+-universal-release\.apk$/.test(asset.name) &&
        asset.browser_download_url?.startsWith(releaseAssetPrefix)
      );
      if (apk) destination = apk.browser_download_url;
    }
  } catch {
    // The latest release page is the fallback when the API is unavailable.
  } finally {
    clearTimeout(timeout);
    link.removeAttribute("aria-busy");
    downloadPending = false;
  }

  window.location.assign(destination);
}

document.querySelectorAll("[data-universal-apk]").forEach((link) => {
  link.addEventListener("click", downloadUniversalApk);
});
