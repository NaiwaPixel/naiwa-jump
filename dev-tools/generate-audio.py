"""Original synthesized effects and a quiet pentatonic pond loop. No third-party samples."""
from pathlib import Path
import math, random, struct, wave
ROOT=Path(__file__).resolve().parents[1]/'assets'/'audio'
RATE=22050
def write(name, data):
    with wave.open(str(ROOT/(name+'.wav')), 'wb') as f:
        f.setparams((1,2,RATE,0,'NONE','not compressed'))
        f.writeframes(b''.join(struct.pack('<h',round(max(-1,min(1,x))*28000)) for x in data))
def chirp(name,duration,base,slope):
    samples=[]
    for i in range(round(duration*RATE)):
        t=i/RATE; a=math.sin(math.pi*t/duration)**1.4
        phase=2*math.pi*(base*t+slope*t*t/2)
        samples.append(a*(math.sin(phase)*.29+math.sin(phase*2)*.06))
    write(name,samples)
chirp('jump',.22,300,1700)
chirp('land',.13,230,-600)
duration=.52
write('perfect',[(math.sin(2*math.pi*660*i/RATE)+math.sin(2*math.pi*880*i/RATE)*.6+math.sin(2*math.pi*1100*i/RATE)*.3)*.18*math.exp(-i/RATE*7)*min(1,i/200) for i in range(round(duration*RATE))])
rng=random.Random(79)
write('splash',[(rng.uniform(-1,1)*.16+math.sin(2*math.pi*(160*i/RATE-150*(i/RATE)**2))*.15)*math.sin(math.pi*i/(.4*RATE))**2 for i in range(round(.4*RATE))])
duration=12
data=[0.0]*round(RATE*duration)
notes=[(0,392),(.75,523.25),(1.5,587.33),(3,659.25),(3.75,587.33),(4.5,523.25),(6,440),(6.75,523.25),(7.5,392),(9,329.63),(9.75,392)]
for at,hz in notes:
    for j in range(round(RATE*1.8)):
        i=round(at*RATE)+j
        if i>=len(data):break
        t=j/RATE; env=min(1,t/.025)*math.exp(-t*3.5)
        data[i]+=(math.sin(2*math.pi*hz*t)+.17*math.sin(2*math.pi*hz*2*t))*env*.21
for i in range(len(data)-RATE,len(data)):data[i]*=(len(data)-i)/RATE
write('pond',data)
chirp('claw',.18,210,-410)
chirp('open',.32,320,450)
write('suspense',[(math.sin(2*math.pi*(220*i/RATE+70*(i/RATE)**2))*.18+math.sin(2*math.pi*330*i/RATE)*.06)*math.sin(math.pi*i/RATE)**2 for i in range(RATE)])
chirp('rise',.9,180,470)
write('boxland',[(math.sin(2*math.pi*95*i/RATE)*.25+rng.uniform(-1,1)*.045)*math.exp(-i/RATE*23) for i in range(round(RATE*.22))])
# Dry paper tear, deliberately different from the musical reveal.
write('peel',[(rng.uniform(-1,1)*.15*(.6+.4*math.sin(i/RATE*83)))*math.sin(math.pi*i/(.72*RATE))**1.5 for i in range(round(RATE*.72))])
data=[0.0]*round(RATE*1.2)
for at,hz in [(0,523.25),(.08,659.25),(.16,783.99),(.24,1046.5)]:
    for j in range(round(RATE*.85)):
        i=round(at*RATE)+j
        if i>=len(data):break
        t=j/RATE
        data[i]+=(math.sin(2*math.pi*hz*t)+.15*math.sin(2*math.pi*hz*2*t))*min(1,t/.012)*math.exp(-t*5)*.22
write('reveal',data)
print('Created twelve original WAV assets.')
