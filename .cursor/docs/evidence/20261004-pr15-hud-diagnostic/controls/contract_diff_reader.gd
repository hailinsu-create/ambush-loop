extends SceneTree
const Guard := preload("res://scripts/test_storage_guard.gd")
var diffs: Array=[]
var base_dir := "/workspace/pr15-metadata-candidate-a42/ambush_loop/build/ambush_test_runs/954c4786d5cb4c1792c9c31f5fdc6f79/data/godot/app_userdata/Ambush Loop/"
func _init() -> void:
    if not Guard.check():quit(91);return
    call_deferred("_run")
func _diff(a: Variant,b: Variant,path: String) -> void:
    if typeof(a)!=typeof(b):diffs.append({"path":path,"a":str(a),"b":str(b),"type_a":typeof(a),"type_b":typeof(b)});return
    if a is Dictionary:
        if a.keys()!=b.keys():diffs.append({"path":path+".keys","a":str(a.keys()),"b":str(b.keys())})
        for key: Variant in a:
            if b.has(key):_diff(a[key],b[key],path+"."+str(key))
    elif a is Array:
        if a.size()!=b.size():diffs.append({"path":path+".size","a":a.size(),"b":b.size()});return
        for i: int in a.size():_diff(a[i],b[i],path+"[%d]" % i)
    elif a!=b:diffs.append({"path":path,"a":str(a),"b":str(b),"type_a":typeof(a),"type_b":typeof(b)})
func _normalize(value: Variant,scope: String,attempt: String) -> void:
    if value is Dictionary:
        for key: Variant in value:
            if value[key] is String:value[key]=value[key].replace(scope,"<scope>").replace(attempt,"<attempt>")
            else:_normalize(value[key],scope,attempt)
    elif value is Array:
        for item: Variant in value:_normalize(item,scope,attempt)
func _run() -> void:
    var rows: Array=[]
    for i: int in 3:rows.append(bytes_to_var(FileAccess.get_file_as_bytes(base_dir+"battle-%d.bin" % i)))
    var results: Array=[]
    for i: int in [1,2]:
        diffs=[];_diff(rows[0].normalized_original,rows[i].normalized_original,"result")
        var left: Dictionary=rows[0].normalized_original.duplicate(true)
        var right: Dictionary=rows[i].normalized_original.duplicate(true)
        _normalize(left.events,rows[0].scope,rows[0].attempt)
        _normalize(right.events,rows[i].scope,rows[i].attempt)
        results.append({"comparison":i,"original_equal":rows[0].normalized_original==rows[i].normalized_original,"diffs":diffs.duplicate(true),"equal_after_only_identity_normalization":left==right})
    var f:=FileAccess.open("user://contract-differences.json",FileAccess.WRITE);f.store_string(JSON.stringify(results,"  "));f.close()
    print("CONTRACT_DIFF_OUTPUT=",ProjectSettings.globalize_path("user://contract-differences.json"))
    for row: Dictionary in results:print("CONTRACT_DIFF count=",row.diffs.size()," identity_only_equal=",row.equal_after_only_identity_normalization)
    quit(0)
