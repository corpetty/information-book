---
title: The Three Layers of a Message
description: "Every message has three parts: the signal that says 'this is a message', the key for reading it, and the content. What gets lost in transit is almost always the key, which is why true claims so often arrive and get read wrong."
aliases:
  - three layers of a message
  - frame outer inner message
  - outer message
  - Hofstadter location of meaning
  - GEB three-layer
tags:
  - information
---

I once [[ethical-infrastructure-talk|gave a talk]] on building public-good infrastructure and borrowed a model from Douglas Hofstadter's [[godel-escher-bach|*Gödel, Escher, Bach*]] to make a point about how messages get manipulated. I keep coming back to it, and it belongs in this book as load-bearing machinery rather than a borrowed illustration. Hofstadter's question in GEB (Chapter VI, "The Location of Meaning") is whether a message carries its meaning intrinsically or whether meaning is something the receiver supplies, and to get at it he decomposes any message into three layers.

## The model

**The frame message** is the information that there is a message here at all: "I am a message, decode me if you can." You don't read it; you recognize it. It is carried implicitly in the structure of the thing, the regularity that says *something here is not noise*. To grasp the frame message is to recognize that a decoding mechanism is needed.

**The outer message** is the information about *how* to decode: the knowledge a receiver needs to extract the content. It is not the content; it is the key, and it is usually implicit, inferred from the message's own patterns or already known. To grasp the outer message is to hold, or be able to build, the correct decoding mechanism.

**The inner message** is the content, what the sender was actually trying to convey.

The [[voyager-golden-record|Voyager Golden Record]] is the cleanest illustration of the model, because it had to carry all three layers physically, with no recipient and no shared context to assume. The recorded sounds and images are the inner message; the cover, etched with diagrams showing how to build a player and at what speed to run it, is the outer message travelling alongside the content; and the artifact itself, a manufactured object of evident regularity that any finder would know was made to be understood, is the frame message. It is the rare case where all three had to be shipped together. Most messages don't do that.

## The outer message is preconditions

Most messages do not carry their own outer message; they assume it. A physics paper assumes you can already read physics; a meme assumes you already share the cultural reference. The outer message, in almost every real case, is *not in the message*. It is pre-installed in the receiver, or it isn't.

**The outer message is the decoding mechanism a receiver must already hold, and that is exactly what this book has been calling preconditions.** When [[complexity-virality-tradeoff|Chapter 5]] defines the complexity of an idea as the number of preconditions a receiver needs to have already internalized, it is describing the size of the idea's outer message. A complex idea has a large or rare outer message; a compressed idea has one so common it decodes with the receiver's default equipment.

And where does a receiver get an outer message they don't already have? Mostly from the medium. A peer-reviewed journal supplies, through its whole apparatus, the decoding instructions for its inner messages: read skeptically, check the methods, treat the conclusion as provisional. A social feed supplies a different one: react fast, the salient thing is the emotional charge. [[medium-and-manipulation|The medium note]] argued the medium is the selection criteria; the GEB framing says the same thing from the receiver's side. Only *mostly*, though: some of the outer message is pre-installed by the receiver's own training, and a well-written piece teaches you how to read it as you go. The honest version is that the outer message is distributed across medium, receiver, and message body, and the real question is which share sits where.

## What this reframes: transit loss

The pipeline is a sequence of re-encodings, and the standard worry is that the inner message degrades, blurry hop after blurry hop. That happens, but it is not the main thing. **What a lossy hop usually strips is the outer message, not the inner one.** The inner message (the claim, the finding, the number) is small and survives; what falls away is the decoding mechanism that came with it, the qualifications, the scope conditions, the "this is provisional." A twenty-year research program arrives downstream as "scientists say X." The inner message "X" is intact; the outer message, *how to decode a scientific finding*, is gone.

The receiver does not then fail to decode. They decode anyway, with whatever outer message they do have, applying their default (*a stated fact is a settled fact*) and extracting an inner message the sender never sent. The content survived transit and was still received wrong, because the key didn't survive with it. That is a sharper account of distortion than "the signal degrades": the signal often arrives fine, and a true inner message decoded with the wrong key produces a false belief just as reliably as a corrupted one does.

## Manipulation and manufactured content

The three layers give two precise definitions the book needs. **Manipulation is most efficient as a corruption of the outer message, not a lie about the inner one.** A lie about the inner message is a false claim, checkable against the world. Corrupting the outer message is quieter: you hand the receiver a wrong decoding mechanism, and they then extract false inner messages from true signals on their own, repeatedly, with no further help from you. Propaganda that teaches you to read every institutional statement as a coded admission of guilt has not told you a single lie. It has installed an outer message, and after that the inner messages take care of themselves.

And **manufactured content forges the frame message.** [[astrology|Astrology]], and [[manufactured-injection|injected content]] of all kinds, presents the structure of a real message ("here is information about your life, decode it") when nothing was ever encoded. The frame says *a mind measured something and sent it*, and for manufactured content that is a forgery: the receiver recognizes the frame, reaches for a decoding mechanism, and extracts an inner message that was never put in.

## Where I land

The three-layer model is not a competitor to the [[transport-vs-selection|transport and selection]] pipeline; it is an anatomy of the thing moving through it. Transport and selection tell you what happens *to* a message at each hop; the three layers tell you what is *in* a message and therefore what can be lost, forged, or corrupted. The sentence to carry forward: **a message can survive transit and still be received wrong, because the inner message and the outer message travel separately, and the outer message is the more fragile of the two.** Most of what this book calls distortion is outer-message loss.

## Where I'm still uncertain

- **"The outer message lives in the medium" is only mostly right.** Some of it is in the medium, some in the receiver's prior training, some carried in the message body. The honest version is that it is distributed, and the real question is which share sits where.
- **The three layers may not stay cleanly separable for manufactured content.** I said manufactured content forges the frame message, but it also fakes an outer message, telling you how to "decode" it. Forging one may force forging all three.
- **Hofstadter's question is not mine.** He built the model to argue meaning is *partly intrinsic*, that a universal enough decoding scheme makes some inner messages recoverable by any intelligence. I use it for a narrower thing, an anatomy of transit loss, and should not import his optimism about intrinsic meaning where the book's pipeline is full of messages whose outer message is deeply contingent.

