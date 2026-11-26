shader_type canvas_item;
// Flowing lava that shines by itself: the darkness of the scene (CanvasModulate) does not dim it,
// e.g. the lava streams in the dark goblin castle (see lava.gdshaderinc).
render_mode unshaded;

#include "res://scenes/world/volcano/lava.gdshaderinc"
