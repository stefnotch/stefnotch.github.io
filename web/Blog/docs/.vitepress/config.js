module.exports = {
  base: "/web/Blog/",
  head: [],
  title: "Stefnotch's Bloggy Blog",
  themeConfig: {
    // TODO: Better sidebar
    nav: [
      {
        text: "GitHub Repo",
        link: "https://github.com/stefnotch/stefnotch.github.io",
      },
    ],
  },
  markdown: {
    // options for markdown-it-anchor
    anchor: { permalink: false },

    // options for markdown-it-toc
    toc: { includeLevel: [1, 2, 3] },

    config: (md) => {
      // use more markdown-it plugins!
      mk = require("@traptitech/markdown-it-katex");

      md.use(mk, { throwOnError: false, errorColor: " #cc0000" });

      // https://github.com/Maorey/Blog/blob/ac5ced6deb3bbec689c672ec425640a0fba598f3/docs/.vitepress/config.js#L51

      const mdRender = md.render;
      md.render = function () {
        return mdRender
          .apply(this, arguments)
          .replace(/<span class="katex">/g, '<span v-pre class="katex">');
      };
    },
  },
};
