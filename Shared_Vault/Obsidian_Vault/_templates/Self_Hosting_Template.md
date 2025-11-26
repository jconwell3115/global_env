<%*
const newTitle = await tp.system.prompt("Enter a custom title");
if (newTitle) await tp.file.rename(newTitle);

const tagsInput = await tp.system.prompt("Enter additional tags (comma-separated, optional)");
const additionalTags = tagsInput ? tagsInput.split(",").map(tag => tag.trim()).filter(Boolean) : [];
const tagsArray = ["Self-Hosting", ...additionalTags];

function toYAMLList(arr){
  return arr.map(s => JSON.stringify(s)).join(", ");
}

tR += `---
title: ${newTitle || ''}
tags: [${toYAMLList(tagsArray)}]
created: ${tp.date.now("YYYY-MM-DD")}
published:
status: draft
---

`;
%>