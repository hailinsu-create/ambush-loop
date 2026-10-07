extends SceneTree
const Guard := preload("res://scripts/test_storage_guard.gd")
const Hud := preload("res://scripts/touch_hud.gd")
var checks := 0
var failures := 0
var phase_rows: Array=[]
func _init() -> void:
    if not Guard.check():quit(91);return
    call_deferred("_run")
func _check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error("HUD_STYLE_EQ: "+label)
func _properties(box: StyleBox) -> Dictionary:
    var values := {}
    for property: Dictionary in box.get_property_list():
        var key := str(property.name)
        if (int(property.usage)&PROPERTY_USAGE_STORAGE)!=0 and key not in ["resource_path","resource_name","resource_scene_unique_id","script"]:
            values[key]=box.get(key)
    return values
func _styles(b: Button) -> Dictionary:
    var result := {}
    for key: String in ["normal","hover","pressed","disabled"]:
        result[key]=_properties(b.get_theme_stylebox(key))
    result["font_color"]=b.get_theme_color("font_color")
    return result
func _run() -> void:
    root.size=Vector2i(1280,720)
    var hud=Hud.new();root.add_child(hud)
    var oracle:=Button.new();root.add_child(oracle)
    await process_frame
    _check(oracle.has_method("begin_bulk_theme_override") and oracle.has_method("end_bulk_theme_override"),"actual pinned engine bulk API")
    for cmd: String in hud._btns:
        var btn: Button=hud._btns[cmd]
        var tint: Color=btn.get_meta("tint",Color(.4,.4,.36))
        for locked: bool in [false,true]:
            _original_style(oracle,tint,locked)
            hud._apply_btn_style(btn,tint,locked)
            _check(_styles(btn)==_styles(oracle) and btn.modulate==oracle.modulate,"all stored style fields and color/modulate "+cmd+str(locked))
            for key: String in ["normal","hover","pressed","disabled"]:
                _check(btn.get_theme_stylebox(key)!=oracle.get_theme_stylebox(key),"resources stay independently owned "+cmd+key)
    var left: Button=hud._btns.alarm
    var right: Button=hud._btns.clear
    var tint: Color=left.get_meta("tint")
    hud._apply_btn_style(left,tint,false)
    var before: Dictionary=_styles(left)
    var other: Dictionary=_styles(right)
    var retained: StyleBoxFlat=left.get_theme_stylebox("normal")
    retained.bg_color=Color.MAGENTA
    _check(_styles(right)==other,"mutating public button style never changes another button")
    left.add_theme_color_override("font_color",Color.BLUE)
    left.add_theme_stylebox_override("hover",StyleBoxEmpty.new())
    hud._apply_btn_style(left,tint,false)
    _check(_styles(left)==before,"next same-key paint repairs mutable external overrides")
    _check(retained.bg_color==Color.MAGENTA and retained!=left.get_theme_stylebox("normal"),"retained public resource is replaced without mutating it")
    var changed:= [0]
    var on_theme: Callable = func() -> void: changed[0]+=1
    left.theme_changed.connect(on_theme)
    hud._apply_btn_style(left,tint,true)
    var emitted:=int(changed[0]);print("HUD_STYLE_THEME_NOTIFICATIONS=",emitted)
    _check(emitted in [1,5],"original5 or candidate1 theme notifications; count difference explicit")
    left.theme_changed.disconnect(on_theme)
    for phase: String in ["SETUP","SWEEP","WATCHING","FAILED","WON","REPLAY"]:
        for variant: int in 4:
            hud.refresh_phase(phase,variant%2==1,variant>=2,variant%2==1,variant>=2,variant%2==1,variant>=2)
            var values := {}
            for cmd: String in hud._btns:
                var btn: Button=hud._btns[cmd]
                var locked: bool=btn.disabled and cmd in ["fire","pack","trip","nade","decoy","crouch","knife","whistle","bind","pass","door","rotate_cw","rotate_ccw","clear","alarm"] and phase=="WATCHING"
                _original_style(oracle,btn.get_meta("tint",Color(.4,.4,.36)),locked if cmd!="crouch" else false)
                _check(_styles(btn)==_styles(oracle),"actual phase styles "+phase+cmd+str(variant))
                values[cmd]={"text":btn.text,"visible":btn.visible,"disabled":btn.disabled,"modulate":btn.modulate,"styles":_styles(btn),"lock_visible":btn.get_node("LockMark").visible}
            phase_rows.append({"phase":phase,"variant":variant,"buttons":values})
    var file:=FileAccess.open("user://style-phase-values.bin",FileAccess.WRITE);file.store_buffer(var_to_bytes(phase_rows));file.close()
    print("HUD_STYLE_PHASE_BIN=",ProjectSettings.globalize_path("user://style-phase-values.bin"))
    print("HUD_STYLE_EQ checks=",checks," failures=",failures," phases=",phase_rows.size()," theme_notifications=",emitted)
    hud.queue_free();oracle.queue_free();await process_frame
    quit(0 if failures==0 else 1)

func _original_style(b: Button, tint: Color, locked: bool) -> void:
    var bg := Color(tint.r * 0.22, tint.g * 0.22, tint.b * 0.18, 0.96)
    var border := Color(tint.r, tint.g, tint.b, 0.85).lightened(0.12)
    if locked:
        bg = Color(0.10, 0.10, 0.09, 0.88)
        border = Color(0.28, 0.22, 0.18, 0.7)
    var normal := NightOps.flat(bg, border, 1, 10, 6)
    var hover := NightOps.flat(bg.lightened(0.18), border.lightened(0.2), 2, 10, 6)
    var pressed := NightOps.flat(bg.darkened(0.18), border, 2, 10, 6)
    var disabled := NightOps.flat(Color(0.09, 0.09, 0.08, 0.82), Color(0.22, 0.20, 0.18), 1, 10, 6)
    b.add_theme_stylebox_override("normal", normal)
    b.add_theme_stylebox_override("hover", hover)
    b.add_theme_stylebox_override("pressed", pressed)
    b.add_theme_stylebox_override("disabled", disabled)
    b.add_theme_color_override("font_color", Color(0.94, 0.92, 0.78) if not locked else Color(0.42, 0.40, 0.38))
    b.modulate = Color.WHITE if not locked else Color(0.62, 0.60, 0.58)

