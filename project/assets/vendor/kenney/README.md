# Kenney prototype model kits

These models are prototype authoring assets. They are CC0 1.0 and may be used in
the project, modified, and shipped without attribution.

Sources:

- Graveyard Kit: https://kenney.nl/assets/graveyard-kit
- Fantasy Town Kit: https://kenney.nl/assets/fantasy-town-kit
- Mini Dungeon: https://kenney.nl/assets/mini-dungeon

The original `License.txt` is kept in each subdirectory.

## Runtime contract

- GLB paths are visual choices only.
- Gameplay behavior must continue to depend on `semantic_id`, `kind`,
  `behavior`, `links`, and `params`.
- The GLB instance is added below its semantic host as `VISUAL_<model_id>`.
- `VISUAL_*` nodes must never receive FIVESTAR semantic metadata.
- Replacing a model must not change the semantic host's identity or behavior.

The editor catalog is `res://authoring/assets/model_catalog.json`.
