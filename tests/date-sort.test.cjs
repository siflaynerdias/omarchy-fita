const {readFileSync} = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const dates = vm.createContext({});
vm.runInContext(readFileSync(__dirname + '/../DateUtils.js', 'utf8'), dates);
const row = (note, dateText, op = '+') => ({note, dateText, op, value: '1'});
const rows = [row('later', '01/01/2027'), row('empty', ''), row('early', '31/12/2026'),
    row('equal', '31122026'), row('invalid', '31/02/2026'), row('subtotal', '', '='),
    row('after subtotal', '01/01/2020'), row('new', '', 'novo'),
    row('second later', '02/10/2026'), row('second empty'), row('second early', '01/10/2026')];
const original = JSON.stringify(rows);
const names = direction => Array.from(dates.sortRows(rows, direction), r => r.note);
assert.deepEqual(names(1), ['empty', 'invalid', 'early', 'equal', 'later', 'subtotal', 'after subtotal', 'new', 'second empty', 'second early', 'second later']);
assert.deepEqual(names(-1), ['empty', 'invalid', 'later', 'early', 'equal', 'subtotal', 'after subtotal', 'new', 'second empty', 'second later', 'second early']);
assert.equal(JSON.stringify(rows), original);
assert.equal(dates.sortRows([], 1).length, 0);
assert.deepEqual(Array.from(dates.sortRows([row('new', '', 'novo'), row('sum', '', '=')], 1), r => r.note), ['new', 'sum']);
console.log('Date sorting checks passed.');
