import struct,json,sys
from pathlib import Path
class Decoder:
 def __init__(self,b):self.b=b;self.i=0
 def unpack(self,f):
  z=struct.calcsize('<'+f);v=struct.unpack_from('<'+f,self.b,self.i);self.i+=z;return v[0] if len(v)==1 else list(v)
 def value(self):
  h=self.unpack('I');t=h&0xffff;wide=bool(h&0x10000)
  if t==0:return None
  if t==1:return bool(self.unpack('I'))
  if t==2:return self.unpack('q' if wide else 'i')
  if t==3:return self.unpack('d' if wide else 'f')
  if t in (4,21):
   n=self.unpack('I');s=self.b[self.i:self.i+n].decode();self.i+=(n+3)//4*4;return s
  if t in (5,7,9,12,14,15,16,17,18,19):return self.unpack(('d' if wide else 'f')*{5:2,7:4,9:3,12:4,14:4,15:4,16:6,17:9,18:12,19:16}[t])
  if t in (6,8,10,13):return self.unpack('i'*{6:2,8:4,10:3,13:4}[t])
  if t==20:return self.unpack('ffff')
  if t==27:
   n=self.unpack('I')&0x7fffffff;out={}
   for _ in range(n):k=self.value();out[k]=self.value()
   return out
  if t==28:return [self.value() for _ in range(self.unpack('I')&0x7fffffff)]
  if t in (29,30,31,32,33,35,36,37,38):
   n=self.unpack('I');f={29:'B',30:'i',31:'q',32:'f',33:'d',35:'ff',36:'fff',37:'ffff',38:'ffff'}[t];v=[self.unpack(f) for _ in range(n)]
   if t==29:self.i+=(4-n%4)%4
   return v
  raise ValueError((t,wide,self.i))
p=Path(sys.argv[1]);d=Decoder(p.read_bytes());j=d.value();assert d.i==len(d.b),(d.i,len(d.b))
r={'path':str(p),'decoded_bytes':d.i,'attempt_id':j['attempt_id'],'terminal_reason':j['terminal_reason'],'last_playback_frames':[{'playback_tick':s['playback_tick'],'frame_seq':s.get('frame_seq'),'wave':s.get('wave_id'),'phase':s['data']['phase'],'ops':[{k:a.get(k) for k in ['id','name','alive','hp','pos','visible','moving','locked','slot']} for a in s['data']['ops']]} for s in j['playback_snapshots'][-8:]]}
print(json.dumps(r,indent=2));Path(sys.argv[2]).write_text(json.dumps(r,indent=2)+'\n')
