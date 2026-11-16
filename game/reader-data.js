// The Reader — all game content. Text and numbers are fixed by game/READER-PLAN.md.
// Minutes and costs are invented to show a shape; they are not data.

// The stops on the way upstream. depth 0 is what reaches you; depth 4 is the measurement.
export const STOPS = ['the feed', 'the news', 'the field', 'the paper', 'the measurement'];

// HOP_COST[d] is the minutes it takes to go from depth d to depth d + 1.
export const HOP_COST = [2, 5, 10, 15];
export const TUTOR_COST = 4;

export const WEEKS = [
  {
    id: 'week1', minutes: 50, tools: false,
    brief: 'Five things reach you this week. You have 50 focused minutes to check them. Each stop upstream costs more than the last. You can believe what you see, shrug it off, or trace it.',
    claims: [
      {
        id: 'earth',
        meme: { text: 'The Earth goes around the Sun.', lands: 'PRESERVED' },
        hops: [
          { text: 'Astronomers confirm: Earth completes one orbit of the Sun about every 365.25 days.', lands: 'PRESERVED' },
          { text: 'Settled astronomy for centuries: the planets, Earth included, orbit the Sun on ellipses.', lands: 'PRESERVED' },
          { text: 'Kepler’s laws of planetary motion, fitted to decades of observations.', lands: 'PRESERVED' },
          { text: 'Tycho Brahe’s naked-eye records of planetary positions, and in 1838 the first measured stellar parallax.', lands: 'PRESERVED' },
        ],
        lesson: 'The short version was right. Tracing it would have cost minutes you needed elsewhere.',
      },
      {
        id: 'power',
        meme: { text: 'Stand like Wonder Woman for two minutes and you’ll ace the interview.', lands: 'INVERTED' },
        hops: [
          { text: 'TED talk: two minutes of “power posing” changes your hormones.', lands: 'INVERTED' },
          { text: 'A 200-person replication found no effect on hormones or behavior, and the original lead author disavowed the work.', lands: 'PRESERVED' },
          { text: 'The 2010 paper: 42 people; poses raised testosterone and lowered cortisol. You already know it didn’t replicate.', lands: 'PRESERVED' },
          { text: 'Saliva samples and risk-task scores from 42 participants.', lands: 'PRESERVED' },
        ],
        lesson: 'Two stops up, the field had already corrected it.',
      },
      {
        id: 'masks',
        meme: { text: 'Masks never worked, and they knew.', lands: 'FLAG' },
        hops: [
          { text: 'Health agency reverses early advice and recommends cloth face coverings as evidence on airborne spread grows.', lands: 'PRESERVED' },
          { text: 'The early advice bundled two things: saving scarce medical masks for hospitals, and an early reading of the evidence that favored droplets.', lands: 'PRESERVED' },
          { text: 'Evidence through spring 2020 made airborne spread clearer.', lands: 'PRESERVED' },
          { text: 'Outbreak reports and lab measurements of how the virus spreads, gathered in the first months of 2020.', lands: 'PRESERVED' },
        ],
        lesson: 'One stop up, the team flag turned back into a claim: advice that changed with the evidence.',
      },
      {
        id: 'eggs',
        meme: { text: 'EGGS ARE KILLING YOU', lands: 'INVERTED' },
        hops: [
          { text: 'Study links eating eggs to heart disease.', lands: 'INVERTED' },
          { text: 'Nutrition science: single diet studies find small, confounded associations; the overall picture moves slowly.', lands: 'PRESERVED' },
          { text: 'One cohort study: a small association between eggs and heart risk; confounders not ruled out.', lands: 'PRESERVED' },
          { text: 'Food questionnaires: people recalling what they ate, then followed for years.', lands: 'PRESERVED' },
        ],
        lesson: 'Two stops up: small, confounded, and one study among many.',
      },
      {
        id: 'forest',
        meme: { text: 'Old German forestry: tidy rows of spruce, more wood. Why don’t we do this everywhere?', lands: 'INVERTED' },
        hops: [
          { text: 'Historians: Prussian and Saxon foresters’ new plantations produced impressive timber yields.', lands: 'INVERTED' },
          { text: 'Forestry science of the time: a standardized tree let a forest’s wood be calculated and planned; managed plantations beat wild forest.', lands: 'INVERTED' },
          { text: 'The yield tables: the first rotation of planted spruce produced more saleable wood.', lands: 'INVERTED' },
          { text: 'The ledgers had columns for saleable wood, and none for underbrush, soil life or the mix of species. Losses of 20 to 30 percent came two or three generations later.', lands: 'PRESERVED' },
        ],
        lesson: 'Every stop above the measurement repeated the same mistake. Only the ledger shows what was never counted.',
      },
    ],
  },
  {
    id: 'week2', minutes: 10, tools: true,
    brief: 'A new week, and only 10 minutes. Two helpers are now on offer. The free assistant built into your feed answers instantly. The library’s tutor takes 4 minutes and walks you through the source.',
    claims: [
      {
        id: 'arsenic',
        meme: { text: 'NASA found alien life on Earth.', lands: 'INVERTED' },
        hops: [
          { text: 'NASA: a bacterium builds its DNA with arsenic.', lands: 'INVERTED' },
          { text: 'Two independent refutations: the bacterium’s DNA held no arsenic, and the original measurement was contaminated.', lands: 'PRESERVED' },
          { text: 'The 2010 paper in Science: a Mono Lake bacterium swaps arsenic for phosphorus. You already know it was refuted.', lands: 'PRESERVED' },
          { text: 'Arsenic readings from the DNA of cells grown in an arsenic-rich medium.', lands: 'PRESERVED' },
        ],
        assistant: { text: 'The 2010 “arsenic life” claim was refuted; later studies found no arsenic in the bacterium’s DNA.', lands: 'PRESERVED' },
        lesson: 'The free assistant gets this one right: the refutation is all over its training text.',
      },
      {
        id: 'prison',
        meme: { text: 'Give ordinary people power and they turn cruel. Stanford proved it.', lands: 'INVERTED' },
        hops: [
          { text: 'Stanford study: student guards turned abusive within days.', lands: 'INVERTED' },
          { text: '2018 archival work showed the guards were coached and a prisoner’s breakdown was performed; the field largely accepted the critique.', lands: 'PRESERVED' },
          { text: 'Zimbardo’s 1971 account of the experiment. You already know what the tapes showed.', lands: 'PRESERVED' },
          { text: 'Tapes and notes from the Stanford basement, reread in 2018.', lands: 'PRESERVED' },
        ],
        assistant: { text: 'The Stanford Prison Experiment (1971) showed that ordinary people can become abusive when given power over others.', lands: 'INVERTED' },
        lesson: 'Ask the free assistant and you get the textbook version, because that is most of what it read.',
      },
      {
        id: 'compoundx',
        meme: { text: 'COMPOUND X CAUSES CANCER', lands: 'INVERTED' },
        hops: [
          { text: 'Study links Compound X to cancer.', lands: 'INVERTED' },
          { text: 'One mouse study at about 1,000× any human dose; not yet replicated; no human data.', lands: 'PRESERVED' },
          { text: 'The paper: tumours in mice fed Compound X at very high doses.', lands: 'PRESERVED' },
          { text: 'Tumour counts in two groups of lab mice.', lands: 'PRESERVED' },
        ],
        assistant: { text: 'Studies have linked Compound X to cancer.', lands: 'INVERTED' },
        lesson: 'The free assistant’s one line is true and drops the key: in mice, at huge doses.',
      },
    ],
  },
];

export const CARDS = [
  { id: 'receiver-budget', week: 'week1', title: 'A week of focus', href: '../concepts/receiver-budget',
    text: 'You could not trace everything, and nobody can. The budget is fixed; what each minute buys depends on what you already know.' },
  { id: 'legibility', week: 'week1', title: 'The first compression', href: '../concepts/legibility',
    text: 'The forest ledgers had no column for soil. Nothing later in the pipeline could recover what the measurement never recorded.' },
  { id: 'open-vigilance', week: 'week1', title: 'Shrugging is a choice too', href: '../concepts/open-vigilance',
    text: 'People mostly err toward caution, refusing something true more often than swallowing something false. Shrug at everything and you lose the true ones.' },
  { id: 'decompression-on-demand', week: 'week2', title: 'The patient tutor', href: '../concepts/decompression-on-demand',
    text: 'The tutor did not give you more minutes. It made each one go further, by doing the unpacking you could not afford.' },
  { id: 'compressed-form-as-authority', week: 'week2', title: 'The answer that replaces the source', href: '../concepts/compressed-form-as-authority',
    text: 'The assistant’s answer arrived free and sure of itself, with no sign of what it dropped. That is what lets a summary stand in for the source.' },
  { id: 'corpus-capture', week: 'week2', title: 'What the assistant read', href: '../concepts/corpus-capture',
    text: 'An assistant answers from the text it was trained on. If most of that text repeats the old story, so does the answer.' },
];

// Verbatim from the chapters. reader.test.js checks each against its source file.
export const QUOTES = {
  raw: {
    text: 'Raw data is misnamed. The "raw" is the first compression, pretending to be the source.',
    attr: 'Lossy, Ch. 1', source: 'content/the-information-landscape.md',
  },
  budget: {
    text: 'The receiver budget is finite, but its capacity, how much complex form a unit of time can absorb, is partly a function of the structure the receiver has already built.',
    attr: 'Lossy, Ch. 3', source: 'content/info-time-limit.md',
  },
  summary: {
    text: 'The paper is technically still there; nobody reads it. The summary is technically not the paper; everybody reads it.',
    attr: 'Lossy, Ch. 11', source: 'content/ai-as-new-node.md',
  },
  owner: {
    text: 'Which mode a given model rewards, patient decompression or eager summary, is a design decision, and it sits with the owner.',
    attr: 'Lossy, Ch. 11', source: 'content/ai-as-new-node.md',
  },
};

export const COPY = {
  intro: {
    kicker: 'A game from Lossy · part three',
    title: 'The Reader',
    body: 'You carried findings and you ran a desk. Now you are at the end of the pipe, with a week’s worth of focused minutes and a feed that does not stop.',
    button: 'Open the feed',
  },
  brief: {
    heading: 'Week {n}',
    button: 'Start the week',
  },
  claim: {
    heading: 'Claim {i} of {total}',
    where: 'You are looking at it in {stop}.',
    minutes: 'Minutes left: {m} of {total}',
    trace: 'Trace it to {next} ({cost} min)',
    noTime: 'Not enough minutes left to go further.',
    bottom: 'This is as far up as it goes.',
    accept: 'Believe it',
    settle: 'Believe this version',
    shrug: 'Shrug it off',
    assistant: 'Ask the free assistant (0 min)',
    tutor: 'Ask the library tutor ({cost} min)',
    trail: 'On the way up',
  },
  answer: {
    assistantHeading: 'The free assistant says',
    tutorHeading: 'The library tutor walks you through it',
    button: 'Next claim',
  },
  reveal: {
    heading: 'Week {n}: what you came away believing',
    spent: 'You used {used} of {total} minutes.',
    routeAccept: 'Believed it as it reached you',
    routeShrug: 'Shrugged it off',
    routeTrace: 'Traced it to {stop}',
    routeAssistant: 'Asked the free assistant',
    routeTutor: 'Asked the library tutor',
    minutes: '{m} min',
    noBelief: 'No belief',
    you: 'You',
    others: 'Two other readers, same week',
    busy: 'Believed everything as it arrived: 0 minutes',
    shrugger: 'Shrugged at everything: 0 minutes',
    assistantOnly: 'Asked the free assistant about everything: 0 minutes',
    cards: 'New cards',
    next: 'Next week',
    finish: 'Finish',
  },
  end: {
    heading: 'What you carry out',
    carry: [
      'Is the short version likely to be roughly right anyway, or is this worth my minutes?',
      'Which stop upstream would settle it: the news, the field, the paper, or the measurement?',
      'When an assistant answers, who owns it, and what did it read?',
    ],
    cutHeading: 'What this game cut',
    cut: [
      'Minutes and costs are invented to show a shape. Real tracing takes longer, and a real week holds far more than eight claims.',
      'Every version of every claim is a simplification of what the book’s cases say. Compound X is the book’s made-up example.',
      'The tutor here is faithful because the game says so. Chapter 11 is about why that is the hard part.',
      'Not holding a view on something is often reasonable. The game counts a shrug as no belief, not as an error.',
    ],
    replay: 'Read the feed again',
    links: [
      { label: 'Next: build the bridge', href: './bridge.html' },
      { label: 'Back to Courier', href: './' },
      { label: 'The Desk', href: './desk.html' },
      { label: 'Read Chapter 1', href: '../the-information-landscape' },
      { label: 'Read Chapter 11', href: '../ai-as-new-node' },
    ],
  },
};
