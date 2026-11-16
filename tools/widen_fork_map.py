# 임시 탑뷰 시험용: 1층 갈림길 맵 원본(art/raw/map_f1_fork_raw.png)을 약 1.5배로 넓힌다(바닥 타일 반복 + 벽·소품 조각 이어 붙이기).
from PIL import Image
import numpy as np
rng=np.random.default_rng(7)
def soft_paste(dst,img,pos,feather=36,block=3,sides='lrtb'):
    # 가장자리를 블록 단위로 섞어 붙인다(흐리게 하지 않고 픽셀을 골라서 섞음)
    w,h=img.size
    bw,bh=(w+block-1)//block,(h+block-1)//block
    yy,xx=np.mgrid[0:bh,0:bw]*block
    d=np.full((bh,bw),1e9)
    if 'l' in sides: d=np.minimum(d,xx)
    if 'r' in sides: d=np.minimum(d,w-1-xx)
    if 't' in sides: d=np.minimum(d,yy)
    if 'b' in sides: d=np.minimum(d,h-1-yy)
    p=np.clip(d/feather,0,1)
    m=(rng.random((bh,bw))<p).astype(np.uint8)*255
    mask=Image.fromarray(m,'L').resize((bw*block,bh*block),Image.NEAREST).crop((0,0,w,h))
    dst.paste(img,pos,mask)
src=Image.open('/home/user/yemo_plan/art/raw/map_f1_fork_raw.png').convert('RGB')
W,H=src.size
DX,DY=664,576            # 바닥 타일(332×192) 배수로 늘려 이음새 줄눈을 맞춘다
BS=830
W2,H2=W+DX,H+DY
out=Image.new('RGB',(W2,H2),(14,12,20))
def crop(x0,y0,x1,y1): return src.crop((x0,y0,x1,y1))
# 1) 바닥: 깨끗한 타일 4×3장 조각을 원본 위치 기준으로 반복
fx0,fy0,fx1,fy1=474,561,806,753; tw,th=fx1-fx0,fy1-fy0
tile=crop(fx0,fy0,fx1,fy1)
ref=np.concatenate([np.asarray(crop(220,440,400,520)).reshape(-1,3),np.asarray(crop(1000,440,1100,520)).reshape(-1,3),np.asarray(crop(600,770,900,800)).reshape(-1,3)]).astype(float)
ta=np.asarray(tile).astype(float); k=ref.mean(0)/ta.reshape(-1,3).mean(0)
tile=Image.fromarray(np.clip(ta*k,0,255).astype(np.uint8))
sx=fx0-((fx0)//tw+1)*tw; sy=fy0-((fy0)//th+1)*th
for y in range(sy,H2,th):
    for x in range(sx,W2,tw): out.paste(tile,(x,y))
# 2) 소품 묶음(원본 바닥째 붙임, 타일 배수 위치)
soft_paste(out,crop(40,420,400,830),(40,420+384),sides='rtb')          # 카드 기둥·붉은 실·일지·촛불
soft_paste(out,crop(1000,420,1390,810),(1000+664,420+192),sides='ltb')  # 무너진 기둥·방패·촛불
soft_paste(out,crop(1010,630,1100,720),(700,900),feather=20)           # 돌 조각 하나 더(빈 바닥 메우기)
# 3) 옆벽: 세로로 반복
def vfill(x0,x1,dstx,y0,y1):
    seg=crop(x0,380,x1,800); h=seg.height; y=y0
    while y<y1:
        part=seg.crop((0,0,seg.width,min(h,y1-y))); out.paste(part,(dstx,y)); y+=h
vfill(0,60,0,369,BS+DY)
vfill(1390,W,1390+DX,369,BS+DY)
# 4) 위쪽 벽(출구 셋): 왼쪽·가운데·오른쪽 + 사이를 창문 벽으로 채움
TOP=369
def hfill(seg,x0,x1,y):
    x=x0
    while x<x1:
        part=seg.crop((0,0,min(seg.width,x1-x),seg.height)); out.paste(part,(x,y)); x+=seg.width
win=crop(932,0,1047,TOP)
out.paste(crop(0,0,515,TOP),(0,0))
hfill(win,515,515+332,0)
out.paste(crop(515,0,1045,TOP),(515+332,0))
hfill(win,1045+332,1045+DX,0)
out.paste(crop(1045,0,W,TOP),(1045+DX,0))
# 5) 아래쪽 벽(입구 아치)
BS=830
wall=crop(400,BS,540,H)
out.paste(crop(0,BS,540,H),(0,BS+DY))
hfill(wall,540,540+332,BS+DY)
out.paste(crop(540,790,910,H),(540+332,790+DY))
hfill(wall,910+332,910+DX,BS+DY)
out.paste(crop(910,BS,W,H),(910+DX,BS+DY))
out.save('/home/user/yemo_plan/art/raw/map_f1_fork_wide_raw.png')
print(out.size, round(W2/W,2), round(H2/H,2))
out.resize((W2//2,H2//2)).save('preview.png')
