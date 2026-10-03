function parse(text) {
    var match = /^(\d{2})\/(\d{2})\/(\d{4})$/.exec(text);
    if (!match) return null;
    var day = Number(match[1]), month = Number(match[2]), year = Number(match[3]);
    if (year < 1000) return null;
    var date = new Date(year, month - 1, day, 12);
    return date.getFullYear() === year && date.getMonth() === month - 1 && date.getDate() === day ? date : null;
}
function format(date) {
    return ('0' + date.getDate()).slice(-2) + '/' + ('0' + (date.getMonth() + 1)).slice(-2) + '/' + date.getFullYear();
}
function normalize(text) {
    var digits = text.replace(/\D/g, '');
    return digits.length === 8 ? digits.slice(0,2) + '/' + digits.slice(2,4) + '/' + digits.slice(4) : text;
}
function cell(year, month, index) {
    var first = new Date(year, month, 1, 12);
    return new Date(year, month, 1 - first.getDay() + index, 12);
}

// Keep calculation and subtotal boundaries in place. Equal keys retain input order.
function sortRows(rows, direction) {
    var result = [], pending = [];
    function flush() {
        pending.sort(function(a, b) {
            if (a.key === null && b.key !== null) return -1;
            if (a.key !== null && b.key === null) return 1;
            return (a.key !== null && b.key !== null ? (a.key - b.key) * direction : 0) || a.index - b.index;
        });
        pending.forEach(function(entry) { result.push(entry.row); });
        pending = [];
    }
    rows.forEach(function(row, index) {
        if (row.op === "novo" || row.op === "=") {
            flush(); result.push(row);
        } else {
            var date = parse(normalize(String(row.dateText || "")));
            pending.push({row: row, index: index, key: date ? date.getTime() : null});
        }
    });
    flush();
    return result;
}
