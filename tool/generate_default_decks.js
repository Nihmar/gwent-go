// Generates lib/core/data/default_decks.dart from the reference premade decks.
global.window = global;
eval(require('fs').readFileSync('gwent-classic-enhanced/cards.js','utf8'));
eval(require('fs').readFileSync('gwent-classic-enhanced/decks.js','utf8') + '; globalThis.premade_deck = premade_deck;');

const names = ['Foltest Siege', 'Foltest Command', 'Emhyr Control', 'Emhyr White Flame', 'Eredin Muster', 'Eredin Rebirth', 'Francesca Hope', 'Francesca Daisy', 'Crach An Craite', 'Crach Storm'];
const facMap = { realms: 'CardFaction.realms', nilfgaard: 'CardFaction.nilfgaard', monsters: 'CardFaction.monsters', scoiatael: 'CardFaction.scoiatael', skellige: 'CardFaction.skellige' };

// pick one deck per faction (prefer the variant that uses the leader shown in the mockup when possible)
const picks = [];
const seen = new Set();
premade_deck.forEach((s, i) => {
  const d = JSON.parse(s);
  if (seen.has(d.faction)) return;
  seen.add(d.faction);
  picks.push({ i, d, name: names[i] });
});

const lines = picks.map(({ i, d, name }) => {
  const counts = d.cards.map(([idx, n]) => `'${card_dict[idx].filename}': ${n}`).join(', ');
  const strength = d.cards.reduce((a, [idx, n]) => a + Number(card_dict[idx].strength || 0) * n, 0);
  const total = d.cards.reduce((a, [, n]) => a + n, 0);
  return `  DeckBlueprint(\n    id: '${d.faction}_starter',\n    name: "${name}",\n    faction: ${facMap[d.faction]},\n    leaderId: '${card_dict[d.leader].filename}',\n    cardCounts: {\n      ${counts},\n    },\n  ), // ${total} cards, ${strength} strength`;
}).join('\n\n');

const header = `// GENERATED FILE — do not edit by hand.
//
// Default decks derived from the reference implementation's premade decks.
// Regenerate with tool/generate_default_decks.js.

import '../models/card.dart';

/// A deck described without resolving card definitions; [CardRepository]
/// turns blueprints into [DeckDefinition] instances.
class DeckBlueprint {
  const DeckBlueprint({
    required this.id,
    required this.name,
    required this.faction,
    required this.leaderId,
    required this.cardCounts,
  });

  final String id;
  final String name;
  final CardFaction faction;
  final String leaderId;
  final Map<String, int> cardCounts;
}

/// One ready-made deck per playable faction.
const List<DeckBlueprint> defaultDeckBlueprints = [
`;

require('fs').writeFileSync('lib/core/data/default_decks.dart', header + lines + '\n];\n');
console.log('wrote', picks.length, 'decks');
picks.forEach(p => console.log(' ', p.d.faction, p.name));
