const {readFileSync} = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const engine = vm.createContext({});
vm.runInContext(readFileSync(__dirname + '/../Engine.js', 'utf8'), engine);
const calc = rows => engine.calculate(rows.map(([op,value='']) => ({op,value})));
assert.equal(calc([['+','1.442'],['+','19.000']]).total, '20.442,00');
assert.equal(calc([['+','50.000'],['−','21.000']]).total, '29.000,00');
assert.equal(calc([['+','54.520'],['−','29.000']]).total, '25.520,00');
assert.equal(calc([['+','31.895,83'],['−','14.000']]).total, '17.895,83');
assert.equal(calc([['+','650'],['+','250']]).total, '900,00');
assert.equal(calc([['+','170'],['×','3']]).total, '510,00');
assert.equal(calc([['+','0,1'],['+','0,2']]).total, '0,30');
assert.equal(calc([['+','19000'],['×','3']]).total, '57.000,00');
assert.equal(calc([['+','31895,83'],['÷','3']]).total, '10.631,943333');
assert.equal(calc([['+','-1'],['÷','6']]).total, '-0,166667');
assert.equal(calc([['+','10'],['='],['+','5']]).total, '15,00');
assert.equal(calc([['+','10'],['novo'],['+','5']]).total, '5,00');
assert.ok(calc([['+','1'],['÷','0']]).error);
assert.ok(calc([['+','1.23']]).error);
assert.ok(calc([['+','9007199254,740992']]).error);
assert.equal(calc([['+','9007199254,740991'],['×','1']]).total, '9.007.199.254,740991');
// Compare multiplication/division against exact BigInt reference, including rounding.
let seed = 42;
function random() { seed = (1664525 * seed + 1013904223) >>> 0; return seed; }
for (let i=0; i<500; i++) {
    const a = BigInt(random()) * 1000n, b = BigInt(random() % 10000000 + 1);
    for (const [op,n,d] of [['×',a*b,1000000n],['÷',a*1000000n,b]]) {
        const exact = n/d + ((n%d)*2n >= d ? 1n : 0n);
        if (exact > 9007199254740991n) continue;
        assert.equal(calc([['+',engine.format(Number(a))],[op,engine.format(Number(b))]]).total, engine.format(Number(exact)));
    }
}
console.log('All arithmetic checks passed, including 1,000 randomized comparisons.');
