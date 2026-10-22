cd run
yosys -s ../scripts/synth_gatemate.ys
himbaechel --device CCGM1A1 --json net.json -o ccf=../scripts/pins.ccf -o out=impl1.txt --router router2
