# Ludovica's Spelling Challenge 🌟

A personalised weekly spelling practice app for Ludovica.

## How to update the words each week

Open `words.js` in any text editor (or directly on GitHub) and change
the entries in the `SPELLING_WORDS` array:

```js
const SPELLING_WORDS = [
  { word: "elephant",  hint: "a big grey animal",  emoji: "🐘" },
  { word: "beautiful", hint: "something pretty",   emoji: "🌸" },
  // add as many words as you like...
];
```

- **word** — the spelling word (required)
- **hint** — a clue shown if she asks for help (optional)
- **emoji** — shown alongside the hint (optional, defaults to ⭐)

You can also change the season theme at the bottom of `words.js`:

```js
const SEASON = "spring"; // "spring" | "summer" | "autumn" | "winter"
```

## Hosting on GitHub Pages

1. Push this folder to a GitHub repository.
2. Go to **Settings → Pages** and set the source to your main branch / root.
3. Your game will be live at `https://<your-username>.github.io/<repo-name>/`
4. Each week, edit `words.js`, commit, and the live site updates automatically.

## How the game works

1. Ludovica presses the 🔊 button to hear the word spoken aloud.
2. She can press it again as many times as she needs.
3. She types the spelling using the on-screen keyboard (or a physical keyboard).
4. She presses **Check** — instant feedback!
5. If she's stuck she can press 💡 for the hint.
6. She earns a star for every correct first attempt.
7. After all words, a celebration screen shows her score.
