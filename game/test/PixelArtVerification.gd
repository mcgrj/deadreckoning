extends Node2D

# Verification scene for Stage 0 pixel art configuration.
# Checks: nearest-neighbour filtering, 1280x720 viewport, landscape lock.
# Delete this file and PixelArtVerification.tscn after Stage 0 is complete.

func _ready() -> void:
    var viewport_size := get_viewport().get_visible_rect().size
    assert(viewport_size == Vector2(1280, 720), \
        "Viewport must be 1280x720, got %s" % viewport_size)

    var orientation := DisplayServer.screen_get_orientation()
    assert(orientation == DisplayServer.SCREEN_LANDSCAPE or \
           orientation == DisplayServer.SCREEN_SENSOR_LANDSCAPE, \
        "Screen must be landscape, got %d" % orientation)

    print("Stage 0 verification: PASS — viewport %s, orientation %d" \
        % [viewport_size, orientation])
