global.window = global;
eval(require('fs').readFileSync('gwent-classic-enhanced/cards.js','utf8'));

const rowMap = { close: 'CardRow.close', ranged: 'CardRow.ranged', siege: 'CardRow.siege', agile: 'CardRow.agile', leader: 'CardRow.leader' };
const facMap = { neutral: 'CardFaction.neutral', special: 'CardFaction.special', weather: 'CardFaction.weather', realms: 'CardFaction.realms', nilfgaard: 'CardFaction.nilfgaard', monsters: 'CardFaction.monsters', scoiatael: 'CardFaction.scoiatael', skellige: 'CardFaction.skellige' };

function esc(s){ return s.replace(/\\/g,'\\\\').replace(/"/g,'\\"').replace(/\$/g,'\\$'); }

const out = [];
card_dict.forEach(c => {
  let row;
  if (c.deck === 'weather') row = 'CardRow.weather';
  else if (c.deck === 'special') row = 'CardRow.special';
  else row = rowMap[c.row] || 'CardRow.special';
  const abilities = (c.ability || '').split(' ').filter(Boolean);
  const strength = Number(c.strength || 0);
  const count = Number(c.count || 0);
  const abilStr = abilities.length ? `, abilities: [${abilities.map(a=>`'${a}'`).join(', ')}]` : '';
  const copies = count !== 1 ? `, maxCopies: ${count}` : '';
  out.push(`  CardDefinition(id: '${esc(c.filename)}', name: "${esc(c.name)}", faction: ${facMap[c.deck]}, row: ${row}, baseStrength: ${strength}, artFilename: '${esc(c.deck)}_${esc(c.filename)}'${abilStr}${copies}),`);
});
// stable order: faction group, row, then name
const order = ['realms','nilfgaard','monsters','scoiatael','skellige','neutral','special','weather'];
const rowOrder = ['CardRow.leader','CardRow.close','CardRow.ranged','CardRow.siege','CardRow.agile','CardRow.weather','CardRow.special'];
const recs = card_dict.map(c => {
  let row = c.deck==='weather'?'CardRow.weather':c.deck==='special'?'CardRow.special':(rowMap[c.row]||'CardRow.special');
  return {c, row, fac: c.deck};
});
recs.sort((a,b) => {
  let d = order.indexOf(a.fac) - order.indexOf(b.fac); if(d) return d;
  d = rowOrder.indexOf(a.row) - rowOrder.indexOf(b.row); if(d) return d;
  d = Number(b.c.strength||0) - Number(a.c.strength||0); if(d) return d;
  return a.c.name.localeCompare(b.c.name);
});

const body = recs.map(({c,row,fac}) => {
  const abilities = (c.ability || '').split(' ').filter(Boolean);
  const strength = Number(c.strength || 0);
  const count = Number(c.count || 0);
  const abilStr = abilities.length ? `, abilities: [${abilities.map(a=>`'${a}'`).join(', ')}]` : '';
  const copies = count !== 1 ? `, maxCopies: ${count}` : '';
  return `  CardDefinition(id: '${esc(c.filename)}', name: "${esc(c.name)}", faction: ${facMap[fac]}, row: ${row}, baseStrength: ${strength}, artFilename: '${esc(fac)}_${esc(c.filename)}'${abilStr}${copies}),`;
}).join('\n');

const header = `// GENERATED FILE — do not edit by hand.
//
// Source: the reference implementation's card list (gwent-classic-enhanced).
// Regenerate with tool/generate_card_catalog.js when the reference data changes.
//
// Card ids are the reference artwork file names, which are unique and stable;
// user-facing names are proper nouns and intentionally not localized.

import '../models/card.dart';

/// Every card known to the game, including non-collectible summons.
// dart format off
const List<CardDefinition> allCards = [
`;
require('fs').writeFileSync('lib/core/data/card_catalog.dart', header + body + '\n];\n// dart format on\n');
console.log('wrote', recs.length, 'cards');
