// The Desk — all game content. Text and numbers are fixed by game/DESK-PLAN.md.
// Attention, rent and reader counts are invented to show a shape; they are not data.

export const REACH = { 1: 20000, 2: 60000, 3: 200000, 4: 600000, 5: 1500000 };
export const PICKS = 3;
export const STRIKES_TO_CLOSE = 2;

export const DAYS = [
  {
    id: 'day1', rent: 4,
    brief: 'Quiet morning. The wire is mostly sound.',
    items: [
      { id: 'd1a', heat: 1, lands: 'PRESERVED', headline: 'Bigger study finds no hormone effect from power posing',
        note: 'The replication, with its key: 200 people, no effect.' },
      { id: 'd1b', heat: 4, lands: 'INVERTED', headline: 'COMPOUND X CAUSES CANCER',
        note: 'A mouse result at 1,000× the dose, read as a warning to you.' },
      { id: 'd1c', heat: 1, lands: 'PRESERVED', headline: 'Central bank raises rates by a quarter point',
        note: 'Dull, and roughly right.' },
      { id: 'd1d', heat: 5, lands: 'FLAG', headline: 'What they don’t want you to know about Compound X',
        note: 'Nobody is decoding a finding. Sharing it says whose side you are on.' },
      { id: 'd1e', heat: 2, lands: 'PRESERVED', headline: 'Compound X linked to tumours in mice, at doses far above human exposure',
        note: 'The finding with its key attached.' },
      { id: 'd1f', heat: 4, lands: 'INVERTED', headline: 'POWER POSING WAS A LIE',
        note: 'A true correction, read as “psychology is a scam”.' },
    ],
  },
  {
    id: 'day2', rent: 6,
    brief: 'The landlord raised the rent. The rival desk across the street is running hot.',
    items: [
      { id: 'd2a', heat: 2, lands: 'PRESERVED', headline: 'Two labs find no arsenic in the “arsenic-life” bacterium’s DNA',
        note: 'The field catching its own mistake, reported as that.' },
      { id: 'd2b', heat: 4, lands: 'INVERTED', headline: 'EGGS ARE KILLING YOU',
        note: 'One confounded association, read as a verdict.' },
      { id: 'd2c', heat: 1, lands: 'PRESERVED', headline: 'Eggs and heart risk: new study finds a small association; confounders not ruled out',
        note: 'The finding with its hedges.' },
      { id: 'd2d', heat: 5, lands: 'FLAG', headline: 'Eggs: the food the experts want to ban',
        note: 'A team flag about experts, not a claim about eggs.' },
      { id: 'd2e', heat: 2, lands: 'PRESERVED', headline: 'Stanford Prison Experiment: archival tapes show the guards were coached',
        note: 'The correction, intact.' },
      { id: 'd2f', heat: 3, lands: 'INVERTED', headline: 'Scientists say life can be built on arsenic',
        note: 'Refuted in 2012, still circulating as a finding.' },
    ],
  },
  {
    id: 'day3', rent: 8,
    brief: 'Rent is up again. Your readers are drifting to the rival.',
    items: [
      { id: 'd3a', heat: 1, lands: 'PRESERVED', headline: 'Health agency now recommends cloth face coverings as evidence on airborne spread grows',
        note: 'A field updating on evidence, said plainly.' },
      { id: 'd3b', heat: 4, lands: 'INVERTED', headline: 'THE FED IS PRINTING MONEY',
        note: 'Several separate mechanisms collapsed into one household image.' },
      { id: 'd3c', heat: 2, lands: 'PRESERVED', headline: 'What “printing money” does and doesn’t mean: the central bank’s balance sheet, explained',
        note: 'The long version. Few finish it.' },
      { id: 'd3d', heat: 3, lands: 'INVERTED', headline: 'Experts flip-flop on masks again',
        note: 'A field updating, read as a field that knows nothing.' },
      { id: 'd3e', heat: 1, lands: 'PRESERVED', headline: 'Why the Stanford Prison Experiment’s correction still isn’t in most textbooks',
        note: 'True, and nobody clicks.' },
      { id: 'd3f', heat: 5, lands: 'FLAG', headline: 'Masks never worked, and they knew',
        note: 'A side to stand on.' },
    ],
  },
  {
    id: 'day4', rent: 10,
    brief: 'Last day of the month. Rent is at its highest.',
    items: [
      { id: 'd4a', heat: 2, lands: 'PRESERVED', headline: 'Power posing’s lead author says she no longer believes the effects are real',
        note: 'The cleanest correction a field can give. Low reach.' },
      { id: 'd4b', heat: 4, lands: 'INVERTED', headline: 'Science confirms: power posing makes you feel more powerful!',
        note: 'Only the feeling survived the replication. The headline says the study held up.' },
      { id: 'd4c', heat: 1, lands: 'PRESERVED', headline: 'Why nutrition headlines flip: single studies move, the overall picture moves slowly',
        note: 'The key for every nutrition story. Nobody shares keys.' },
      { id: 'd4d', heat: 5, lands: 'FLAG', headline: 'The scientists who lied to you about eggs, masks and power poses',
        note: 'Three corrections, recycled as proof that nobody can be trusted.' },
      { id: 'd4e', heat: 1, lands: 'PRESERVED', headline: 'Arsenic-life, ten years on: how science caught its own mistake',
        note: 'A success story. Successes don’t travel.' },
      { id: 'd4f', heat: 4, lands: 'INVERTED', headline: 'Your morning eggs are back on the menu, scientists say',
        note: 'The next turn of the whiplash, as confident as the last.' },
    ],
  },
  {
    id: 'day5', rent: 0, endowed: true,
    brief: 'A public library offers to pay your rent for a year, on one condition: you can never sell the desk. Today there is no rent. Run what you like.',
    items: [
      { id: 'd5a', heat: 1, lands: 'PRESERVED', headline: 'What the power-posing replication found, and what it didn’t',
        note: 'The finding and its key, at full length.' },
      { id: 'd5b', heat: 5, lands: 'INVERTED', headline: 'COMPOUND X IS IN YOUR CEREAL',
        note: 'A mouse result, now in your kitchen.' },
      { id: 'd5c', heat: 1, lands: 'PRESERVED', headline: 'How to read a nutrition headline: three questions',
        note: 'A key, handed over directly.' },
      { id: 'd5d', heat: 4, lands: 'FLAG', headline: 'Psychology’s dirty secret',
        note: 'A whole field as a team to be against.' },
      { id: 'd5e', heat: 2, lands: 'PRESERVED', headline: 'Compound X: what “carcinogenic in mice” does and doesn’t mean',
        note: 'The finding with its key attached.' },
      { id: 'd5f', heat: 3, lands: 'INVERTED', headline: 'Eggs are good for you now',
        note: 'The whiplash, one turn further.' },
    ],
  },
];

export const CARDS = [
  { id: 'algorithm-as-selection-engine', at: 'audit', title: 'You were the gate', href: '../concepts/algorithm-as-selection-engine',
    text: 'Six stories in, three out, every day. Whatever chooses is a gate, and its criteria decide what readers see. The rent pushed on yours.' },
  { id: 'engagement-equilibrium', at: 'audit', title: 'The engagement trap', href: '../mechanisms/engagement-equilibrium',
    text: 'Nobody tells a desk to run the hot stories. The rent does. When every desk pays the same rent, the hot stories win everywhere, and there is no villain to blame.' },
  { id: 'goodharts-law', at: 'audit', title: 'Goodhart’s law', href: '../concepts/goodharts-law',
    text: 'The meter measured attention, so attention is what the rent asked for. Once a measure becomes the target, it stops telling you what you cared about.' },
  { id: 'out-competition-of-carriers', at: 'audit', title: 'Priced out', href: '../concepts/out-competition-of-carriers',
    text: 'The careful desk is not censored. It is out-competed: the hot story costs the same to run and brings in more.' },
  { id: 'funding-decoupling', at: 'final', title: 'Funding outside the feed', href: '../concepts/funding-decoupling',
    text: 'With the rent gone, you could run the careful stories. Change who pays, and you change what the gate selects.' },
  { id: 'survival-not-victory', at: 'final', title: 'Survival, not victory', href: '../concepts/survival-not-victory',
    text: 'The endowed desk reached a fraction of the rival’s readers. It did not win. It lasted, and kept the careful version in print.' },
];

// Verbatim from the chapters. desk.test.js checks each against its source file.
export const QUOTES = {
  proxy: {
    text: 'engagement is a proxy for revenue, dressed up as a proxy for user benefit',
    attr: 'Lossy, Ch. 10', source: 'content/political-economy-of-attention.md',
  },
  captor: {
    text: 'You can fight a captor; you cannot fight an equilibrium.',
    attr: 'Lossy, Ch. 10', source: 'content/political-economy-of-attention.md',
  },
  outlast: {
    text: 'They never beat the dark age. They just outlasted it.',
    attr: 'Lossy, Ch. 12', source: 'content/infrastructure-for-integration.md',
  },
};

export const COPY = {
  intro: {
    kicker: 'A game from Lossy · part two',
    title: 'The Desk',
    body: 'You run a news desk. Each day the wire sends six stories and you can run three. The landlord takes rent in attention. Miss the rent twice and the desk closes.',
    button: 'Open the desk',
  },
  brief: {
    heading: 'Day {n}',
    status: 'Rent: {rent} attention · Strikes: {strikes} of 2',
    statusEndowed: 'Rent: none · The library pays',
    button: 'See the wire',
  },
  pick: {
    heading: 'Day {n}: pick three',
    count: '{k} of 3 picked',
    meter: 'Attention: {a} / rent {rent}',
    meterEndowed: 'Attention: {a} · no rent today',
    heat: 'attention +{heat}',
    short: 'Short by {k}. You can run it anyway and take a strike.',
    button: 'Run these three',
  },
  day: {
    heading: 'Day {n}: the numbers',
    earned: 'Attention earned: {a}. Rent: {rent}.',
    paid: 'Rent paid.',
    missed: 'Rent missed. Strike {s} of 2.',
    reach: 'Readers reached: {reach}',
    closed: 'Two strikes. The desk is closed, and the rival desk takes your readers.',
    button: 'Next',
  },
  audit: {
    heading: 'The audit',
    survived: 'Your desk made it through the month.',
    closed: 'Your desk closed on day {d}.',
    meter: 'The meter counted attention. It never counted what readers came away believing. Here is what they believed.',
    dayHeading: 'Day {n}',
    summary: '{inv} readers came away believing something the evidence doesn’t support. {flag} more read a story as a team flag.',
    summaryClean: 'Every story you ran landed roughly right. That is why the desk closed.',
    cards: 'New cards',
    button: 'Next: a different landlord',
  },
  final: {
    heading: 'Day 5: the endowed desk',
    yours: 'Your desk reached {reach} readers.',
    rival: 'The rival desk ran the three hottest stories and reached {reach}.',
    yoursLabel: 'Your desk',
    rivalLabel: 'The rival desk',
    cards: 'New cards',
    button: 'Finish',
  },
  end: {
    heading: 'What you carry out',
    carry: [
      'Who chose this story for me, and what are they paid in?',
      'What would this outlet have to run to make its rent tomorrow?',
      'Which of the sources I trust are paid for by something other than my attention?',
    ],
    cutHeading: 'What this game cut',
    cut: [
      'Every number is invented to show a shape. The headlines come from the book’s cases; Compound X is its made-up example.',
      'Real editors have standards, and many hold them. The game shows the pull of the rent, not a verdict on any newsroom.',
      'An endowment is one way out of the attention market. Chapter 12 weighs others, and admits it has not shown they can pay for everything.',
    ],
    replay: 'Run the desk again',
    links: [
      { label: 'Next: be the reader', href: './reader.html' },
      { label: 'Back to Courier', href: './' },
      { label: 'Read Chapter 10', href: '../political-economy-of-attention' },
      { label: 'Read Chapter 12', href: '../infrastructure-for-integration' },
    ],
  },
};
