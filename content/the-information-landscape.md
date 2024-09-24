---
title: Information Landscape Graphic
tags:
  - information
---
![[Pasted image 20240922201821.png]]

```graphviz
digraph {
void [label="The Out There", shape=egg];
data [label="Raw Data"];
insight [label="Insight"];
theory [label="Theory"];
news [label="News/Journalism"];
meme [label="Meme"];

void -> data[label="Measurement"];
data -> insight[label="Analysis"];
insight -> theory[label="Consensus"];
theory -> news[label="Abstraction/Curation"];
news -> meme[label="Abstraction/Emote"];
}
```