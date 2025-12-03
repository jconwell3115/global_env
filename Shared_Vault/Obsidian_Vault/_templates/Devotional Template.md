<%*
const newTitle = await tp.system.prompt("Enter a custom title");
if (newTitle) await tp.file.rename(newTitle);

const tagsInput = await tp.system.prompt("Enter tags (comma-separated)");
const tagsArray = tagsInput ? tagsInput.split(",").map(tag => tag.trim()).filter(Boolean) : [];

const category = await tp.system.prompt("Enter category");

function toYAMLList(arr){
  return arr.map(s => JSON.stringify(s)).join(", ");
}

tR += `---
title: ${newTitle || ''}
tags: [${toYAMLList(tagsArray)}]
category: ${category || ''}
created: ${tp.date.now("YYYY-MM-DD")}
published:
status: draft
---

# ${newTitle || ''}

#### **Scripture Reading:**
- 

**Body**

**Prayer**:

**Further Study**:
`;
%>