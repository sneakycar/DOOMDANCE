export function personName(firstName, surnameOrLast) {
  return `${firstName || ""} ${surnameOrLast || ""}`.trim();
}

export function formatTimelineText(entry) {
  const name = personName(entry.firstName, entry.surname);
  const trimmed = (entry.text || "").trim();
  if (entry.isBirth) return `${name} was born.`;
  if (/^You /i.test(trimmed)) return trimmed.replace(/^You /i, `${name} `);
  if (/^you /i.test(trimmed)) return trimmed.replace(/^you /i, `${name} `);
  return trimmed;
}

export function birthTimelineEntry(life, atMs = Date.now()) {
  const name = personName(life.firstName, life.surname);
  return {
    id: crypto.randomUUID(),
    lifeId: life.id,
    firstName: life.firstName,
    surname: life.surname,
    text: `${name} was born.`,
    age: 0,
    timestamp: atMs,
    isBirth: true,
    isDeath: false,
    isRead: true,
  };
}

export function timelineEntryFromRecord(life, record) {
  return {
    id: record.id,
    lifeId: life.id,
    firstName: life.firstName,
    surname: life.surname,
    text: record.text,
    age: record.age ?? record.ageYears ?? life.currentAge ?? 0,
    timestamp: record.timestamp ?? Date.now(),
    isBirth: false,
    isDeath: !!(record.isDeath || record.isDeathEvent),
    isRead: record.isRead ?? false,
  };
}

export function appendTimelineEntry(save, entry) {
  if (!save.timeline) save.timeline = [];
  save.timeline.push(entry);
  return entry;
}

export function groupTimelineByLife(entries) {
  const chapters = [];
  for (const entry of entries) {
    const last = chapters[chapters.length - 1];
    if (!last || last.lifeId !== entry.lifeId) {
      chapters.push({
        lifeId: entry.lifeId,
        firstName: entry.firstName,
        surname: entry.surname,
        entries: [entry],
      });
    } else {
      last.entries.push(entry);
    }
  }
  return chapters;
}

export function groupEntriesByAge(entries) {
  const groups = new Map();
  for (const entry of entries) {
    const age = entry.age ?? 0;
    if (!groups.has(age)) groups.set(age, []);
    groups.get(age).push(entry);
  }
  return [...groups.entries()]
    .sort((a, b) => a[0] - b[0])
    .map(([age, rows]) => ({
      age,
      rows: rows.sort((a, b) => a.timestamp - b.timestamp),
    }));
}

export function rebuildTimelineFromSave(save) {
  if (save.timeline?.length) return save.timeline;

  const timeline = [];
  const obits = [...(save.obituaries || [])].reverse();
  for (const ob of obits) {
    const parts = (ob.fullName || "Unknown Person").split(" ");
    const firstName = parts[0] || "Unknown";
    const surname = parts.slice(1).join(" ") || "Person";
    timeline.push({
      id: crypto.randomUUID(),
      lifeId: ob.lifeId,
      firstName,
      surname,
      text: `${ob.fullName} was born.`,
      age: 0,
      timestamp: ob.bornAt ?? ob.archivedAt ?? Date.now(),
      isBirth: true,
      isDeath: false,
      isRead: true,
    });
    for (const record of ob.events || []) {
      timeline.push({
        id: record.id,
        lifeId: ob.lifeId,
        firstName,
        surname,
        text: record.text,
        age: record.age ?? record.ageYears ?? 0,
        timestamp: record.timestamp ?? ob.archivedAt ?? Date.now(),
        isBirth: false,
        isDeath: !!(record.isDeath || record.isDeathEvent),
        isRead: true,
      });
    }
  }

  const life = save.activeLife;
  if (life?.events?.length) {
    const hasBirth = timeline.some((e) => e.lifeId === life.id && e.isBirth);
    if (!hasBirth) {
      timeline.push(birthTimelineEntry(life, life.bornAt ?? Date.now()));
    }
    for (const record of life.events) {
      if (timeline.some((e) => e.id === record.id)) continue;
      timeline.push(timelineEntryFromRecord(life, { ...record, isRead: record.isRead ?? true }));
    }
  }

  save.timeline = timeline;
  return timeline;
}
