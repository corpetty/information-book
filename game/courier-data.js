// Courier — all game content. Text and numbers are fixed by game/PLAN.md.
// Reader counts are invented to show a shape; they are not data.

export const READERS = {
  A: { name: 'The trained reader', key: 'a finding is provisional and scoped' },
  B: { name: 'The busy reader', key: 'a stated fact is a settled fact' },
  C: { name: 'The team reader', key: 'who is saying this?' },
};

export const STAMPS = {
  PRESERVED: { tone: 'ok', label: 'Roughly right' },
  INVERTED: { tone: 'bad', label: 'Flipped' },
  FLAG: { tone: 'flag', label: 'Read as a team flag' },
  BOUNCED: { tone: 'dim', label: 'Changes nothing' },
};

const R2_LANDING = {
  A: { rule: 'fixed', stamp: 'PRESERVED', text: 'In mice, at absurd doses, unreplicated. Worth watching.' },
  B: {
    rule: 'byChips',
    pass: { stamp: 'PRESERVED', text: 'A mouse result at huge doses. Not worried.' },
    fail: { stamp: 'INVERTED', text: 'X will hurt me. Never buying it again.' },
  },
};

export const ROUNDS = [
  {
    id: 'r1',
    title: 'Delivery 1 · The easy one',
    brief: 'An old finding, long settled. Carry it from the observatory to the dinner table. Every hand-off gives you less room. Cut what you must.',
    claimCost: 2,
    predict: false,
    stamps: ['PRESERVED'],
    chips: [
      { id: 'e1', text: 'the orbit is an ellipse, not a circle', cost: 2, role: 'elaboration' },
      { id: 'e2', text: 'one orbit takes about 365.25 days', cost: 1, role: 'elaboration' },
      { id: 'e3', text: 'strictly, both circle a shared center of mass', cost: 3, role: 'elaboration' },
      { id: 'e4', text: 'confirmed by stellar parallax in 1838', cost: 2, role: 'elaboration' },
    ],
    hops: [
      { options: [{ id: 'textbook', to: 'Textbook', budget: 9, claim: 'The Earth orbits the Sun.' }] },
      { options: [{ id: 'column', to: 'Science column', budget: 6, claim: 'The Earth goes around the Sun.' }] },
      {
        options: [{
          id: 'table', to: 'Dinner table', budget: 3, claim: 'The Earth goes around the Sun.',
          reach: 1000000, mix: { A: 20, B: 80, C: 0 },
          landing: {
            A: { rule: 'fixed', stamp: 'PRESERVED', text: 'Knows the fine print exists and where to find it.' },
            B: { rule: 'fixed', stamp: 'PRESERVED', text: 'Believes the Earth goes around the Sun. Correct.' },
          },
        }],
      },
    ],
    result: {
      ifStamp: null,
      then: '',
      else: 'Everything you cut was detail. The bare claim still lands in the right place. Most compression is like this: lossy and honest.',
    },
    quote: 'preservation',
  },
  {
    id: 'r2',
    title: 'Delivery 2 · Compound X',
    brief: 'A new lab result. Compound X is the made-up example from Chapter 5c of the book; no such substance exists. Same job: lab to readers.',
    claimCost: 2,
    predict: true,
    stamps: ['INVERTED', 'PRESERVED'],
    chips: [
      { id: 'c1', text: 'in mice', cost: 1, role: 'corrective' },
      { id: 'c2', text: 'at about 1,000× any real human dose', cost: 2, role: 'corrective' },
      { id: 'd1', text: 'one study', cost: 1, role: 'elaboration' },
      { id: 'd2', text: 'not yet replicated', cost: 2, role: 'elaboration' },
      { id: 'd3', text: 'full methods in the supplement', cost: 3, role: 'elaboration' },
    ],
    hops: [
      { options: [{ id: 'journal', to: 'Journal', budget: 11, claim: 'Compound X is carcinogenic.' }] },
      { options: [{ id: 'newsroom', to: 'Newsroom', budget: 7, claim: 'Study links Compound X to cancer.' }] },
      {
        options: [
          {
            id: 'feed', to: 'The feed', budget: 3, claim: 'COMPOUND X CAUSES CANCER',
            reach: 4000000, mix: { A: 10, B: 90, C: 0 }, landing: R2_LANDING,
          },
          {
            id: 'longread', to: 'A long read', budget: 7, claim: 'What the Compound X study found, and what it didn’t',
            reach: 40000, mix: { A: 50, B: 50, C: 0 }, landing: R2_LANDING,
          },
        ],
      },
    ],
    result: {
      ifStamp: 'INVERTED',
      then: 'About {n} people now believe Compound X will hurt them. Every word you handed on was true.',
      else: 'Everyone you reached got the key. You reached {reach} people.',
    },
    rival: {
      optionId: 'feed',
      kept: [],
      text: 'Meanwhile, another courier took the bare claim to the feed. It did not need you.',
    },
    quote: 'inversion',
  },
  {
    id: 'r3',
    title: 'Delivery 3 · The correction',
    brief: 'In 2010 a study of 42 people said two minutes of “power posing” raises testosterone, lowers cortisol and improves performance on a risk-taking task. A TED talk about it has more than 70 million views. In 2015 a replication with 200 people found no hormone effect and no behavioral one. You are carrying the replication.',
    claimCost: 2,
    predict: true,
    stamps: ['INVERTED', 'BOUNCED', 'FLAG', 'PRESERVED'],
    chips: [
      { id: 'p1', text: '200 people this time; the original had 42', cost: 2, role: 'corrective' },
      { id: 'p2', text: 'the original’s lead author disavowed it in 2016', cost: 2, role: 'corrective' },
      { id: 'q1', text: 'one author still defends a narrower “felt power” effect', cost: 3, role: 'elaboration' },
      { id: 'q2', text: 'now a standard case of the replication crisis', cost: 1, role: 'elaboration' },
    ],
    hops: [
      { options: [{ id: 'journal', to: 'Journal', budget: 10, claim: 'A larger replication finds no effect of power posing on hormones or behavior.' }] },
      { options: [{ id: 'newsroom', to: 'Newsroom', budget: 6, claim: 'Power posing doesn’t work, bigger study finds.' }] },
      {
        options: [
          {
            id: 'faithful', to: 'Post it straight', budget: 4,
            claim: 'Power posing does not change your hormones or your behavior.',
            reach: 40000, mix: { A: 30, B: 50, C: 20 },
            landing: {
              A: { rule: 'fixed', stamp: 'PRESERVED', text: 'Updates. Drops the pose.' },
              B: {
                rule: 'byChips',
                pass: { stamp: 'PRESERVED', text: 'Bigger study, and the author backed off. Fair enough.' },
                fail: { stamp: 'BOUNCED', text: 'One study says yes, one says no. Keeps the pose.' },
              },
              C: { rule: 'fixed', stamp: 'FLAG', text: 'Who is posting this, and what are they selling?' },
            },
          },
          {
            id: 'punchy', to: 'Punch it up', budget: 2,
            claim: 'POWER POSING WAS A LIE',
            reach: 2000000, mix: { A: 10, B: 50, C: 40 },
            landing: {
              A: { rule: 'fixed', stamp: 'PRESERVED', text: 'Looks up the replication. Winces at the headline.' },
              B: { rule: 'fixed', stamp: 'INVERTED', text: 'So psychology is a scam. Good to know.' },
              C: { rule: 'fixed', stamp: 'FLAG', text: 'Shares it to dunk on TED people.' },
            },
          },
          {
            id: 'upbeat', to: 'Find the good news', budget: 2,
            claim: 'Science confirms: power posing makes you feel more powerful!',
            reach: 6000000, mix: { A: 10, B: 80, C: 10 },
            landing: {
              A: { rule: 'fixed', stamp: 'PRESERVED', text: 'Reads past the headline. Notes that only the feeling survived.' },
              B: { rule: 'fixed', stamp: 'INVERTED', text: 'Knew it. Keeps the pose.' },
              C: { rule: 'fixed', stamp: 'FLAG', text: 'Posts it under a gym selfie.' },
            },
          },
        ],
      },
    ],
    result: {
      ifStamp: 'INVERTED',
      then: 'The version that travelled says something the study didn’t. {n} people took it that way.',
      else: 'You kept it straight. {reach} people saw it.',
    },
    compare: { label: 'The original’s TED talk', count: 70000000, suffix: 'views, and counting' },
    quote: 'fitness',
  },
];

export const CARDS = [
  { id: 'compressed-form', round: 'r1', title: 'Compressed form', href: '../concepts/compressed-form',
    text: 'The short version of an idea, cut to fit the next reader’s room. You just made three of them.' },
  { id: 'receiver-budget', round: 'r1', title: 'Receiver budget', href: '../concepts/receiver-budget',
    text: 'The room shrank at every hand-off because every reader has a finite amount of attention to give. No fix changes that.' },
  { id: 'three-layer-message', round: 'r2', title: 'The key', href: '../concepts/three-layer-message',
    text: 'A message has a claim and a key for reading it: the scope, the method, the doubt. The claim travels. The key is what you cut.' },
  { id: 'truth-compression-regimes', round: 'r2', title: 'Three ways to land', href: '../concepts/truth-compression-regimes',
    text: 'Strip the key and the bare claim can land roughly right, flipped, or as a team flag. Which one depends on the key the reader supplies.' },
  { id: 'optionality-vs-access', round: 'r2', title: 'Faithful or easy', href: '../optionality-vs-access',
    text: 'The long read had room for the key and reached a hundredth of the people. One object can’t be both faithful and easy.' },
  { id: 'memetic-fitness', round: 'r3', title: 'Memetic fitness', href: '../concepts/memetic-fitness',
    text: 'How well a version does at the gates, whatever its truth. The pose is easy, flattering and free. The correction is none of those.' },
  { id: 'selection', round: 'r3', title: 'Selection', href: '../mechanisms/selection',
    text: 'At every hand-off something chose which version moved on. Every version of the correction that travelled far said something the study didn’t.' },
];

// Verbatim from the chapters. courier.test.js checks each against its source file.
export const QUOTES = {
  preservation: {
    text: 'Preservation is when the stripped key was elaboration rather than correction, and the bare claim still decodes to roughly the right place.',
    attr: 'Lossy, Ch. 5c', source: 'content/truth-compression-and-when-each-wins.md',
  },
  inversion: {
    text: 'Inversion is when a true inner message, decoded with the wrong key, yields a false belief, and it is the dangerous regime precisely because nothing was lied about.',
    attr: 'Lossy, Ch. 5c', source: 'content/truth-compression-and-when-each-wins.md',
  },
  fitness: {
    text: 'The pipeline can run its full length and leave a persistent meme even when the finding is wrong, because the correction has worse curation fitness than the thing it corrects.',
    attr: 'Lossy, Ch. 2', source: 'content/case-studies-and-three-realities.md',
  },
  aim: {
    text: 'You cannot aim a cost. You can aim a choice.',
    attr: 'Lossy, Ch. 5b', source: 'content/selection-as-other-engine.md',
  },
};

export const COPY = {
  intro: {
    title: 'Courier',
    kicker: 'A ten-minute game from Lossy',
    body: 'You carry findings from the people who measured them to the people who will repeat them. Every hand-off gives you less room. You decide what to cut.',
    button: 'Start',
  },
  brief: { button: 'Pick it up' },
  hop: {
    heading: 'Hand-off {n} of {total}: to {to}',
    room: 'Room: {used} / {budget}',
    help: 'Tap a part to cut it or put it back. Parts cut at an earlier hand-off are gone.',
    over: 'Over by {k}. Cut something.',
    button: 'Hand it on',
    back: 'Choose a different route',
    lens: 'You can now see which parts are the key (◆) and which are detail (·).',
    lensKey: '◆ key',
    lensDetail: '· detail',
  },
  choose: { heading: 'Where does it go?', option: 'Room {budget} · reaches about {reach} people' },
  predict: { heading: 'Before it lands: how will most readers take it?' },
  result: {
    heading: 'How it landed',
    reader: '{name} · default key: “{key}”',
    called: 'You called it.',
    missed: 'You expected “{expected}”. Most readers: “{actual}”.',
    cards: 'New cards',
    next: 'Next delivery',
    finish: 'See the chain of custody',
  },
  end: {
    heading: 'Chain of custody',
    ledgerKept: 'kept',
    ledgerCut: 'cut',
    carryHeading: 'What you carry out',
    carry: [
      'How many hand-offs is this from the people who measured it?',
      'What part of the key is missing: the scope, the method, or the doubt?',
      'Who chose this version to reach me, and what were they choosing for?',
    ],
    cutHeading: 'What this game cut',
    cut: [
      'Every count of readers here is invented to show a shape. The power-posing facts and the 70 million views are from Chapter 2.',
      'Real readers come in more than three kinds, and one person is all three on different days.',
      'Compound X is the book’s made-up example.',
      'This game covers transport and a first look at selection. The rest of the argument is in the chapters.',
    ],
    replay: 'Carry Compound X again',
    replayNote: 'This time you can see which parts are the key.',
    links: [
      { label: 'Read Chapter 1', href: '../the-information-landscape' },
      { label: 'The short version', href: '../the-short-version' },
      { label: 'Explore the ideas', href: '../explore' },
    ],
  },
};
