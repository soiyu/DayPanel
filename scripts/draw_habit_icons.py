"""Original DayPanel living-object icons. Rebuild with Python + Pillow.
No third-party artwork. Coordinates use a 100-unit canvas, rendered at 3x.
Persisted indices 0..23 intentionally retain their previous meanings.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import math
ROOT = Path(__file__).resolve().parents[1] / 'assets' / 'habit_icons'
ROOT.mkdir(parents=True, exist_ok=True)
S=3
BLUE='#4E8DDE'; NAVY='#315C96'; TEAL='#4EAFA5'; GREEN='#75AF85'; CORAL='#E88978'; GOLD='#EABB69'; PURPLE='#9C8ACA'; CREAM='#FFF4DC'; WHITE='#FFFDF6'; INK='#4C5971'

def make(i):
 im=Image.new('RGBA',(100*S,100*S));d=ImageDraw.Draw(im)
 def box(xy,fill,r=0,outline=None,w=1):
  xy=tuple(round(x*S) for x in xy)
  if r:d.rounded_rectangle(xy,round(r*S),fill,outline,round(w*S))
  else:d.rectangle(xy,fill,outline,round(w*S))
 def oval(xy,fill,outline=None,w=1):d.ellipse(tuple(round(x*S) for x in xy),fill,outline,round(w*S))
 def line(pts,c,w=3):d.line([(round(x*S),round(y*S)) for x,y in pts],fill=c,width=round(w*S),joint='curve')
 def poly(pts,c):d.polygon([(round(x*S),round(y*S)) for x,y in pts],fill=c)
 def path(start,segments,c,stroke=None,w=2):
  pts=[start];x,y=start
  for seg in segments:
   if len(seg)==2:pts.append(seg);x,y=seg
   else:
    a,b,e,f,g,h=seg;x0,y0=x,y
    for j in range(1,25):
     t=j/24;u=1-t;pts.append((u**3*x0+3*u*u*t*a+3*u*t*t*e+t**3*g,u**3*y0+3*u*u*t*b+3*u*t*t*f+t**3*h))
    x,y=g,h
  if c:poly(pts,c)
  if stroke:line(pts,stroke,w)
 def heart(cx,cy,k,c):
  path((cx,cy+k*.7),[(cx-k*1.2,cy-k*.15,cx-k*.45,cy-k,cx,cy-k*.4),(cx+k*.45,cy-k,cx+k*1.2,cy-k*.15,cx,cy+k*.7)],c)
 def star(cx,cy,r,c):
  poly([(cx+math.cos(-math.pi/2+j*math.pi/5)*(r if j%2==0 else r*.44),cy+math.sin(-math.pi/2+j*math.pi/5)*(r if j%2==0 else r*.44)) for j in range(10)],c)
 def book():
  box((17,25,80,80),NAVY,7);box((20,21,77,75),CORAL,6);box((25,23,31,72),'#D46D67',2)
  poly([(32,30),(51,35),(51,69),(32,64)],CREAM);poly([(51,35),(70,29),(70,63),(51,69)],WHITE)
  line([(51,35),(51,68)],'#D5C6B3',1.3)
  for y in [39,47,55]:line([(36,y),(46,y+3)],'#B5ACAA',1.3);line([(56,y+2),(65,y-1)],'#B5ACAA',1.3)
  poly([(64,22),(71,22),(71,42),(67.5,38),(64,42)],TEAL)
 def shoe(run=False):
  path((19,54),[(25,49),(32,32),(43,35),(47,48),(60,53),(69,45),(76,54),(86,59,89,68,84,72),(19,72),(14,67,15,58,19,54)],TEAL if not run else CORAL)
  path((18,67),[(39,71,61,65,87,67),(87,76),(18,76),(15,72)],CREAM)
  line([(38,45),(48,50)],WHITE,3);line([(35,51),(45,56)],WHITE,3)
  path((51,57),[(63,62,67,54,74,54)],None,GOLD,5)
  line([(20,80),(43,80)],'#A4BBD0',2)
  if run:line([(13,38),(27,38)],GOLD,3);line([(9,45),(22,45)],BLUE,3)
 # Soft grounding shadow belongs to the illustration, not its frame.
 oval((17,79,84,87),'#40516C12')
 if i==0:
  for a in range(0,360,45):
   r=math.radians(a);line([(50+31*math.cos(r),43+31*math.sin(r)),(50+38*math.cos(r),43+38*math.sin(r))],GOLD,4)
  oval((26,19,74,67),GOLD);oval((33,24,65,57),'#F6CE87');path((21,65),[(16,53,32,49,38,57),(45,44,61,48,63,60),(79,57,86,75,70,78),(28,78),(18,78,14,70,21,65)],WHITE)
 elif i==1:
  path((26,23),[(75,23),(69,78),(33,78),(26,23)],'#C5E6F6');path((31,47),[(43,40,55,53,71,44),(67,76),(36,76)],BLUE)
  oval((25,19,76,29),'#E8F6FB',NAVY,1.5);line([(34,32),(38,53)],WHITE,3);oval((44,58,48,62),'#96D5F3');oval((54,50,60,56),'#96D5F3')
  path((80,29),[(65,46,78,55,85,47),(91,39,82,32,80,29)],TEAL)
 elif i==2:book()
 elif i==3:shoe()
 elif i==4:
  heart(50,48,32,CORAL);heart(48,45,24,'#F3A08F');line([(24,48),(37,48),(44,35),(52,60),(59,46),(76,46)],WHITE,3)
 elif i in [5,21]:
  path((66,18),[(29,11,14,50,34,69),(57,90,86,66,83,52),(62,63,45,34,66,18)],PURPLE)
  path((58,24),[(35,30,35,60,55,68)],None,'#C3B4E5',4);star(76,26,10,GOLD);star(85,43,5,GOLD)
  if i==21:box((22,70,77,84),BLUE,5);box((27,67,47,76),CREAM,4)
 elif i==6:
  line([(29,66),(71,32)],INK,10)
  for x,y in [(24,65),(33,57),(67,40),(76,32)]:
   poly([(x-11,y-9),(x-4,y-15),(x+12,y+5),(x+5,y+11)],BLUE if x<50 else TEAL)
  line([(18,63),(26,72)],'#9CC6EF',3);star(77,70,9,GOLD)
 elif i==7:
  oval((43,16,59,32),GOLD);path((48,35),[(34,37,35,59,27,61),(21,64,24,72,32,68),(43,61),(53,62),(70,69),(78,69,77,61,70,59),(62,37,60,35,48,35)],PURPLE)
  path((24,75),[(39,61,46,67,51,72),(60,64,70,64,81,77),(63,84,38,85,24,75)],TEAL);line([(47,48),(52,56),(58,48)],CREAM,3)
 elif i==8:shoe(True)
 elif i==9:
  oval((10,49,44,83),None,NAVY,3);oval((58,49,92,83),None,NAVY,3)
  line([(27,66),(40,40),(58,66),(27,66),(66,42),(75,66)],TEAL,4);line([(64,36),(71,34),(75,37)],CORAL,4);line([(34,39),(46,39)],INK,4);oval((52,61,62,71),GOLD)
 elif i==10:
  oval((24,22,80,81),BLUE);oval((29,27,75,76),CREAM);oval((33,32,70,71),WHITE)
  oval((46,39,69,62),GOLD);path((38,38),[(22,41,29,62,45,64),(52,54,50,41,38,38)],GREEN)
  line([(14,26),(14,77)],INK,3);line([(10,26),(10,38),(18,38),(18,26)],INK,2);line([(87,26),(87,77)],CORAL,4)
 elif i==11:
  line([(50,48),(50,76)],TEAL,4);path((49,65),[(23,39,23,75,49,73)],GREEN);path((53,62),[(78,42,79,69,53,70)],TEAL)
  for a in range(0,360,72):
   x=50+13*math.cos(math.radians(a));y=32+13*math.sin(math.radians(a));oval((x-11,y-11,x+11,y+11),CORAL)
  oval((43,25,57,39),GOLD);path((32,74),[(68,74),(63,89),(37,89)],'#E6B58D')
 elif i==12:
  path((35,34),[(35,73),(29,80,16,76,20,68),(24,62,29,64,30,64),(30,30),(73,21),(73,64),(66,74,54,68,58,60),(61,56,65,56,68,58),(68,35)],PURPLE)
  line([(34,34),(69,26)],CORAL,5);star(78,47,7,GOLD)
 elif i==13:
  path((40,23),[(11,31,12,70,36,78),(64,88,85,68,68,61),(60,54,89,41,73,28),(61,18,47,19,40,23)],'#EAC498')
  for x,y,c in [(32,38,CORAL),(50,30,BLUE),(67,39,TEAL),(29,57,PURPLE)]:oval((x-6,y-6,x+6,y+6),c)
  line([(48,74),(76,27)],NAVY,7);poly([(70,31),(84,15),(83,35)],CORAL)
 elif i==14:
  box((22,21,70,83),BLUE,6);box((27,17,75,78),CREAM,5)
  for y in [33,44,55,66]:line([(35,y),(62,y)],'#D1C8B8',2)
  poly([(56,67),(68,65),(87,27),(77,21)],CORAL);poly([(56,67),(55,77),(64,71)],INK);line([(76,30),(82,33)],GOLD,3)
 elif i==15:
  oval((19,19,81,81),BLUE);oval((24,24,76,76),'#B9E1EE')
  path((37,24),[(35,37),(47,43),(41,54),(28,49),(24,37)],TEAL);path((62,46),[(74,41),(76,63),(63,74),(57,59)],GREEN)
  d.arc((31*S,22*S,69*S,78*S),70,290,fill=NAVY,width=2*S);line([(24,50),(76,50)],WHITE,2)
 elif i==16:
  path((27,37),[(23,31),(35,35),(57,29,79,40,78,57),(88,57),(88,68),(76,69),(70,82),(61,82),(59,73),(40,74),(35,82),(26,82),(28,70),(16,58,15,45,27,37)],CORAL)
  oval((62,43,66,47),INK);line([(41,37),(54,37)],INK,3);oval((42,12,61,31),GOLD);line([(51,17),(51,26)],CREAM,2);path((19,45),[(4,31,5,61,18,55)],None,PURPLE,3)
 elif i==17:
  line([(59,19),(43,59)],TEAL,7);poly([(27,53),(54,61),(57,82),(13,77)],GOLD);line([(32,60),(27,77)],'#C3945B',2);line([(43,64),(39,79)],'#C3945B',2)
  box((63,50,84,83),BLUE,5);box((66,43,80,53),NAVY,2);line([(71,44),(71,36),(83,36)],NAVY,4);star(30,27,9,PURPLE)
 elif i==18:
  oval((28,46,73,80),GOLD);oval((18,27,35,48),CORAL);oval((38,17,53,40),CORAL);oval((59,21,75,44),CORAL);oval((76,37,90,58),CORAL);heart(51,65,12,WHITE)
 elif i==19:
  oval((17,73,87,84),'#CBD9E8');oval((61,39,88,65),None,CORAL,6);box((23,33,70,77),CORAL,10);oval((22,28,71,43),CREAM);oval((29,32,65,39),'#95694E');path((39,22),[(31,12,47,10,40,3)],None,TEAL,3)
 elif i==20:
  box((26,26,74,84),TEAL,10);box((31,17,69,32),NAVY,4);box((31,43,69,70),CREAM,4);box((46,46,54,67),CORAL,1);box((39,52,61,60),CORAL,1);line([(34,34),(34,41)],'#A0D9CE',3)
 elif i==22:
  box((29,16,71,83),NAVY,8);box((33,23,67,72),'#CEE2ED',4);oval((46,75,54,79),CREAM);line([(21,25),(80,77)],CORAL,7);star(79,22,8,GOLD)
 elif i==23:
  heart(51,33,23,CORAL);path((16,61),[(26,54),(45,62),(54,60),(59,64,56,70,51,71),(70,57),(82,59,84,66,76,71),(55,85),(37,85),(16,73)],GOLD);line([(30,65),(49,74),(58,71)],CREAM,2);box((9,57,24,81),TEAL,4)
 return im.resize((256,256),Image.Resampling.LANCZOS)

if __name__=='__main__':
 for i in range(24):make(i).save(ROOT/f'{i:02}.png',optimize=True)
 # Optional contact sheet is diagnostic only, never packaged.
 import sys
 if len(sys.argv)>1:
  sheet=Image.new('RGB',(960,640),'#F4F6FA')
  for i in range(24):
   icon=make(i).resize((120,120),Image.Resampling.LANCZOS);x=(i%6)*160+20;y=(i//6)*160+10;sheet.paste(icon,(x,y),icon);ImageDraw.Draw(sheet).text((x+52,y+124),str(i),fill=INK)
  sheet.save(sys.argv[1])
