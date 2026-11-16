// The Keeper — all game content. Text and numbers are fixed by game/KEEPER-PLAN.md.
// Funds, decay and reader counts are invented to show a shape; they are not data.

export const RULES = {
  generations: 4,
  archiveStart: 100,     // percent of the full texts still legible
  archiveDecay: 25,      // lost each generation
  copyGain: 10,          // regained per point spent copying (archive never exceeds 100 or drops below 0)
  readersStart: 2,       // people who can read the full texts when you start
  studentsPerReader: 2,  // each reader can teach at most this many students
  offerGeneration: 3,    // the generation in which the summary engine makes its offer
  offerBonus: 2,         // extra funds that generation if you accept
  summaryPerPoint: 2,    // summary readers per teaching point if you accept
  keepArchive: 40,       // at the end, an archive at or above this counts as kept
  keepReaders: 2,        // at the end, this many full readers or more counts as kept
};

export const FUNDING = {
  endowed: {
    label: 'Take the endowment',
    about: 'This generation gets less to spend. Every generation after it is paid for.',
    funds: [3, 4, 4, 4],
  },
  donations: {
    label: 'Live off donations',
    about: 'More to spend now. Donations shrink as the feeds take your readers’ evenings.',
    funds: [5, 4, 3, 2],
  },
};

export const OUTCOMES = {
  kept: { title: 'The books and their readers both made it',
    text: 'There are still full texts on the shelves and people who can read them, and teach the next ones. You did not beat the age you lived in. You outlasted it.' },
  locked: { title: 'A library nobody can read',
    text: 'The archive held. The readers did not. The books are still there, and the people who could open them are gone.' },
  nobooks: { title: 'Readers without books',
    text: 'You kept training readers, and the texts they were trained on crumbled. They are teaching from memory now, and memory drifts.' },
  lost: { title: 'Both gone',
    text: 'The texts crumbled and the readers retired without successors.' },
};

export const CARDS = [
  { id: 'preservation-vs-training-pair', title: 'Two jobs, not one', href: '../concepts/preservation-vs-training-pair',
    text: 'Keeping hard knowledge alive takes an archive and people who can read it. Either alone fails: an archive nobody can read might as well be empty.' },
  { id: 'institutional-decay-rates', title: 'Books fade, readers retire', href: '../concepts/institutional-decay-rates',
    text: 'Your archive lost a quarter a generation. Your readers were all gone each generation unless you had trained new ones. Training is the half that decays fast.' },
  { id: 'capture-asymmetry', title: 'The corrupted generation', href: '../concepts/capture-asymmetry',
    text: 'Had the summary engine taught a generation, its students could not have read the books, or taught anyone who could. A bad copy can be replaced from another; a generation cannot.' },
  { id: 'work-of-generations', title: 'The work of generations', href: '../concepts/work-of-generations',
    text: 'Nothing you did paid off inside one generation. Institutions that hold hard knowledge are built, and lost, on that timescale.' },
];

// Verbatim from the chapters. keeper.test.js checks each against its source file.
export const QUOTES = {
  corrupted: {
    text: 'You can replace a corrupted book; you cannot replace a corrupted generation, not quickly and not from outside.',
    attr: 'Lossy, Ch. 8', source: 'content/preservation-vs-training.md',
  },
  outlast: {
    text: 'They never beat the dark age. They just outlasted it.',
    attr: 'Lossy, Ch. 12', source: 'content/infrastructure-for-integration.md',
  },
};

export const COPY = {
  intro: {
    kicker: 'A game from Lossy · part five',
    title: 'The Keeper',
    body: 'You keep a library through four generations. Each generation you spend its funds on copying the old texts before they crumble, or on teaching people who can read them. Every generation, a quarter of the archive fades and every reader retires. Each reader can teach at most two students.',
    button: 'Open the library',
  },
  fund: {
    heading: 'Before the first generation',
    body: 'A patron offers an endowment.',
  },
  offer: {
    heading: 'Generation 3: an offer',
    body: 'A company offers its summary engine. Put a point into teaching and it trains two readers, no teachers needed, and it adds 2 to your funds this generation. Its students learn the summaries, not the texts.',
    accept: 'Use the summary engine',
    decline: 'Keep teaching from the texts',
  },
  gen: {
    heading: 'Generation {n}',
    status: 'Funds: {p} · Archive: {a}% · Readers: {r}',
    pick: 'How do you spend the funds?',
    split: 'Copy {c} · Teach {t}',
    engine: 'The summary engine is teaching this generation.',
  },
  result: {
    heading: 'Generation {n}: what is left',
    archive: 'The archive stands at {a}%.',
    readers: '{r} people can read the full texts.',
    summary: '{s} people learned from the summaries. They cannot read the texts, or teach anyone who can.',
    locked: 'The books are on the shelves. Nobody left can read them.',
    crumbled: 'The last legible copies have crumbled.',
    next: 'Next generation',
    last: 'See what is left',
  },
  verdict: {
    heading: 'Four generations on',
    ledger: 'The ledger',
    row: 'Generation {n}: copy {c}, teach {t} → archive {a}%, readers {r}',
    rowSummary: 'Generation {n}: copy {c}, teach {t} → archive {a}%, readers {r}, summary readers {s}',
    cards: 'New cards',
    button: 'Finish',
  },
  end: {
    heading: 'What you carry out',
    carry: [
      'Where is the full version of what I rely on kept, and who can still read it?',
      'Who is being trained to read it next, and who pays for that?',
      'When something offers to teach faster, what does it teach from?',
    ],
    cutHeading: 'What this game cut',
    cut: [
      'Every number is invented to show a shape. Real archives can rot fast and real apprenticeships can last centuries; the book calls its rule of thumb a rule of thumb.',
      'The summary engine stands for any teaching that replaces the source, not for any one product.',
      'Four generations is a short run. The book’s timescale is universities and cathedrals.',
    ],
    replay: 'Keep the library again',
    links: [
      { label: 'Back to Courier', href: './' },
      { label: 'The Bridge', href: './bridge.html' },
      { label: 'Read Chapter 8', href: '../preservation-vs-training' },
      { label: 'Read Chapter 12', href: '../infrastructure-for-integration' },
    ],
  },
};
