---
title: The Three Layers of a Message
tags:
  - information
---

Working note. A few years ago I gave a talk at Devcon on building public-good infrastructure, and I borrowed a model from Douglas Hofstadter's *Gödel, Escher, Bach* to make a point about how messages get manipulated. I've come back to that model repeatedly since, and I now think it belongs in this book as load-bearing machinery rather than a borrowed illustration. This note works out why.

Hofstadter's question in GEB (Chapter VI, "The Location of Meaning") is whether a message carries its meaning intrinsically or whether meaning is something a receiver supplies. To get at it, he decomposes any message into three layers.

## The model

**The frame message** is the information that there is a message here at all. It says, in effect, "I am a message — decode me if you can." You don't read the frame message; you recognize it. It is carried implicitly in the structure of the thing: the regularity, the patterning, the something-here-is-not-noise. To grasp the frame message is to recognize that a decoding mechanism is needed.

**The outer message** is the information about *how* to decode — the knowledge a receiver needs in order to extract the content. It is not the content. It is the key. Hofstadter's point is that the outer message is usually implicit: it has to be inferred from the message's own patterns, or it has to be already known. To grasp the outer message is to hold, or be able to build, the correct decoding mechanism.

**The inner message** is the content — what the sender was actually trying to convey. To grasp the inner message is to have extracted the meaning the sender intended.

Hofstadter's cleanest example is the Voyager Golden Record. It was launched into deep space with no recipient and no shared context to rely on — so it has to carry its own outer message physically. The recorded sounds and images are the inner message. The cover, etched with diagrams showing how to build a player and at what speed to run it, is the outer message — the decoding instructions, travelling alongside the content because nothing about the receiver can be assumed. And the frame message is the artifact itself: a manufactured object of evident regularity that any finder would recognize as something made to be understood. The record is worth dwelling on precisely because it is the rare case where all three layers had to be shipped together. Most messages don't do that.

## The move that earns the model its place

Most messages do not carry their own outer message. They assume it. A physics paper assumes you can already read physics. A meme assumes you already share the cultural reference. The outer message, in almost every real case, is *not in the message* — it is pre-installed in the receiver, or it isn't.

Which is to say: **the outer message is the decoding mechanism a receiver must already hold — and that is exactly what this book has been calling preconditions.** When [[complexity-virality-tradeoff|Chapter 5]] defines the complexity of an idea as "the number of preconditions a receiver needs to have already internalized," it is describing the size of the idea's outer message. A complex idea is one with a large or rare outer message. A compressed idea is one whose outer message is so common it can be assumed in everyone — it decodes with the receiver's default equipment.

And where does a receiver get an outer message they don't already have? From the medium. This is the identification I made in the talk and still think is right: **the outer message lives in the medium.** A peer-reviewed journal supplies, through its whole apparatus, the decoding instructions for its inner messages — read skeptically, check the methods, treat the conclusion as provisional. A social feed supplies a different outer message — react fast, the salient thing is the emotional charge. [[medium-and-manipulation|The medium-and-manipulation note]] argued the medium is the selection criteria; the GEB framing says the same thing from the receiver's side: the medium is where the outer message comes from. Two angles on one fact.

## What this reframes: transit loss

Here is where the model does real work. The pipeline this book describes is a sequence of re-encodings. The standard worry is that the inner message degrades — the content gets blurry, lossy hop after lossy hop. That happens. But it is not the main thing that happens.

**What a lossy hop usually strips is the outer message, not the inner one.** The inner message — the claim, the finding, the number — is small and survives. What falls away is the decoding mechanism that came with it: the qualifications, the scope conditions, the methodology, the "this is provisional" framing, the "this holds only under these assumptions" framing. A twenty-year research program arrives downstream as "scientists say X." The inner message "X" is intact. The outer message — *how to decode a scientific finding* — is gone.

And the receiver does not then fail to decode. They decode anyway, with whatever outer message they do have. They apply their default decoding mechanism — "a stated fact is a settled fact" — and extract an inner message the sender never sent. The content survived transit and was still received wrong, because the key didn't survive with it.

This is a sharper account of pipeline distortion than "the signal degrades." The signal often arrives fine. It is the key that gets lost, and a true inner message decoded with the wrong key produces a false belief just as reliably as a corrupted one does.

## Manipulation and manufactured content

The three layers also give two precise definitions the book needs.

**Manipulation is most efficient as a corruption of the outer message, not a lie about the inner one.** A lie about the inner message is just a false claim, and false claims can be checked against the world. Corrupting the outer message is quieter and harder to catch: you hand the receiver a wrong decoding mechanism, and they then extract false inner messages from true signals on their own, repeatedly, with no further help from you. Propaganda that teaches you to read every institutional statement as a coded admission of guilt has not told you a single lie. It has installed an outer message. After that the inner messages take care of themselves. The closing line of the talk this note comes from was "think about how they can manipulate the intended messages" — corrupting the outer message is the mechanism.

And **manufactured content forges the frame message.** Astrology, and [[the-information-landscape|injected content]] of all kinds, presents the structure of a real message — "here is information about your life, decode it" — when nothing was ever encoded. The frame message says "a mind measured something and sent it." For manufactured content that is a forgery. The receiver recognizes the frame, reaches for a decoding mechanism, and extracts an inner message that was never put in.

## Where I land

The three-layer model is not a competing structure to the [[transport-vs-selection|transport and selection]] pipeline. It is an anatomy of the thing moving through the pipeline. Transport and selection tell you what happens *to* messages at each hop; the three layers tell you what is *in* a message and therefore what, specifically, can be lost, forged, or corrupted at each hop.

The single most useful sentence to carry forward: **a message can survive transit and still be received wrong, because the inner message and the outer message travel separately, and the outer message is the more fragile of the two.** Most of what this book calls distortion is outer-message loss.

## Where I'm still uncertain

- **Is "the outer message lives in the medium" exactly right, or only mostly?** Some of the outer message is in the medium; some is in the receiver's prior training; some is genuinely carried in the message body — a well-written paper teaches you how to read it as you go. The talk's clean identification may be too clean. The honest version might be that the outer message is *distributed* across medium, receiver, and message body, and the real question is which share sits where.
- **Does the frame/outer/inner split survive contact with the manufactured-content case?** I said manufactured content forges the frame message. But it also fakes an outer message — it tells you how to "decode" it. The three layers may not be cleanly separable for manufactured content: forging one may force forging all three.
- **Hofstadter's question is not mine.** Hofstadter built this model to argue that meaning is *partly intrinsic* — that a sufficiently universal decoding scheme (number theory, physics) makes some inner messages recoverable by any intelligence. I am using the model for something narrower: an anatomy of transit loss. I should be careful not to import his optimism about intrinsic meaning where it doesn't belong. The book's pipeline is full of messages whose outer message is deeply contingent, and for those, meaning is not intrinsic at all.
