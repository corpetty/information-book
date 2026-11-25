"""Simulation 6, materials. Eight invented findings, each in two variants A and B.

Both variants of a topic share the same bare claim and differ only in their three scope
conditions (who it was shown for, how strong the evidence is, how big or how limited the
effect is). So a reader can tell which variant a retelling came from only through a scope
condition that survived. The findings are made up for the experiment; none is a real result.

Half the items state the claim first and half state the conditions first, balanced across
topics and variants.
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))

TOPICS = [
    ("A daily twenty-minute walk lowers blood pressure.",
     ["The study only included adults over 65.",
      "It was a small trial of 48 people that ran for six weeks.",
      "The drop was about 3 points, and only in people not taking medication."],
     ["The study only included office workers under 40.",
      "It was a survey of 12,000 people, so it cannot show cause.",
      "The drop was about 11 points, and only in people who also cut down on salt."]),
    ("Drinking coffee improves memory.",
     ["So far this has only been tested in mice.",
      "The dose was the equivalent of eight cups a day.",
      "The effect wore off after about two hours."],
     ["So far this has only been tested in university students.",
      "It only showed up after a night without sleep.",
      "The improvement was 2 percent on a single word-list test."]),
    ("Working from home raises productivity.",
     ["The evidence comes from one call-centre company in China.",
      "Only staff who volunteered to work from home were included.",
      "The gain was 13 percent and came mostly from taking fewer breaks."],
     ["The evidence comes from software teams at three start-ups.",
      "Productivity was measured by asking people to rate themselves.",
      "The gain had disappeared after six months."]),
    ("The new bridge has cut commuting times.",
     ["This holds only for drivers coming from the north side.",
      "The measurements were taken during the school holidays.",
      "The saving averages four minutes."],
     ["This holds only for bus passengers.",
      "The comparison year was one with major roadworks.",
      "The saving averages twenty minutes."]),
    ("Vitamin D supplements prevent colds.",
     ["The benefit was found only in people who were deficient to begin with.",
      "It comes from pooling 25 small trials of mixed quality.",
      "It amounts to one fewer cold a year for every 30 people."],
     ["The benefit was found only in children under five.",
      "It comes from a single trial paid for by a supplement maker.",
      "It was seen only in the winter months."]),
    ("The reading app helps children learn to read.",
     ["The children in the study already had a private tutor.",
      "The app was tested for four weeks.",
      "It improved letter recognition but not understanding of stories."],
     ["The children in the study were learning English as a second language.",
      "The app was compared with no teaching at all.",
      "The gains had faded by the next school year."]),
    ("The pesticide harms bees.",
     ["This was observed in laboratory colonies.",
      "The doses were ten times what bees meet in fields.",
      "It shortened foraging trips but did not kill colonies."],
     ["This was observed in bumblebees, not honeybees.",
      "The study covered one season in two English counties.",
      "Colonies produced a quarter fewer queens."]),
    ("A four-day week reduces burnout.",
     ["The firms in the trial had all volunteered for it.",
      "There was no comparison group.",
      "Weekly hours only fell from 38 to 34."],
     ["The trial was run in public-sector offices in Iceland.",
      "Pay was kept the same throughout.",
      "The number of sick days did not change."]),
]


def text(topic, variant):
    """variant is 'A' or 'B'. Claim first for (even topic, A) and (odd topic, B)."""
    claim, a, b = TOPICS[topic]
    caveats = a if variant == "A" else b
    claim_first = (topic % 2 == 0) == (variant == "A")
    parts = [claim] + caveats if claim_first else caveats + [claim]
    return " ".join(parts), claim_first


def materials():
    out = []
    for t in range(len(TOPICS)):
        for v in "AB":
            txt, cf = text(t, v)
            claim, a, b = TOPICS[t]
            out.append({"topic": t + 1, "variant": v, "claim_first": cf, "text": txt,
                        "claim": claim, "caveats": a if v == "A" else b})
    return out


if __name__ == "__main__":
    mats = materials()
    json.dump(mats, open(os.path.join(HERE, "llm", "materials.json"), "w"), indent=1)
    for line in ("A1", "A2", "B1", "B2"):
        d = os.path.join(HERE, "llm", "runs", line)
        os.makedirs(d, exist_ok=True)
        items = [{"id": f"t{m['topic']}", "text": m["text"]} for m in mats if m["variant"] == line[0]]
        json.dump(items, open(os.path.join(d, "h0.json"), "w"), indent=1)
    words = [len(m["text"].split()) for m in mats]
    print(len(mats), "originals; words min/mean/max:", min(words), sum(words) / len(words), max(words))
