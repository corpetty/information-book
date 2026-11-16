// The Bridge — all game content. Text and outcomes are fixed by game/BRIDGE-PLAN.md.
// The towns, people and ten-year outcomes are invented to show the book's argument.

export const FINDING = 'Today the river’s Compound X is far below any dose that harmed mice. If the works upstream doubles its output, as it plans to, the level could climb into the range worth watching within about ten years.';

export const MESSENGERS = {
  you: { name: 'You', about: 'A toxicologist from the university in the city, with your field’s slides.' },
  host: { name: 'Jules', about: 'Hosts a popular science channel. Clear, friendly, and famous.' },
  ana: { name: 'Ana', about: 'A river ecologist who grew up fishing in Lowmill and still lives there.' },
  sam: { name: 'Sam', about: 'A chemist on the works floor in Ridgeton who trained in toxicology.' },
};

export const FRAMINGS = {
  safe: { label: 'Lead with the reassurance', text: 'Today’s river is safe.' },
  risk: { label: 'Lead with the warning', text: 'The river could be in trouble within ten years.' },
  gauges: { label: 'Bring the readings', text: 'Here are the readings, taken where you live. Today’s are far below any harmful dose. Here is the line they would cross if the works doubles output, and here is how you can check it yourselves every month.' },
};

export const TOWNS = [
  {
    id: 'lowmill', name: 'Lowmill', local: 'ana',
    about: 'A fishing town downstream of the works.',
    heard: [
      '“The works has told us everything’s fine before.”',
      '“My father fished this river for forty years.”',
      '“We listen to people who’ve stood in this river.”',
    ],
    outsiders: {
      you: { lands: 'BOUNCED', text: 'Polite applause for the university slides, then the first question: “Who paid for this study?” Nobody’s mind changed.' },
      host: { lands: 'BOUNCED', text: '“Seen Jules on my phone. Didn’t know Jules fished.” They watched, and went home.' },
    },
    framings: {
      safe: { lands: 'FLAG', text: '“Safe. That’s what the works always says.” As far as the hall is concerned, Ana is on the works’ side now.' },
      risk: { lands: 'INVERTED', text: '“Ten years? It’s poisoning us now.” By the weekend people are buying bottled water and the fish market is empty.' },
      gauges: { lands: 'PRESERVED', text: 'Ana spreads the readings on a table and people find their own fishing spots on the map. “So we’re fine now, and we watch it.”' },
    },
  },
  {
    id: 'ridgeton', name: 'Ridgeton', local: 'sam',
    about: 'The town that works the plant upstream.',
    heard: [
      '“Every few years someone from the city tries to shut us down.”',
      '“Half this town works the line.”',
      '“Show me numbers from someone who’s been on the floor.”',
    ],
    outsiders: {
      you: { lands: 'BOUNCED', text: '“Another expert from the city.” The questions are all about jobs, and your charts go unread.' },
      host: { lands: 'BOUNCED', text: '“Jules makes videos.” The shift crowd is polite and unmoved.' },
    },
    framings: {
      safe: { lands: 'INVERTED', text: '“Told you it was nothing.” The planned expansion is now proof that the river can take anything.' },
      risk: { lands: 'FLAG', text: '“So Sam’s come to shut the works.” Sam is an outsider now, and the river is an argument about jobs.' },
      gauges: { lands: 'PRESERVED', text: 'Sam pins the readings by the time clock, next to the line they would cross. “Fine now. Let’s keep it fine when we expand.”' },
    },
  },
];

export const CONNECTIONS = {
  forum: {
    label: 'One shared online forum for both towns', about: 'Everyone in, all the time.', rule: 'flag',
    epilogue: 'The first confident post set the tone, and every post after it was read by which town it came from. Within a year the forum was two camps, and the river was a flag.',
  },
  apart: {
    label: 'Keep the towns apart', about: 'Each town gets its own yearly briefing.', rule: 'keep',
    epilogue: 'Each town kept what it had heard, and heard every later reading from its own side. Nothing got worse between them. Nothing got better.',
  },
  panel: {
    label: 'A joint river panel', about: 'Two people from each town read the gauges together every month and publish the readings.', rule: 'audit',
    epilogue: 'Nobody had to trust the other town, or you. Anyone could check the gauges. When the readings began to climb, both towns saw the same numbers in the same month.',
  },
};

export const CARDS = [
  { id: 'versatile-expertise', at: 'towns', title: 'The bridge', href: '../concepts/versatile-expertise',
    text: 'Ana and Sam were heard because each was a peer at home and knew the field deeply. Depth gets a bridge through the door; flexibility lets it translate.' },
  { id: 'curse-of-expertise', at: 'towns', title: 'The curse of expertise', href: '../concepts/curse-of-expertise',
    text: 'Your field’s slides felt perfectly clear to you. That is the trap: the deeper you are in one way of seeing, the harder it is to notice it is only one way.' },
  { id: 'polarization-via-distrust', at: 'epilogue', title: 'Just connect them?', href: '../concepts/polarization-via-distrust',
    text: 'Two reasonable towns, each trusting the other a little less, can drift apart faster once you put them in one room.' },
  { id: 'zollman-effect', at: 'epilogue', title: 'The stampede', href: '../concepts/zollman-effect',
    text: 'In a densely connected crowd, the first confident claim spreads before the evidence is in. There is a best amount of connection, and it is not the most.' },
  { id: 'survivable-polarization', at: 'epilogue', title: 'Built for partial trust', href: '../concepts/survivable-polarization',
    text: 'The panel did not need the towns to trust each other. It let a skeptic check the part they cared about.' },
];

// Verbatim from the chapters. bridge.test.js checks each against its source file.
export const QUOTES = {
  peer: {
    text: 'The depth is what gets them admitted as a peer on either side; the flexibility is what lets them see and translate the structural analogy across.',
    attr: 'Lossy, Ch. 9', source: 'content/integration-problem.md',
  },
  channel: {
    text: 'Adding a channel between distrustful communities can accelerate divergence, not reconcile it.',
    attr: 'Lossy, Ch. 9', source: 'content/integration-problem.md',
  },
  audit: {
    text: 'an institution whose reasoning and evidence are published can be partially trusted by doubters who verify the parts that matter to them',
    attr: 'Lossy, Ch. 12', source: 'content/infrastructure-for-integration.md',
  },
};

export const COPY = {
  intro: {
    kicker: 'A game from Lossy · part four',
    title: 'The Bridge',
    body: 'You hold a finding two towns both need, and the towns do not trust each other. Choose who carries it to each town, how it is framed, and how the towns talk afterwards.',
    findingLabel: 'Your finding',
    button: 'Go to the first town',
  },
  town: {
    heading: '{name}',
    heard: 'Overheard in the town hall',
    pick: 'Who carries the finding to {name}?',
  },
  framing: {
    heading: 'How does {messenger} put it?',
    back: 'Choose a different messenger',
  },
  reaction: {
    heading: 'How {name} took it',
    next: 'Next town',
    last: 'Decide how the towns talk',
  },
  connect: {
    heading: 'Ten years is a long time',
    body: 'Both towns will keep hearing about the river. How should they talk about it from here?',
    cards: 'New cards',
  },
  epilogue: {
    heading: 'Ten years on',
    town: '{name}, ten years on',
    both: 'Both towns read the river the same way, and roughly right.',
    notBoth: 'The towns do not read the river the same way.',
    cards: 'New cards',
    button: 'Finish',
  },
  end: {
    heading: 'What you carry out',
    carry: [
      'Who would this audience hear it from, and is that person a peer there?',
      'Am I leading with the half of the truth this audience will flip?',
      'Can a skeptic check it without having to trust me?',
    ],
    cutHeading: 'What this game cut',
    cut: [
      'Lowmill, Ridgeton, Ana, Sam and Jules are invented. Compound X is the book’s made-up example.',
      'Real towns are not of one mind, and real bridges take years to build, not one choice.',
      'The ten-year outcomes are fixed to show the book’s argument. The research behind them is modelling, not a forecast.',
    ],
    replay: 'Build the bridge again',
    links: [
      { label: 'Back to Courier', href: './' },
      { label: 'The Reader', href: './reader.html' },
      { label: 'Read Chapter 9', href: '../integration-problem' },
      { label: 'Read Chapter 12', href: '../infrastructure-for-integration' },
    ],
  },
};
