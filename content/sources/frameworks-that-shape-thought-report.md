---
title: "Frameworks That Shape the Thoughts Built Inside Them (research report)"
tags:
  - source
  - research-report
---

> *A research report on how frameworks bias the thinking done inside them, filed here as a source. It is a literature survey: every claim in it is relayed from the works listed under Sources at the end, and the book treats it as secondhand until those works are read directly. The book's own use of it is in [[thinking-inside-frameworks]].*

# Frameworks That Shape the Thoughts Built Inside Them: Named Concepts, Mechanisms, and a Catalog of Examples

The idea is real and has been named many times over. Scholars in linguistics, philosophy of science, psychology, sociology of measurement, economics, software engineering and machine learning have each described how a human-made framework (a language, notation, metaphor, classification, model, metric, tool or organization) makes some thoughts cheap and others expensive, so that conclusions reached inside it carry the framework's shape. The strongest evidence comes from cases where the framework is easy to swap: survey wording, prompt formatting, measurement targets, financial models and team structures. The weakest evidence comes from claims that a natural language fixes what its speakers *can* think. Across fields, the dependable result is a weak but measurable bias toward whatever the framework makes easy, visible or rewarded. Claims that a framework imprisons thought do not hold up.

## TL;DR

- The concept has no single name. It is a family: linguistic relativity, theory-ladenness and paradigms, framing effects, conceptual metaphor, the law of the instrument, Goodhart's and Campbell's laws, classification "torque", legibility, performativity, Conway's law, path dependence and inductive bias. Each names the same basic move in a different domain: the framework sets the default, and defaults drive outcomes.
- The best-documented examples are Tversky and Kahneman's disease-problem framing (replicated in 31 of 36 Many Labs samples), the Black-Scholes-Merton model reshaping option prices until the 1987 crash, NASA's PowerPoint "engineering by viewgraph" before the Columbia loss, German "scientific forestry" monocultures, apartheid race classification, MacCormack et al.'s evidence that software architecture mirrors organization structure, and LLM accuracy swinging by up to 76 points on meaning-preserving prompt reformatting.
- Strong versions are mostly false. Pirahã speakers match exact quantities without number words, Boroditsky's 2001 time-metaphor finding failed six replication attempts by January and Kako (Cognition, 2007), and the QWERTY lock-in story is disputed. The practical defense is to treat every framework as one lens among several: use multiple models and notations, report results across framings, separate measures from targets, and red-team the categories themselves.

## Key Findings

1. **The general concept is "framework-dependence" or "representational bias".** A framework does four things. It sets defaults (what is assumed unless overridden), changes costs (some operations become cheap, others laborious), controls visibility (what can be recorded, counted or drawn), and in social settings feeds back on the world, so the reality it describes moves toward or away from it.
2. **Effects are graded.** Empirical work supports *influence*, meaning faster, easier or default routes of thought. It rarely supports *determinism*. Pirahã speakers, who lack number words, still matched large exact quantities when objects were in view.\[1\] Russian speakers' faster blue discrimination disappeared under verbal interference.\[2\]
3. **Feedback loops are where the bias becomes most consequential.** When people act on a framework, they can make it truer (Black-Scholes before 1987, monoculture forests "read" from tables) or break it (the post-1987 volatility skew, Waldsterben, metrics corrupted under Goodhart/Campbell pressure).
4. **Countermeasures work by multiplying or rotating frameworks.** Single frameworks fail silently. Disagreement between several frameworks exposes the shape of each.

## Part 1: The Concept Families

### A. Language and notation

**Linguistic relativity (Sapir-Whorf).** This is the hypothesis that the language one speaks influences habitual thought. The "strong" (determinism) and "weak" (influence) split is a later scholarly construction; Sapir and Whorf never set up that dichotomy.\[3\] The modern consensus rejects determinism and accepts domain-specific, often modest effects.\[4\] Three lines of evidence are the strongest:
- *Color.* Russian obligatorily distinguishes lighter blue (goluboy) from darker blue (siniy).\[5\] Winawer et al. (PNAS, 2007) found Russian speakers were faster to discriminate two blues that fell into different Russian categories than two from the same category. The advantage was eliminated by a verbal dual task but not by a spatial one.\[2\] English speakers tested on the same stimuli showed no category advantage.\[6\] The effect is real but "online": it depends on language being active in the moment.\[7\]
- *Space.* Guugu Yimithirr, spoken in northeastern Australia, describes horizontal space almost entirely with cardinal directions rather than left/right.\[8\] Levinson (Journal of Linguistic Anthropology, 1997) showed that Guugu Yimithirr speakers code nonverbal memory in "absolute" terms congruent with their language, while a Dutch comparison group coded in "relative" terms. He concluded that "Whorfian effects may in fact be demonstrable in the spatial domain."\[9\] Majid, Levinson and colleagues later extended this across communities.\[10\]
- *Number.* Pirahã has no stable word even for "one".\[11\] Frank, Everett, Fedorenko and Gibson (Cognition, 2008) found Pirahã speakers matched large exact quantities perfectly when objects stayed visible but were inaccurate on tasks requiring memory. Their conclusion was that number words "do not change our underlying representations of number but instead are a cognitive technology for keeping track of the cardinality of large sets across time, space, and changes in modality."\[1\] This is the clearest statement of the weak position: the framework is a tool that extends some capacities. It is not a cage.

**Wittgenstein's "The limits of my language mean the limits of my world"** (Tractatus 5.6) is the philosophical slogan for the strong form. Empirical work generally supports a softer reading.

**Notation as a tool of thought.** Kenneth Iverson's 1979 Turing Award lecture opens: "The importance of nomenclature, notation, and language as tools of thought has long been recognized." He argued that "If it is to be effective as a tool of thought, a notation must allow convenient expression not only of notions arising directly from a problem, but also of those arising in subsequent analysis, generalization, and specialization."\[12\] He also identified a framework-feedback loop in computing: "early programming languages reflected the characteristics of the early computers, and each generation of computers reflects the needs of the programming languages of the preceding generation."\[13\] Paul Graham's "Blub paradox" (2001) is the programmer's version: someone fluent only in a mid-power language cannot see what more expressive languages offer, because they think in their own language's constructs.

**Conceptual metaphor (Lakoff and Johnson, *Metaphors We Live By*, 1980).** This theory holds that abstract domains are structured by metaphors from concrete ones (ARGUMENT IS WAR, TIME IS MONEY), and that the metaphor shapes inference. The best-known experimental test is Thibodeau and Boroditsky (PLOS ONE, 2011).\[14\] Participants who read that crime was a "beast" preying on a city favored enforcement more than those who read it was a "virus" infecting the city, even though both groups saw the same statistics.\[15\] The effect depended on the metaphor appearing early, where it could organize incoming information.\[16\] Steen, Reijnierse and Burgers (2014) argued that the effect was smaller than claimed and sensitive to coding choices.\[15\]\[17\] A German-language replication published in *Scientific Data* (2016) did reproduce it.\[18\]

**McLuhan's "the medium is the message"** (*Understanding Media*, 1964). This is the claim that the form of a communication technology restructures thought and social relations independently of content. Tufte's critique of PowerPoint (below) is its most concrete modern application.

### B. Theory, paradigm and observation

**Theory-ladenness of observation (Hanson, *Patterns of Discovery*, 1958).** What a scientist "sees" depends on the conceptual background brought to the observation. **Kuhn's paradigms** (*The Structure of Scientific Revolutions*, 1962) extend this to whole communities. Normal science solves puzzles that the paradigm defines as legitimate, and anomalies are set aside until a crisis forces a revolution. **Duhem-Quine underdetermination** adds that evidence never tests a hypothesis alone, only a bundle of hypotheses and auxiliary assumptions. The framework therefore determines which part of the bundle gets blamed when a prediction fails. This is the logic behind the Ptolemaic system's long survival: adding epicycles was always an available repair. **Foucault's episteme** (*The Order of Things*, 1966) is the historical-structural version. Each era has an unspoken set of conditions that decides what can count as knowledge at all.

### C. Framing, cognitive set and tools

**Framing effects (Tversky and Kahneman, *Science*, 1981).** In the "Asian disease problem", 72% of subjects chose the certain program when outcomes were described as lives saved, while 78% chose the risky program when the identical outcomes were described as lives lost.\[19\] **Goffman's *Frame Analysis*** (1974) is the sociological ancestor: the interpretive "frames" that tell people what kind of situation they are in.

**Einstellung effect and functional fixedness.** A known solution method blocks the search for better ones (Luchins's water-jar problems, 1942). Seeing an object only in its conventional role blocks its use in a new one (Duncker's candle problem). Bilalić, McLeod and Gobet (Cognition, 2008) showed this in chess experts. After finding a familiar solution, players said they were searching for a better one, but their eye movements kept returning to board regions tied to the familiar solution.\[20\]\[21\] Sheridan and Reingold (PLOS ONE, 2013) found a boundary condition: when the familiar move was an outright blunder rather than merely suboptimal, all of the experts avoided it.\[22\]\[23\]

**Law of the instrument / Maslow's hammer.** Maslow (*The Psychology of Science*, 1966) wrote: "it is tempting, if the only tool you have is a hammer, to treat everything as if it were a nail." The **streetlight effect** is its measurement cousin: people search where it is easy to look, not where the answer is.

### D. Measurement, classification and legibility

**Goodhart's law.** Charles Goodhart's original 1975 wording, in a paper on UK monetary management, was: "Any observed statistical regularity will tend to collapse once pressure is placed upon it for control purposes."\[24\] The famous aphorism "When a measure becomes a target, it ceases to be a good measure" is Marilyn Strathern's generalization in a 1997 paper on British university audit (*European Review*, p. 308). She credited the "Goodhart's law" label to Keith Hoskin\[25\] and added that "measuring the improvement leads to improving the measures."\[26\]

**Campbell's law.** Donald T. Campbell, "Assessing the impact of planned social change" (*Evaluation and Program Planning*, 1979, p. 85): "The more any quantitative social indicator is used for social decision-making, the more subject it will be to corruption pressures and the more apt it will be to distort and corrupt the social processes it is intended to monitor."\[27\]

**Classification and "torque" (Bowker and Star, *Sorting Things Out*, 1999).** Bowker and Star treat classification systems as infrastructure: invisible when they work, consequential for everyone sorted by them.\[28\] Their term **torque** names "a twisting of time lines that pull at each other, and bend or twist both patient biography and the process of metrication," a mismatch in which "Lives are twisted, even torn, in the attempt to force the one into the other."\[29\] They also note: "Politically and socially charged agendas are often first presented as purely technical and they are difficult even to see."\[30\]

**Legibility (James C. Scott, *Seeing Like a State*, 1998).** Scott describes the state's effort "to make a society legible, to arrange the population in ways that simplified the classic state functions of taxation, conscription, and prevention of rebellion." State simplifications are "rather like abridged maps," but maps that, "when allied with state power, would enable much of the reality they depicted to be remade."\[31\] Legibility is the mechanism through which a framework stops describing reality and starts reshaping it.\[32\]

**Looping effects (Ian Hacking, "making up people").** Human kinds differ from natural kinds because the people classified respond to their classification. This changes the people and therefore the category itself.

### E. Models, maps and performativity

**"The map is not the territory" (Korzybski, *Science and Sanity*, 1933)** and **reification** (treating an abstraction as a concrete thing) warn against confusing the representation with what it represents. **George Box's "all models are wrong"** (1976; the "but some are useful" form appears in 1979) is the working modeler's version. **Taleb's ludic fallacy** (*The Black Swan*, 2007) is the error of treating real-world uncertainty as if it had the tidy structure of games and textbook distributions. **Model risk** is the financial-regulatory name for losses caused by decisions based on flawed or misapplied models.

**Performativity of economics (Donald MacKenzie, *An Engine, Not a Camera*, 2006).** MacKenzie argues that financial models are engines that shape markets, not cameras that record them. His strongest category is "Barnesian performativity", where using a model makes reality more like the model.\[33\] He is careful to deny the crude version: it "is not to make the crude claim that any arbitrary formula for option prices, if proposed by sufficiently authoritative people, could have 'made itself true' by being adopted."\[34\] **Counterperformativity** is the reverse, where use of a model makes reality less like it.\[35\]

### F. Organizational structure and lock-in

**Conway's law** (Melvin Conway, "How Do Committees Invent?", 1968): systems mirror the communication structure of the organizations that design them. Management researchers call this the "mirroring hypothesis".\[36\]\[37\] **Path dependence and lock-in** (Paul David, "Clio and the Economics of QWERTY", 1985; Brian Arthur) describe how early, sometimes arbitrary choices get entrenched by network effects and sunk investment.\[38\] The **Overton window** applies the same logic to politics: the range of policies treated as discussable frames what gets debated at all.

### G. Machine learning: inductive bias

Every learning algorithm needs assumptions beyond the data to generalize at all. Convolutions assume locality and translation invariance, linear models assume additivity, and tokenizers fix the units a language model reasons over. This is the one field where framework-bias is treated as unavoidable and designed deliberately rather than treated as an error. The same field has shown how quickly implicit frameworks (benchmarks, prompt templates) shape both research and model output.

### Comparison table

| Concept | Origin | Framework type | Main claim | Feedback on reality? | Evidence status |
|---|---|---|---|---|---|
| Linguistic relativity | Sapir, Whorf (1920s–40s) | Natural language | Language influences habitual thought | No (cognitive) | Weak form supported in color, space, number; strong form rejected |
| Notation as tool of thought | Iverson (1979); Whitehead | Formal notation | Notation sets what is easy to express and generalize | Indirect | Historical case support; little experimental work |
| Conceptual metaphor | Lakoff and Johnson (1980) | Metaphor | Source domain structures inference | No | Mixed; some framing effects replicate, effect sizes debated |
| Theory-ladenness / paradigms | Hanson (1958), Kuhn (1962) | Scientific theory | Theory shapes observation and legitimate problems | Yes, via research agendas | Philosophical; strong historical case support |
| Episteme | Foucault (1966) | Era-wide knowledge order | Conditions of possibility for knowledge | Yes | Interpretive, not testable in the usual sense |
| Framing effect | Tversky and Kahneman (1981); Goffman (1974) | Description/wording | Equivalent descriptions yield different choices | No | Robustly replicated |
| Einstellung / functional fixedness | Luchins (1942), Duncker (1945) | Learned method | Known solutions block better ones | No | Robust, with boundary conditions |
| Law of the instrument | Maslow (1966), Kaplan (1964) | Tool/method | Tools define the problems seen | Indirect | Anecdotal and observational |
| Goodhart / Campbell | Goodhart (1975), Campbell (1979) | Metric used as target | Targeted indicators degrade and distort | Yes | Widely documented across cases |
| Classification torque | Bowker and Star (1999) | Classification system | Categories twist lives and data to fit | Yes | Historical and ethnographic |
| Legibility | Scott (1998) | State simplification | Simplified maps enable remaking reality | Yes | Historical case studies |
| Looping effects | Hacking (1990s) | Human-kind categories | Classified people change, changing categories | Yes | Philosophical/historical |
| Performativity | MacKenzie (2006) | Economic model | Models shape markets | Yes, both directions | Strong single case (options); generality debated |
| Map ≠ territory / all models wrong | Korzybski (1933), Box (1976) | Any model | Representation is not reality | Warning, not mechanism | Maxim |
| Conway's law | Conway (1968) | Organization chart | Systems mirror communication structure | Yes | Supported in firms; weaker in open collaborations |
| Path dependence | David (1985), Arthur (1989) | Early standard | Early choices lock in | Yes | Concept accepted; QWERTY example disputed |
| Inductive bias | Mitchell (1980) and ML theory | Model architecture | Assumptions required to generalize | Yes, via deployed systems | Formal and empirical |

## Part 2: Mechanisms — How the Bias Gets In

1. **Cost asymmetry.** A framework makes some operations cheap and others costly. Leibniz's *dy/dx* encodes the chain rule and change of variables in its symbols, while Newton's dots do not. A slide format makes bullet hierarchies cheap and sustained argument costly. Over time, people mostly do what is cheap.
2. **Default setting.** The framework provides an unmarked option (a reference point, a category, a prompt template). Framing studies show that defaults steer choices even when the alternatives are logically equivalent.
3. **Visibility and invisibility.** What the framework cannot record drops out of reasoning. Scott's foresters saw saleable wood volume. The underbrush, soil biota and species diversity lay "outside the brackets."\[31\]
4. **Attention capture.** Once a framework supplies a solution, attention stays anchored to it, as the chess eye-tracking data show directly.
5. **Target substitution.** When a measure becomes the objective, effort flows to the measure rather than to what it stood for (Goodhart, Campbell, Strathern).
6. **Feedback onto reality.** People act on the framework's outputs, and the world changes. Sometimes it converges on the framework (Barnesian performativity, Normalbaum forests). Sometimes it diverges (counterperformativity, looping kinds, Waldsterben).
7. **Lock-in.** Training, tooling, standards and coordination make switching costly, so a framework survives after its fit has declined (fluxional notation at Cambridge, arguably QWERTY, the DSM's continued use).

## Part 3: Catalog of Examples

### Mathematics and the natural sciences

- **Leibniz vs. Newton notation and the British lag.** After the priority dispute, British mathematicians kept Newton's fluxional "dot" notation while the Continent built analysis on Leibniz's differentials.\[39\]\[40\] In 1812 Cambridge undergraduates Charles Babbage, John Herschel and George Peacock formed the Analytical Society. Babbage proposed the joking title "The Principles of pure D-ism in opposition to the Dot-age of the University."\[41\]\[42\] Robert Woodhouse had already introduced the Leibniz notation in 1803, Peacock used continental notation in the Tripos examination in 1817, and by about 1830 it was widely adopted.\[43\]\[44\] Historians caution against crediting notation alone. Newton's preference for synthetic geometric methods and the breakdown of exchange after the priority dispute also isolated British mathematics.\[42\] The case is best read as notation plus institutional loyalty to a framework.
- **Feynman diagrams.** David Kaiser's *Drawing Theories Apart* (2005; Pfizer Prize, 2007) traces how postwar theorists "learned to frame their research in terms of the diagrams—and how both the diagrams and their users were molded in the process."\[45\]\[46\] Students learned the diagrams before the formalism. The diagrams then moved into domains Feynman did not intend, such as dispersion relations and Geoffrey Chew's S-matrix "bootstrap" program, which aimed to replace quantum field theory.\[47\]\[48\] One reviewer noted that it is often hard to isolate what the diagrams per se contributed.\[49\] That difficulty is itself characteristic of framework effects.
- **Ptolemaic epicycles.** This is the classic Duhem-Quine case. Within a geocentric framework committed to uniform circular motion, any discrepancy could be absorbed by adding circles, so the framework did not fail on its own terms.
- **Roman vs. Hindu-Arabic numerals.** Place-value notation makes written multiplication and long division routine. Roman numerals push calculation onto the abacus and leave notation for recording. This is Iverson's point about notation and the cost of operations.

### Medicine and psychiatry

- **DSM categories.** On 29 April 2013, weeks before DSM-5 appeared, NIMH Director Thomas Insel wrote in "Transforming Diagnosis" that the DSM's strength is reliability: "The weakness is its lack of validity. Unlike our definitions of ischemic heart disease, lymphoma, or AIDS, the DSM diagnoses are based on a consensus about clusters of clinical symptoms, not any objective laboratory measure."\[50\]\[51\] He announced that "NIMH will be re-orienting its research away from DSM categories" toward the Research Domain Criteria (RDoC).\[51\] The episode shows a classification shaping which research questions get asked and funded. Insel stressed that RDoC was a research framework, not a clinical replacement.\[50\]
- **ICD.** Bowker and Star trace the International Classification of Diseases to Bertillon's late-nineteenth-century list of causes of death.\[52\] Revised "roughly every ten years since the 1890s," it is "not a record of gradually increasing consensus, but a panoply of tangled and crisscrossing classification schemes." Categories appear and vanish with the framework. In their example, by 1930 the scheme distinguished an adult starving to death (misfortune) from a child starving (homicide), and "Death by wolf alone becomes impossible by 1948."\[29\]
- **BMI.** Quetelet's population-statistics index became an individual clinical cutoff. It sorts muscular people as overweight and misses fat distribution, a case of a population framework reified at the individual level.

### Economics and finance

- **Black-Scholes-Merton.** MacKenzie identifies three phases. From 1973 to 1976, market prices fit the model poorly. From 1976 to the summer of 1987, prices converged on the model as traders used it, partly through arbitrage that imposed its pricing. After the October 1987 crash, a persistent "volatility skew" or "smile" appeared.\[53\] Even that departure is "a skew with respect to the Black-Scholes-Merton flat-line relationship between strike price and implied volatility."\[54\] The model's own parameter, implied volatility, became the market's language for pricing options.\[55\]
- **Gaussian copula and 2008.** Felix Salmon's *Wired* article called David Li's Gaussian copula "the formula that killed Wall Street." MacKenzie and Spears (*Social Studies of Science*, 2014), drawing on 114 interviews, qualify that claim.\[56\]\[57\] They identify a "culture of no-arbitrage modelling" in investment banks and show the copula served as shared infrastructure: running it "backwards" yielded "implied correlations," and it gave traders and organizations a common way to agree on values and book profit and loss.\[56\]\[58\]\[59\] The framework shaped coordination as much as it shaped estimates, which made its blind spot (correlation behavior in a housing-wide downturn) systemic.
- **GDP, VaR and other targets.** These are classic Goodhart/Campbell candidates. A single-number summary becomes the object of management, and activity it does not count (unpaid work, tail risk beyond the confidence level) recedes from attention.

### Computing and organizations

- **PowerPoint and Columbia.** During the 2003 Columbia mission, Boeing engineers briefed NASA managers on possible foam-strike damage with slides whose key caveats were buried in nested bullets. The headline read "Review Of Test Data Indicates Conservatism for Tile Penetration," while the test data were for far smaller debris.\[60\] The Columbia Accident Investigation Board's report (p. 191) adopted Edward Tufte's analysis: "It is easy to understand how a senior manager might read this PowerPoint slide and not realize that it addresses a life-threatening situation."\[61\] The Board added that "At many points during its investigation, the Board was surprised to receive similar presentation slides from NASA officials in place of technical reports."\[62\] Tufte called the slide "a PowerPoint festival of bureaucratic hyper-rationalism."\[63\]
- **Conway's law, tested.** MacCormack, Rusnak and Baldwin (*Research Policy*, 2012) compared matched pairs of software products with the same function, one built by a loosely coupled open-source community and one by a tightly coupled firm (for example Linux vs. Solaris, and MySQL vs. Berkeley DB). "In all of the pairs we examine, the product developed by the loosely-coupled organization is significantly more modular than the product from the tightly-coupled organization."\[37\]\[64\] Colfer and Baldwin's review of 142 studies (*Industrial and Corporate Change*, 2016) found that 70% provided strong evidence of mirroring, 22% partial support and only 8% none, but the majority (56%) of descriptive studies of open collaborative projects did not support the hypothesis.
- **Programming paradigms.** Iverson's lecture and Graham's Blub paradox describe the same effect for code. Object-oriented languages encourage decomposing problems into interacting objects. SQL and the relational model encourage set-based thinking and normalization. Spreadsheets encourage grid-shaped, cell-referenced models that hide their formulas.

### Law, bureaucracy and the state

- **Scientific forestry.** Scott (pp. 11–22) describes how Prussian and Saxon foresters, from about 1765 to 1800, used the cone-volume principle to define a standardized tree (*Normalbaum*). They then cleared underbrush, reduced species "often to monoculture", and planted in straight rows. These practices "produced the monocultural, even-age forests that eventually transformed the Normalbaum from abstraction to reality." Diverse forests that had been about three-quarters broadleaf were replaced largely by Norway spruce or Scotch pine. The first rotation grew well, partly by "mining" the soil capital of the old forest. Problems "became painfully obvious only after the second rotation." Scott quotes a source citing production losses of 20 to 30 percent over two or three generations, and "A new term, *Waldsterben* (forest death), entered the German vocabulary to describe the worst cases."\[31\]
- **Apartheid race classification.** Bowker and Star (ch. 6) analyze the 1950 Population Registration Act and Group Areas Act, which "required that people be strictly classified by racial group, and that those classifications determine where they could live and work." Initial sorting derived from the categories checked on 1951 census returns. Criteria were "appearance and general acceptance and repute," enforced with devices such as the "pencil test" in the hair. Appeals averaged 14 months, during which the person "existed in limbo." About 100,000 people applied for reclassification. In 1984 alone, 795 people were reclassified, 518 of them from coloured to white. In one family, one twin was classified as coloured and the other as African.\[30\] This is torque at its most extreme: the framework's categories overrode family, biography and self-identification.

### Cognitive science

The color, spatial-frame and number studies are summarized in Part 1A. Taken together, they show language acting as an attention-and-memory tool with measurable but limited effects.

### AI and large language models

- **Benchmarks shape research agendas.** Raji, Bender, Paullada, Denton and Hanna ("AI and the Everything in the Whole Wide World Benchmark", NeurIPS Datasets and Benchmarks, 2021) argue that the field "valorize[s] a small collection of influential benchmarks" such as ImageNet and GLUE. These serve as stand-ins for "anointed common problems" framed as milestones toward general AI.\[65\]\[66\] Leaderboard gains get read as general progress, which is a construct-validity failure. The benchmarks also play "a critical role orienting research agendas."\[67\]\[68\]
- **Prompt formatting shapes output.** Sclar, Choi, Tsvetkov and Suhr (ICLR 2024) found that several widely used open-source LLMs are "extremely sensitive to subtle changes in prompt formatting in few-shot settings."\[69\] Changes such as separators, spacing and capitalization, with no change in meaning, produced "performance differences of up to 76 accuracy points" for LLaMA-2-13B, with a median spread of 7.5 points and about 10 accuracy points on average across 50+ tasks and several models. They also found that format performance "only weakly correlates between models," which undermines model comparisons made with a single, arbitrarily chosen prompt format. Sensitivity persisted with larger models, more few-shot examples and instruction tuning.\[69\] They recommend reporting performance ranges across plausible formats rather than a single format.\[70\]
- **Tokenization and inductive bias.** A tokenizer decides the units a model sees. Arithmetic and character-level tasks are harder when digits or letters are chunked irregularly, a direct analogue of Roman numerals.

## Part 4: Evidence Quality — What Holds Up and What Is Contested

- **Framing effects: robust.** The Many Labs project (Klein et al., *Social Psychology*, 2014) re-ran the disease problem in 36 independent samples totaling 6,344 participants (27 in laboratories and 9 online; 25 from the US and 11 from other countries). The reversal appeared in 31 of the 36 samples, and none showed the opposite effect. The effect was smaller than in the 1981 original but clearly present. A 2020 survey of 88,181 people in 47 countries (Rachev et al., *PLOS ONE*, 2021) again found it, with size varying by country and by stress level.\[71\]\[72\]\[73\]
- **Linguistic relativity: weak form supported, strong form rejected, specific findings fragile.** Boroditsky's 2001 claim that Mandarin speakers think about time vertically failed six replication attempts by January and Kako (*Cognition*, 2007), who concluded it "provides no support for the Whorfian hypothesis,"\[4\] and four more by Chen (2007).\[74\] A computational analogue of Boroditsky et al.'s grammatical-gender design across nine languages (Kann, arXiv, 2019) also found "evidence against neo-Whorfianism." The Russian-blue and Guugu Yimithirr results are better supported, but the color effect is online and removable. Levinson's spatial findings remain debated over whether ecology, culture or language drives the difference.
- **Metaphor framing: real but smaller and more conditional than early reports.** Thibodeau and Boroditsky's crime-metaphor result was contested by Steen and colleagues and partly vindicated by a German replication.\[18\] Effects depend on early placement and on readers' prior attitudes.\[15\]\[16\]
- **QWERTY: the example is disputed even though path dependence as a concept is not.** Liebowitz and Margolis ("The Fable of the Keys", *Journal of Law and Economics*, 1990) argued that the evidence for Dvorak's superiority is "both scant and suspect"\[75\] and traceable largely to Dvorak himself.\[76\] They distinguish first-, second- and third-degree path dependence, and only the third implies a remediable inefficiency.\[77\] Defenders reply that David never claimed a remediable market failure, and that the early adoption mechanism (third-party typing schools training on QWERTY) went unaddressed.\[38\] Use QWERTY to illustrate coordination lock-in, not proven inefficiency.
- **Performativity: compelling for options, general scope debated.** MacKenzie himself states that consistency with Barnesian performativity "does not *prove* performativity," and that most arbitrary formulas could not have made themselves true.\[34\]\[78\]
- **Gaussian copula: "killed Wall Street" is overstated.** The careful account is that the model was one embedded component of an evaluation culture and a coordination device, not the sole cause of the crisis.\[57\]
- **Conway's law: well supported within firms, less universal across open collaborations,** and the mapping can be deliberately reversed (the "inverse Conway maneuver").\[79\]
- **Calculus notation: a good illustration, but multi-causal.** Notation, geometric method and nationalism all contributed to the British lag.\[40\]\[42\]
- **PowerPoint: official endorsement but n = 1.** The CAIB adopted Tufte's analysis, yet the slide was one factor among organizational causes the Board documented at length.\[80\]

## Recommendations: Countermeasures That Work

1. **Use several frameworks and look for disagreement.** Ensemble methods in forecasting and ML, multiple models in climate science, and triangulation in social science all exploit the same principle: biases specific to one framework do not survive when independent frameworks are combined. Where frameworks disagree, the disagreement shows where each one's shape is driving the result.
2. **Report results across framings, not one.** Follow Sclar et al.'s recommendation for LLM evaluation (report ranges across prompt formats) and apply it elsewhere. Present gains and losses, absolute and relative risk, and multiple chart scales.
3. **Separate measures from targets.** Rotate indicators, keep some measures unpublished or audit-only, and pair every quantitative target with qualitative review, which addresses Campbell's and Goodhart's mechanisms directly.
4. **Change the notation when the problem changes.** The Analytical Society's fix was a notation switch. In software, choose languages and data models that make the critical operations cheap. In briefings, replace slide decks with written technical reports for high-stakes decisions, as the CAIB urged.\[81\]
5. **Red-team the categories, not just the conclusions.** Ask what the classification cannot record, who falls between categories, and what lies "outside the brackets." Bowker and Star's torque and Scott's forestry are the warning cases.
6. **Treat models as engines, and expect feedback.** When a model will be used to act on a system, ask how widespread use will change the system (performativity), as risk managers now do for crowded trades.
7. **Design organizations for the architecture you want.** The inverse Conway maneuver structures teams around the intended system boundaries.
8. **Deliberately reframe and seek out-of-framework input.** Pre-mortems, outsider review and "consider the opposite" prompts counter Einstellung-style capture. The chess data suggest that experts are not immune and may be more confident while captured.
9. **Keep Box's maxim operational.** For every model, document what it assumes, what it omits, where it is known to fail, and what evidence would make it be abandoned.

## Caveats

- Several named concepts (episteme, paradigm, looping effects, legibility) are interpretive frameworks themselves. They are supported by historical case studies rather than controlled experiments and cannot be "replicated" in the psychological sense.
- Psychological effect sizes are often smaller in replications than in original reports. Framing and Einstellung effects are robust. Many linguistic-relativity and metaphor findings are fragile.
- Historical examples (calculus notation, Columbia, the Gaussian copula) are multi-causal. Single-cause stories attributing the outcome to the framework alone overstate the case.
- Some page citations and exact wordings rest on secondary citations: the page number for Campbell's 1979 law, Goodhart's 1975 wording via later reprints, and the page of Bowker and Star's torque definition. Bowker and Star place the ICD's 1893 origin in Paris, while other sources say Chicago.\[52\]\[82\]
- Inductive bias in machine learning is necessary, not a defect. The aim is to choose framework biases deliberately and test against them, not to eliminate them.

## Sources

1. [ERIC - EJ810129 - Number as a Cognitive Technology: Evidence from Piraha Language and Cognition, Cognition, 2008-Sep](https://eric.ed.gov/?id=EJ810129)
2. [Russian Blues Reveal Effects of Language on Color Discrimination @ The Open Buddhist University](https://buddhistuniversity.net/content/articles/russian-blues-reveal-effects-of-language_winawer-jonathan-et-al)
3. [Linguistic relativity](https://en.wikipedia.org/wiki/Linguistic_relativity)
4. [Re-evaluating evidence for linguistic relativity: Reply to Boroditsky (2001) - ScienceDirect](https://www.sciencedirect.com/science/article/abs/pii/S0010027706001582)
5. [Figure 2 from Russian blues reveal effects of language on color discrimination](https://www.semanticscholar.org/paper/Russian-blues-reveal-effects-of-language-on-color-Winawer-Witthoft/fb061d06766e127988316ff17e29822c66322c36/figure/2)
6. [Russian blues reveal effects of language on color discrimination - PubMed](https://pubmed.ncbi.nlm.nih.gov/17470790/?dopt=Abstract)
7. [(PDF) The Russian Blues Reveal Effects of Language on Color Discrimination](https://www.researchgate.net/publication/6358875_The_Russian_Blues_Reveal_Effects_of_Language_on_Color_Discrimination)
8. [The Language With No Word for "Left" or "Right"](https://www.newsbreak.com/nerdy-digest-325136183/4897359584172-the-language-with-no-word-for-left-or-right-only-compass-directions)
9. [Language and Cognition: The Cognitive Consequences of Spatial Description in Guugu Yimithirr - Levinson - 1997 - Journal of Linguistic Anthropology - Wiley Online Library](https://onlinelibrary.wiley.com/doi/10.1525/jlin.1997.7.1.98/abstract)
10. [Can language restructure cognition? The case for space](https://pages.ucsd.edu/~rbelew/courses/cogs1_w10/readings/MajidLevinson04.pdf)
11. [The Pirah\\\~a and the cognitive gap in Frege's theorem: Hume's principle without the #](https://arxiv.org/pdf/2607.05838)
12. [Kenneth E. Iverson - Wikiquote](https://en.wikiquote.org/wiki/Kenneth_E._Iverson)
13. [Ken Iverson Quotations and Anecdotes](https://www.jsoftware.com/papers/KEIQA.htm)
14. [Metaphors We Think With: The Role of Metaphor in Reasoning](http://lera.ucsd.edu/papers/crime-metaphors.pdf)
15. [Metaphorical framing](https://en.wikipedia.org/wiki/Metaphorical_framing)
16. [Do metaphors put us on the right track? : TechCommNZ](https://techcomm.nz/Story?Action=View&Story_id=167)
17. [RESEARCH ARTICLE When Do Natural Language Metaphors](https://pdfs.semanticscholar.org/224f/6a2b027ac5a0cdac56cf25e371986b1bc47d.pdf)
18. [A German-language replication study analysing the role of figurative speech in reasoning](https://www.nature.com/articles/sdata201698)
19. [The Online Laboratory: Conducting Experiments in a Real Labor Market](https://arxiv.org/pdf/1004.2931)
20. [1 COVER PAGE Correspondence address: Merim Bilalić Tübingen University](https://core.ac.uk/download/pdf/336396.pdf)
21. [(PDF) The Mechanism of the Einstellung (Set) Effect: A Pervasive Source of Cognitive Bias](https://www.researchgate.net/publication/247780898_The_Mechanism_of_the_Einstellung_Set_Effect_A_Pervasive_Source_of_Cognitive_Bias)
22. [The Mechanisms and Boundary Conditions of the Einstellung Effect in Chess: Evidence from Eye Movements - PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC3790829/)
23. [The Mechanisms and Boundary Conditions of the Einstellung Effect in Chess: Evidence from Eye Movements](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3790829/)
24. [Goodhart's law - Wikiwand](https://www.wikiwand.com/en/Goodhart's_law)
25. [Goodhart's law](https://aiwiki.ai/wiki/goodharts_law)
26. <https://gwern.net/doc/statistics/decision/1997-strathern.pdf>
27. [Implementing Public Accounts Committee Recommendations: Evidence from the UK Government’s ‘Progress Reports’ since 2012](https://academic.oup.com/pa/article/76/3/662/6532406)
28. [Sorting Things Out: Classification and Its Consequences - Geoffrey C. Bowker, Susan Leigh Star - Google Books](https://books.google.com/books/about/Sorting_Things_Out.html?id=xHlP8WqzizYC)
29. [Sorting Things Out: Classification and Its Consequences](https://museumofdata.org/wp-content/uploads/2019/03/Bowker_and_Star_-_Sorting_Things_Out_Intro.pdf)
30. <https://bpb-us-e1.wpmucdn.com/sites.tufts.edu/dist/d/4865/files/2019/03/Bowker-Star-apartheid.pdf>
31. <http://kokolabs.org/Scott%20-%20Seeing%20Like%20a%20State%20(Intro,%20cp%201-3).pdf>
32. [Seeing Like a State](https://theanarchistlibrary.org/library/james-c-scott-seeing-like-a-state)
33. [mackenzie redux](https://orgtheory.wordpress.com/2007/01/08/mackenzie-redux/)
34. [Donald MacKenzie An Engine, Not a Camera h How Financial Models Shape Markets](https://direct.mit.edu/books/monograph/2002/bookpreview-pdf/2424272)
35. [Deriving the Derivative](https://www.cambridge.org/core/journals/signs-and-society/article/deriving-the-derivative/CE7005B1D8761C321B46A0F5A76C6CCB)
36. [Conway%27s law](https://en.wikipedia.org/wiki/Conway%27s_law)
37. [Exploring the duality between product and organizational architectures: A test of the “mirroring” hypothesis - ScienceDirect](https://www.sciencedirect.com/science/article/abs/pii/S0048733312001205)
38. [Path Dependence](https://eh.net/encyclopedia/path-dependence/)
39. [10 Victoria\\'s Brumous Isles](https://nap.nationalacademies.org/read/11540/chapter/15)
40. [The Calculus Wars. Two brilliant minds — Isaac Newton in…](https://medium.com/@izaakmaine/the-calculus-wars-e7ac64fa006a)
41. [The Calculus Rebellion At Cambridge - Vagelis Plevris](https://vplevris.medium.com/the-calculus-rebellion-at-cambridge-402a235e26dd)
42. [HOW APPLIED MATHEMATICS BECAME PURE](https://www.pgrim.org/philosophersannual/pa28articles/maddyhowapplied.pdf)
43. [MX 7226926 X Contents ABSTRACT](https://repository.mdx.ac.uk/download/4bd7ce22ea6ad72f8458973373c889c304a3bbee9486ba8371ff683634e7bdcc/3441585/Delve_phd.pdf)
44. [Analytical Society](https://en.wikipedia.org/wiki/Analytical_Society)
45. [Drawing Theories Apart: The Dispersion of Feynman Diagrams in Postwar Physics - David Kaiser - Google Books](https://books.google.com/books/about/Drawing_Theories_Apart.html?id=_wz9JZvBt78C)
46. [DrawingTheoriesApart.html](https://web.mit.edu/dikaiser/www/DrawingTheoriesApart.html)
47. [Drawing Theories Apart: The Dispersion of Feynman Diagrams in Postwar Physics: Physics Today: Vol 59, No 11](https://physicstoday.scitation.org/doi/10.1063/1.2435652)
48. [Book Review: Drawing Theories Apart](https://drossbucket.com/2021/07/30/book-review-drawing-theories-apart/)
49. [The Dispersion of Feynman Diagrams in Postwar Physics, ...](https://philarchive.org/archive/SMETWT)
50. [Research Domain Criteria](https://en.wikipedia.org/wiki/Research_Domain_Criteria)
51. [Why Psychiatry's Seismic Shift Will Happen Slowly](https://www.forbes.com/sites/matthewherper/2013/05/08/why-psychiatrys-seismic-shift-will-happen-slowly/)
52. [Sorting Things Out: Classification and Its Consequences](https://www.scribd.com/document/350105847/Sorting-things-out-classification-and-its-consequences)
53. [(PDF) Book Review: Adventures in Financeland An Engine, Not a Camera: How Financial Models Shape Markets by Donald MacKenzie](https://www.researchgate.net/publication/247747472_Book_Review_Adventures_in_Financeland_An_Engine_Not_a_Camera_How_Financial_Models_Shape_Markets_by_Donald_MacKenzie)
54. [IS ECONOMICS PERFORMATIVE? OPTION THEORY AND THE CONSTRUCTION OF](https://gwern.net/doc/economics/2006-mackenzie.pdf)
55. [Full Terms & Conditions of access and use can be found at](https://personal.lse.ac.uk/robert49/teaching/ph232/pdf/MacKenzie-Performative.pdf)
56. [\[PDF\] ‘The formula that killed Wall Street’: The Gaussian copula and modelling practices in investment banking](https://www.semanticscholar.org/paper/%E2%80%98The-formula-that-killed-Wall-Street%E2%80%99:-The-Gaussian-MacKenzie-Spears/85f82bfe25ed2d32e597476307e2bbbb63d68ff6)
57. [The Gaussian Copula and the Financial Crisis - Samuel Watts](https://samueldwatts.com/wp-content/uploads/2016/08/Watts-Gaussian-Copula_Financial_Crisis.pdf)
58. [‘The Formula That Killed Wall Street’:](https://www.sps.ed.ac.uk/sites/default/files/assets/pdf/Formula12.pdf)
59. [‘The Formula That Killed Wall Street’? The Gaussian Copula and the Material](https://mathbabe.org/wp-content/uploads/2012/06/gaussian14.pdf)
60. [ACCIDENT INVESTIGATION BOARD COLUMBIA 1 9 1](https://www.gocivilairpatrol.com/media/cms/Columbiapdf_5161B0B3295B0.pdf)
61. [PowerPoint blows up Space Shuttle](https://vividmethod.com/powerpoint-blows-up-space-shuttle/)
62. [Columbia Accident Investigation Board: The Boeing PowerPoint Slide](https://www.edwardtufte.com/notebook/columbia-accident-investigation-board-the-boeing-powerpoint-slide/)
63. [The perils of PowerPoint at Vermont Yankee - VTDigger](https://vtdigger.org/2010/05/05/the-perils-of-powerpoint-at-vermont-yankee/)
64. [Conway's law](https://www.rabinpoudyal.com/models/conways-law)
65. [AI and the Everything Benchmark](https://www.emergentmind.com/papers/2111.15366)
66. [AI and the Everything in the Whole Wide World Benchmark](https://www.catalyzex.com/paper/ai-and-the-everything-in-the-whole-wide-world)
67. [AI and the Everything in the Whole Wide World Benchmark Inioluwa Deborah Raji](https://ml-retrospectives.github.io/neurips2020/camera_ready/18.pdf)
68. [Raji and Bender challenge the 'general' AI benchmark myth](https://aiweekly.co/alerts/raji-and-bender-challenge-the-general-ai-benchmark-myth)
69. [Published as a conference paper at ICLR 2024](https://arxiv.org/pdf/2310.11324)
70. [Preprint. Under review. QUANTIFYING LANGUAGE MODELS’ SENSITIVITY TO](https://scispace.com/pdf/quantifying-language-models-sensitivity-to-spurious-features-1dd21kndau.pdf)
71. [Replicating the Disease framing problem during the 2020 COVID-19 pandemic: A study of stress, worry, trust, and choice under risk](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8432807/)
72. [Framing effect: Did It Replicate?](https://conyso.com/biases/bias/framing-effect/)
73. [THE FRAMING EFFECT DURING THE COVID-19 PANDEMIC 1](https://www.researchgate.net/profile/Hyemin-Han/publication/347297904_Replicating_the_Disease_framing_problem_during_the_2020_COVID-19_pandemic_A_study_of_stress_worry_trust_and_choice_under_risk/links/5fdcc41992851c13fe9c1d03/Replicating-the-Disease-framing-problem-during-the-2020-COVID-19-pandemic-A-study-of-stress-worry-trust-and-choice-under-risk.pdf)
74. [(PDF) Evidence Against Linguistic Relativity in Chinese and English: A Case Study of Spatial and Temporal Metaphors](https://www.researchgate.net/publication/233613663_Evidence_Against_Linguistic_Relativity_in_Chinese_and_English_A_Case_Study_of_Spatial_and_Temporal_Metaphors)
75. [The Fable of the Keys](https://personal.utdallas.edu/~liebowit/keys1.html)
76. [Battle of the Keys: Why Do We Have QWERTY?](https://janetakesonhistory.org/2021/10/14/battle-of-the-keys-why-do-we-have-qwerty/)
77. [Path dependence — Grokipedia](https://grokipedia.com/page/Path_dependence)
78. [Donald MacKenzie An Engine, Not a Camera h How Financial Models Shape Markets](https://uberty.org/wp-content/uploads/2015/02/MacKenzie-An-Engine-Not-a-Camera.pdf)
79. [Conway's Law: Meaning, Examples & Origin](https://conyso.com/lawtome/laws/conways-law/)
80. [Columbia Accident Investigation Board](https://en.wikipedia.org/wiki/Columbia_Accident_Investigation_Board)
81. [Missing the Point - Government Executive](https://www.govexec.com/magazine/features/2004/09/missing-the-point/17525/)
82. [International Classification of Diseases](https://en.wikipedia.org/wiki/International_Classification_of_Diseases)
