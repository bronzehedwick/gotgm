/// Original God of Thunder dialogue and quest-script runtime
function dialogue_init(){
 global.dialogue={active:false,episode:1,entry:"",lines:[],labels:{},pc:0,pending:[],
 vars:array_create(26,0),strings:array_create(26,""),calls:[],loops:[],mode:"idle",
 text_lines:[],page:0,choices:[],selection:0,answer_var:0,title:"",portrait:-1,
 item_sprite:-1,speaker:noone,pause_timer:0,last_if:false};
 global.dialogue_banks=array_create(4,undefined);
}
function dialogue_bank(ep){
 if(global.dialogue_banks[ep]!=undefined)return global.dialogue_banks[ep];
 var _p="data/dialogue/dialogue"+string(ep)+".json",_b=buffer_load(_p);
 if(_b==-1){show_debug_message("Missing "+_p);return undefined;}
 var _s=buffer_read(_b,buffer_string);buffer_delete(_b);
 global.dialogue_banks[ep]=json_parse(_s);return global.dialogue_banks[ep];
}
function dialogue_build_labels(){
 var _d=global.dialogue;_d.labels={};
 for(var _i=0;_i<array_length(_d.lines);_i++){
  var _s=string_trim(_d.lines[_i]),_n=string_length(_s);
  if(_n>1&&string_char_at(_s,_n)==":")
   _d.labels[$ string_upper(string_trim(string_copy(_s,1,_n-1)))]=_i+1;
 }
}
function dialogue_set_entry(id,reset_vars){
 var _d=global.dialogue,_b=dialogue_bank(_d.episode),_k=string(id);
 if(_b==undefined||!struct_exists(_b,_k)){show_debug_message("Missing dialogue EP"+string(_d.episode)+" #"+_k);dialogue_close();return false;}
 if(reset_vars){_d.vars=array_create(26,0);_d.strings=array_create(26,"");_d.calls=[];_d.loops=[];}
 _d.entry=_k;_d.lines=_b[$ _k];_d.pc=0;_d.pending=[];_d.mode="running";dialogue_build_labels();return true;
}
function dialogue_start_actor(a){
 if(global.dialogue.active||!instance_exists(a)||a.actor_slot<0)return false;
 var _name=a.actor_def.name,_colon=string_pos(":",_name);
 var _face=clamp(real((_colon>0)?string_copy(_name,1,_colon-1):_name),1,20),_num=string(_face);
 _num=string_repeat("0",max(0,2-string_length(_num)))+_num;
 var _d=global.dialogue;_d.active=true;_d.episode=global.current_episode;_d.speaker=a;
 _d.portrait=asset_get_index("spr_face_"+_num);_d.item_sprite=-1;
 if(!dialogue_set_entry(global.current_level*1000+a.actor_slot,true))return false;
 dialogue_run();return true;
}
function dialogue_start(id,portrait){
 if(global.dialogue.active)return false;var _d=global.dialogue;
 _d.active=true;_d.episode=global.current_episode;_d.speaker=noone;_d.portrait=portrait;_d.item_sprite=-1;
 if(!dialogue_set_entry(id,true))return false;dialogue_run();return true;
}
function dialogue_close(){
 var _d=global.dialogue;if(instance_exists(_d.speaker))_d.speaker.dialogue_cooldown=20;
 _d.active=false;_d.mode="idle";_d.speaker=noone;_d.item_sprite=-1;
}
function dialogue_var_index(s){return clamp(ord(string_upper(string_char_at(string_trim(s),1)))-ord("A"),0,25);}
function dialogue_eval_numeric(e){
 var _d=global.dialogue;_e=string_trim(e);
 while(string_length(_e)>=2&&string_char_at(_e,1)=="("&&string_char_at(_e,string_length(_e))==")")
  _e=string_trim(string_copy(_e,2,string_length(_e)-2));
 for(var _pass=0;_pass<2;_pass++){var _ops=(_pass==0)?"+-":"*/";
  for(var _i=string_length(_e);_i>=2;_i--){var _c=string_char_at(_e,_i);
   if(string_pos(_c,_ops)>0){var _a=dialogue_eval_numeric(string_copy(_e,1,_i-1));
    var _b=dialogue_eval_numeric(string_copy(_e,_i+1,string_length(_e)-_i));
    if(_c=="+")return _a+_b;if(_c=="-")return _a-_b;if(_c=="*")return _a*_b;return(_b==0)?0:_a div _b;}}}
 var _u=string_upper(_e);
 if(string_pos("@FLAG",_u)==1&&string_length(_u)>5)return struct_exists(global.flags,string(real(string_copy(_u,6,string_length(_u)-5))))?1:0;
 switch(_u){
  case"@JEWELS":return global.jewels;case"@HEALTH":return global.health;case"@MAGIC":return global.magic;
  case"@SCORE":return global.score;case"@SCREEN":return global.current_level;case"@KEYS":return global.keys;
  case"@ITEM":return global.quest_object;
  case"@THORPOS":return((global.player.y+8)div 16)*20+((global.player.x+8)div 16);
  case"@THORTILE":return tile_get((global.player.x+8)div 16,(global.player.y+8)div 16);
  case"@OW":return 1;case"@GULP":return 2;case"@SWISH":return 3;case"@YAH":return 4;
  case"@ELECTRIC":return 5;case"@THUNDER":return 6;case"@DOOR":return 7;case"@FALL":return 8;
  case"@ANGEL":return 9;case"@WOOP":return 10;case"@DEAD":return 11;case"@BRAAPP":return 12;
  case"@WIND":return 13;case"@PUNCH":return 14;case"@CLANG":return 15;case"@EXPLODE":return 16;
 }
 if(string_length(_u)==1&&ord(_u)>=ord("A")&&ord(_u)<=ord("Z"))return _d.vars[dialogue_var_index(_u)];
 return real(_e);
}
function dialogue_eval_string(e){
 var _d=global.dialogue;_e=string_trim(e);var _out="",_part="",_q=false,_quote=chr(34);
 for(var _i=1;_i<=string_length(_e)+1;_i++){var _c=(_i<=string_length(_e))?string_char_at(_e,_i):"+";
  if(_c==_quote){_q=!_q;continue;}if(_c=="+"&&(!_q||_i>string_length(_e))){var _t=string_trim(_part);
   if(string_length(_t)>=2&&string_char_at(_t,string_length(_t))=="$")_out+=_d.strings[dialogue_var_index(_t)];
   else if(string_length(_t)>0)_out+=_t;_part="";}else _part+=_c;}return _out;
}
function dialogue_csv(s){
 var _a=[],_p="",_q=false,_quote=chr(34);for(var _i=1;_i<=string_length(s);_i++){var _c=string_char_at(s,_i);
  if(_c==_quote)_q=!_q;if(_c==","&&!_q){array_push(_a,string_trim(_p));_p="";}else _p+=_c;}
 array_push(_a,string_trim(_p));return _a;
}
function dialogue_split_commands(s){
 var _a=[],_p="",_q=false,_quote=chr(34);for(var _i=1;_i<=string_length(s);_i++){var _c=string_char_at(s,_i);
  if(_c==_quote)_q=!_q;if(_c==":"&&!_q){if(string_length(string_trim(_p))>0)array_push(_a,string_trim(_p));_p="";}else _p+=_c;}
 if(string_length(string_trim(_p))>0)array_push(_a,string_trim(_p));return _a;
}
function dialogue_enqueue_front(s){var _a=dialogue_split_commands(s);for(var _i=array_length(_a)-1;_i>=0;_i--)array_insert(global.dialogue.pending,0,_a[_i]);}
function dialogue_collect_quoted(){
 var _d=global.dialogue,_a=[],_quote=chr(34);while(_d.pc<array_length(_d.lines)){var _s=string_trim(_d.lines[_d.pc]);
  if(string_length(_s)==0){_d.pc++;continue;}
  if(string_char_at(_s,1)!=_quote)break;_d.pc++;array_push(_a,dialogue_eval_string(_s));}return _a;
}
function dialogue_wrap(lines,width){
 var _a=[];for(var _j=0;_j<array_length(lines);_j++){var _s=lines[_j];if(string_length(_s)==0){array_push(_a,"");continue;}
  while(string_length(_s)>width){var _cut=width;for(var _i=width;_i>=1;_i--)if(string_char_at(_s,_i)==" "){_cut=_i;break;}
   array_push(_a,string_copy(_s,1,_cut));_s=string_trim(string_copy(_s,_cut+1,string_length(_s)-_cut));}array_push(_a,_s);}return _a;
}
function dialogue_compare(s){
 var _ops=["<>",">=","<=","=",">","<"];for(var _i=0;_i<array_length(_ops);_i++){var _op=_ops[_i],_at=string_pos(_op,s);
  if(_at>0){var _a=dialogue_eval_numeric(string_copy(s,1,_at-1));
   var _b=dialogue_eval_numeric(string_copy(s,_at+string_length(_op),string_length(s)-_at-string_length(_op)+1));
   if(_op=="<>")return _a!=_b;if(_op==">=")return _a>=_b;if(_op=="<=")return _a<=_b;
   if(_op=="=")return _a==_b;if(_op==">")return _a>_b;return _a<_b;}}return dialogue_eval_numeric(s)!=0;
}
function dialogue_assign(s){
 var _d=global.dialogue,_eq=string_pos("=",s);if(_eq<=1)return false;
 var _l=string_trim(string_copy(s,1,_eq-1)),_r=string_trim(string_copy(s,_eq+1,string_length(s)-_eq));
 if(string_char_at(_l,string_length(_l))=="$")_d.strings[dialogue_var_index(_l)]=dialogue_eval_string(_r);
 else if(string_length(_l)==1)_d.vars[dialogue_var_index(_l)]=dialogue_eval_numeric(_r);else return false;return true;
}
function dialogue_goto(label){
 var _d=global.dialogue,_k=string_upper(string_trim(label));
 if(struct_exists(_d.labels,_k)){_d.pc=_d.labels[$ _k];_d.pending=[];return true;}show_debug_message("Unknown label "+_k);return false;
}
function dialogue_place_tile(screen,pos,tile){
 global.tile_overrides[$ string(global.current_episode)+":"+string(screen)+":"+string(pos)]=tile;
 if(screen==global.current_level)level_set_tile(pos mod 20,pos div 20,tile);
}
function dialogue_sound(n){
 var _a=[snd_got_ow,snd_got_gulp,snd_got_swish,snd_got_yah,snd_got_electric,snd_got_thunder,snd_got_door,snd_got_fall,
 snd_got_angel,snd_got_woop,snd_got_dead,snd_got_braapp,snd_got_wind,snd_got_punch,snd_got_clang,snd_got_explode];
 if(n>=1&&n<=16)audio_play_sound(_a[n-1],2,false);
}
function dialogue_execute_hook(n){
 var _d=global.dialogue;if(_d.episode==3&&n==2){var _a=["Cussing","Rebellion","Kissing Your Mother Goodbye",
 "Being a Thunder God","Door-to-Door Sales","Carrying a Concealed Hammer"];
 var _b=["The law is the law.","No excuses are accepted.","You should have known better.","Orders are orders."];
 _d.strings[0]=_a[irandom(array_length(_a)-1)];_d.strings[1]=_b[irandom(array_length(_b)-1)];
 }else show_debug_message("Dialogue EXEC "+string(n)+" EP"+string(_d.episode));
}
function dialogue_execute(s){
 var _d=global.dialogue,_u=string_upper(string_trim(s));
 if(string_length(_u)==0||string_char_at(_u,1)=="'"||string_pos("//",_u)==1||string_char_at(_u,1)=="|")return;
 var _sp=string_pos(" ",_u),_name=(_sp>0)?string_copy(_u,1,_sp-1):_u;
 var _args=(_sp>0)?string_trim(string_copy(s,_sp+1,string_length(s)-_sp)):"";
 switch(_name){
 case"END":dialogue_close();return;case"GOTO":dialogue_goto(_args);return;
 case"GOSUB":array_push(_d.calls,_d.pc);dialogue_goto(_args);return;
 case"RETURN":if(array_length(_d.calls)>0){_d.pc=array_pop(_d.calls);_d.pending=[];}else dialogue_close();return;
 case"RUN":dialogue_set_entry(dialogue_eval_numeric(_args),false);return;
 case"IF":
  var _then=string_pos(" THEN ",_u);if(_then<=0)return;var _condition=string_copy(s,3,_then-3);
  var _tail=string_copy(s,_then+6,string_length(s)-_then-5),_else=string_pos(" ELSE ",string_upper(_tail));
  var _yes=dialogue_compare(_condition);_d.last_if=_yes;
  if(_yes){if(_else>0)_tail=string_copy(_tail,1,_else-1);dialogue_enqueue_front(_tail);}
  else if(_else>0)dialogue_enqueue_front(string_copy(_tail,_else+6,string_length(_tail)-_else-5));return;
 case"ELSE":if(!_d.last_if)dialogue_enqueue_front(_args);return;
 case"SAY":case"TEXT":case"ITEMSAY":
  _d.text_lines=dialogue_collect_quoted();_d.page=0;_d.item_sprite=-1;if(_name=="TEXT")_d.portrait=-1;
  if(_name=="ITEMSAY"){var _num=string(dialogue_eval_numeric(_args));_num=string_repeat("0",max(0,2-string_length(_num)))+_num;
   _d.item_sprite=asset_get_index("spr_pickup_"+_num);}_d.mode="say";return;
 case"ASK":
  var _parts=dialogue_csv(_args);_d.answer_var=dialogue_var_index(_parts[0]);
  _d.title=(array_length(_parts)>1)?dialogue_eval_string(_parts[1]):"";
  _d.selection=(array_length(_parts)>2)?max(0,dialogue_eval_numeric(_parts[2])-1):0;_d.choices=dialogue_collect_quoted();
  _d.selection=clamp(_d.selection,0,max(0,array_length(_d.choices)-1));_d.mode="ask";return;
 case"PAUSE":_d.pause_timer=max(1,dialogue_eval_numeric(_args));_d.mode="pause";return;
 case"SOUND":dialogue_sound(dialogue_eval_numeric(_args));return;
 case"ADDJEWELS":global.jewels=clamp(global.jewels+dialogue_eval_numeric(_args),0,MAX_JEWELS);return;
 case"ADDHEALTH":global.health=clamp(global.health+dialogue_eval_numeric(_args),0,MAX_HEALTH);return;
 case"ADDMAGIC":global.magic=clamp(global.magic+dialogue_eval_numeric(_args),0,MAX_MAGIC);return;
 case"ADDKEYS":global.keys=clamp(global.keys+dialogue_eval_numeric(_args),0,MAX_KEYS);return;
 case"ADDSCORE":global.score=clamp(global.score+dialogue_eval_numeric(_args),0,MAX_SCORE);return;
 case"SETFLAG":global.flags[$ string(dialogue_eval_numeric(_args))]=true;return;
 case"PLACETILE":var _p=dialogue_csv(_args);if(array_length(_p)>=3)dialogue_place_tile(dialogue_eval_numeric(_p[0]),dialogue_eval_numeric(_p[1]),dialogue_eval_numeric(_p[2]));return;
 case"ITEMGIVE":global.quest_object=dialogue_eval_numeric(_args);global.selected_item=7;return;
 case"ITEMTAKE":global.quest_object=0;if(global.selected_item==7)global.selected_item=0;return;
 case"VISIBLE":var _group=dialogue_eval_numeric(_args);with(obj_enemy)if(!visible&&invisibility_group==_group)visible=true;return;
 case"RANDOM":var _r=dialogue_csv(_args);if(array_length(_r)>=2)_d.vars[dialogue_var_index(_r[0])]=irandom(max(0,dialogue_eval_numeric(_r[1])-1));return;
 case"LTOA":var _l=dialogue_csv(_args);if(array_length(_l)>=2)_d.strings[dialogue_var_index(_l[1])]=string(dialogue_eval_numeric(_l[0]));return;
 case"FOR":
  var _eq=string_pos("=",_args),_to=string_pos(" TO ",string_upper(_args));if(_eq>0&&_to>_eq){var _vi=dialogue_var_index(string_copy(_args,1,_eq-1));
   _d.vars[_vi]=dialogue_eval_numeric(string_copy(_args,_eq+1,_to-_eq-1));
   array_push(_d.loops,{variable:_vi,start_pc:_d.pc,end_value:dialogue_eval_numeric(string_copy(_args,_to+4,string_length(_args)-_to-3))});}return;
 case"NEXT":
  if(array_length(_d.loops)>0){var _loop=_d.loops[array_length(_d.loops)-1];_d.vars[_loop.variable]++;
   if(_d.vars[_loop.variable]<=_loop.end_value){_d.pc=_loop.start_pc;_d.pending=[];}else array_pop(_d.loops);}return;
 case"EXEC":dialogue_execute_hook(dialogue_eval_numeric(_args));return;
 }
 if(!dialogue_assign(s))show_debug_message("Unhandled dialogue: "+s);
}
function dialogue_run(){
 var _d=global.dialogue,_safe=0;while(_d.active&&_d.mode=="running"&&_safe<200){_safe++;var _cmd="";
  if(array_length(_d.pending)>0){_cmd=_d.pending[0];array_delete(_d.pending,0,1);}
  else{if(_d.pc>=array_length(_d.lines)){dialogue_close();break;}var _line=string_trim(_d.lines[_d.pc]);_d.pc++;
   if(string_length(_line)==0)continue;if(string_char_at(_line,string_length(_line))==":")continue;
   var _commands=dialogue_split_commands(_line);for(var _i=0;_i<array_length(_commands);_i++)array_push(_d.pending,_commands[_i]);continue;}
  dialogue_execute(_cmd);}if(_safe>=200)show_debug_message("Dialogue safety stop #"+_d.entry);
}
function dialogue_update(){
 var _d=global.dialogue;if(!_d.active)return;if(keyboard_check_pressed(vk_escape)){dialogue_close();return;}var _ok=keyboard_check_pressed(vk_space)||keyboard_check_pressed(vk_enter)||keyboard_check_pressed(ord("Z"));
 if(_d.mode=="pause"){_d.pause_timer--;if(_d.pause_timer<=0){_d.mode="running";dialogue_run();}return;}
 if(_d.mode=="say"){if(_ok){if((_d.page+1)*5<array_length(_d.text_lines))_d.page++;else{_d.mode="running";_d.item_sprite=-1;dialogue_run();}}return;}
 if(_d.mode=="ask"){if(keyboard_check_pressed(vk_up))_d.selection=max(0,_d.selection-1);
  if(keyboard_check_pressed(vk_down))_d.selection=min(array_length(_d.choices)-1,_d.selection+1);
  if(_ok&&array_length(_d.choices)>0){_d.vars[_d.answer_var]=_d.selection+1;_d.mode="running";dialogue_run();}return;}dialogue_run();
}
function dialogue_markup_colour(index) {
 var _colours=[
  make_colour_rgb(243,243,83),
  make_colour_rgb(255,35,35),
  make_colour_rgb(0,231,231),
  make_colour_rgb(159,159,255),
  make_colour_rgb(243,243,243)
 ];
 return _colours[clamp(index,0,4)];
}
function dialogue_draw_line(s,xx,yy){
 var _x=xx,_colour=dialogue_markup_colour(0);
 for(var _i=1;_i<=string_length(s);_i++){
  var _c=string_char_at(s,_i);
  if(_c=="~"&&_i<string_length(s)){
   var _code=string_upper(string_char_at(s,_i+1)),_value=-1;
   if(ord(_code)>=ord("0")&&ord(_code)<=ord("9"))_value=ord(_code)-ord("0");
   else if(ord(_code)>=ord("A")&&ord(_code)<=ord("F"))_value=ord(_code)-ord("A")+10;
   if(_value>=0){_colour=dialogue_markup_colour(_value);_i++;continue;}
  }
  draw_original_text_colour(_c,_x,yy,_colour,true);_x+=8;
 }
}
function dialogue_draw_tile(tile_id,xx,yy){
 if(global.room_tiles_sprite==-1)return;
 var _source=tile_id+1;
 draw_sprite_part(global.room_tiles_sprite,0,(_source mod 16)*16,(_source div 16)*16,16,16,xx,yy);
}
function dialogue_draw_frame(){
 draw_set_colour(make_colour_rgb(131,83,47));
 draw_rectangle(48,64,273,145,false);
 dialogue_draw_tile(192,32,48);dialogue_draw_tile(193,272,48);
 dialogue_draw_tile(194,32,144);dialogue_draw_tile(195,272,144);
 for(var _i=0;_i<14;_i++){
  dialogue_draw_tile(196,48+_i*16,48);
  dialogue_draw_tile(197,48+_i*16,144);
 }
 for(var _i=0;_i<5;_i++){
  dialogue_draw_tile(198,32,64+_i*16);
  dialogue_draw_tile(199,272,64+_i*16);
 }
}
function dialogue_draw(){
 var _d=global.dialogue;if(!_d.active||_d.mode=="pause")return;
 dialogue_draw_frame();
 if(_d.mode=="ask"){
  var _title_x=160-(string_length(_d.title)*4);
  dialogue_draw_line("~1"+_d.title+"~0",_title_x,68);
  for(var _i=0;_i<min(5,array_length(_d.choices));_i++){
   dialogue_draw_line(((_i==_d.selection)?"~4> ~0":"  ")+_d.choices[_i],56,86+_i*11);
  }
  return;
 }
 if(_d.portrait!=-1)draw_sprite_ext(_d.portrait,floor(current_time/140)mod 4,152,65,1,1,0,c_white,1);
 if(_d.item_sprite!=-1)draw_sprite_ext(_d.item_sprite,0,176,65,1,1,0,c_white,1);
 var _first=_d.page*5;
 for(var _i=0;_i<5;_i++){
  var _at=_first+_i;if(_at>=array_length(_d.text_lines))break;
  dialogue_draw_line(_d.text_lines[_at],52,83+_i*10);
 }
 if(_first+5<array_length(_d.text_lines))dialogue_draw_line("~4More...",216,134);
}