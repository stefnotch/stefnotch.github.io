#let frontmatter = (
  title: "Enabling COOP/COEP without touching the server",
  date: datetime(year: 2021, month: 8, day: 5),
  tags: ("programming", "web"),
  template: "layout.typ",
  description: "Enabling COOP/COEP with just a service worker",
)

_Or how to modify security headers clientside._


Ever since the rather impressive #link("https://meltdownattack.com/")[Meltdown and Spectre] attacks, browser vendors had to #link("https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/SharedArrayBuffer#security_requirements")[clamp down] on shared memory and high resolution timers. While this conveniently means that the casual user doesn't have to work about #link("https://xkcd.com/1938")[phantom trolleys], it can be an irritating restriction for a developer. Some APIs got #link("https://developer.mozilla.org/en-US/docs/Web/API/Performance/now")[limited], while others were completely disabled unless one does a little dance to appease the web browser.



This means that certain web-applications have an additional hurdle to overcome.

A few examples of web-applications that have this problem are in-browser video converters using #link("https://github.com/ffmpegwasm/ffmpeg.wasm")[ffmpeg.wasm], a web-based #link("https://github.com/gzuidhof/starboard-notebook")[notebook that supports Python] and #link("https://emscripten.org/docs/porting/pthreads.html")[multithreaded Emscripten applications].



== The Problem

The following APIs are unavailable by default

- `SharedArrayBuffer`
- `Atomics`



To re-enable them, the site needs to be served over HTTPS#footnote[ Or be on localhost, since the requirement is that the document has to be in a #link("https://developer.mozilla.org/en-US/docs/Web/Security/Secure_Contexts")[secure context]] and two headers need to be set. The headers, which have to be set server side#footnote[ Those headers cannot be set using `<meta http-equiv="..">`, as they're not included in the #link("https://developer.mozilla.org/en-US/docs/Web/HTML/Element/meta#attr-http-equiv")[whitelist].], are

- `Cross-Origin-Opener-Policy: same-origin`

- `Cross-Origin-Embedder-Policy: require-corp`



This can be quite a challenge for a number of reasons. It is not always a walk in the park for a frontend developer to control the headers that the backend sends. Static frontend applications are becoming more widespread. It is quite common that one uses a CDN which simply doesn't support setting custom HTTP headers. I personally needed a solution, as I was deploying #link("https://stefnotch.github.io/quantum-sheet")[a web-based computer algebra system] on GitHub pages.



Finally, do note that those headers impose some additional restrictions. The main one is that the `Cross-Origin-Embedder-Policy` header makes it harder to load cross-origin resources.


== What if I can't set the headers myself?

_Service workers to the rescue!_



It turns out that there is something that sits between the server serving the webpage and frontend Javascript. Service workers can intercept all requests, modify the responses and even set arbitrary HTTP headers.



First, we register our service worker in a Javascript file that gets loaded as soon as the website gets loaded. To make sure that the service worker can intercept all requests, we have to reload the page.

```js
// main.js
if ("serviceWorker" in navigator) {
  // Register service worker
  navigator.serviceWorker.register(new URL("./sw.js", import.meta.url)).then(
    function (registration) {
      console.log("COOP/COEP Service Worker registered", registration.scope);
      // If the registration is active, but it's not controlling the page
      if (registration.active && !navigator.serviceWorker.controller) {
          window.location.reload();
      }
    },
    function (err) {
      console.log("COOP/COEP Service Worker failed to register", err);
    }
  );
} else {
  console.warn("Cannot register a service worker");
}
```



Then, place the service worker right next to the script above and call it `sw.js`. The important part is that every time the `fetch` event listener is invoked, we replace the response with one where the COOP/COEP headers are set. All the other parts are optional.

Do make sure that the service worker gets served from the topmost directory, right where the `index.html` of the website is. This makes sure that the service worker's scope includes all the files on your site.

```js
// sw.js
self.addEventListener("install", function () {
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener("fetch", function (event) {
  if (event.request.cache === "only-if-cached" && event.request.mode !== "same-origin") {
    return;
  }

  event.respondWith(
    fetch(event.request)
      .then(function (response) {
        // It seems like we only need to set the headers for index.html
        // If you want to be on the safe side, comment this out
        // if (!response.url.includes("index.html")) return response;

        const newHeaders = new Headers(response.headers);
        newHeaders.set("Cross-Origin-Embedder-Policy", "require-corp");
        newHeaders.set("Cross-Origin-Opener-Policy", "same-origin");

        const moddedResponse = new Response(response.body, {
          status: response.status,
          statusText: response.statusText,
          headers: newHeaders,
        });

        return moddedResponse;
      })
      .catch(function (e) {
        console.error(e);
      })
  );
});
```



What this ends up doing is

1. when the page gets loaded for the first time, we register the worker
2. then we reload the page
3. and finally, now that the worker is controlling everything, every request will now have the appropriate headers set



I can quite recommend using the #link("https://github.com/gzuidhof/coi-serviceworker")[`coi-serviceworker` library], which is based on this post and does exactly what is needed.



Of course the ideal solution is still to set the headers server side.



== Security issue?

No, I doubt that. There is a #link("https://w3c-test.org/html/cross-origin-opener-policy/popup-coop-by-sw.https.html")[w3c test] for this. It's a way of opting in into additional security restrictions on your website.

Opting out with the same approach does not work.

#quote(block: true, attribution: link("https://web.dev/why-coop-coep/"))[
  Once you add the COEP header, you won't be able to bypass the  restriction by using service workers. If the document is protected by a  COEP header, the policy is respected before the response enters the  document process, or before it enters the service worker that is  controlling the document.
]

