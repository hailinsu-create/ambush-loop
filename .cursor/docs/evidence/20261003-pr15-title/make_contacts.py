from pathlib import Path
import json
from PIL import Image,ImageOps,ImageDraw,ImageFont
base=Path(__file__).resolve().parent
r=json.loads((base/"formal-matrix/title-menu-report.json").read_text())
font=ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",14)
for page in range(4):
    sheet=Image.new("RGB",(1152,1320),(15,18,16))
    draw=ImageDraw.Draw(sheet)
    for index,cap in enumerate(r["captures"][page*18:(page+1)*18]):
        img=Image.open(base/"formal-matrix"/Path(cap["path"]).name).convert("RGB")
        img.thumbnail((384,216))
        x=(index%3)*384; y=(index//3)*220
        sheet.paste(img,(x+(384-img.width)//2,y))
        # Full identity is kept in the source JSON; labels aid visual comparison.
        label=cap["id"].replace("title_", "").replace("desktop", "desk")
        draw.text((x+4,y+199),label,font=font,fill=(240,240,222))
    sheet.save(base/("contact-%d.png"%page))
