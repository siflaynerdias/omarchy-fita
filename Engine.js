// Fixed-point arithmetic: six decimal places; reject unsafe intermediates.
var SCALE = 1000000;
var LIMIT = 9007199254740991;
function trim(s) { return s.replace(/^0+(?=\d)/, ""); }
function compare(a, b) { return a.length !== b.length ? a.length - b.length : a === b ? 0 : a > b ? 1 : -1; }
function subtract(a, b) {
    var out = "", borrow = 0;
    for (var i = a.length - 1, j = b.length - 1; i >= 0; i--, j--) {
        var digit = Number(a[i]) - (j >= 0 ? Number(b[j]) : 0) - borrow;
        borrow = digit < 0 ? 1 : 0; out = String((digit + 10) % 10) + out;
    }
    return trim(out);
}
function product(a, b) {
    var out = new Array(a.length + b.length).fill(0);
    for (var i = a.length - 1; i >= 0; i--)
        for (var j = b.length - 1; j >= 0; j--) out[i + j + 1] += Number(a[i]) * Number(b[j]);
    for (var k = out.length - 1; k > 0; k--) { out[k - 1] += Math.floor(out[k] / 10); out[k] %= 10; }
    return trim(out.join(""));
}
function roundedRatio(numerator, denominator) {
    var quotient = "", remainder = "0";
    for (var i = 0; i < numerator.length; i++) {
        remainder = trim(remainder + numerator[i]); var digit = 0;
        while (compare(remainder, denominator) >= 0) { remainder = subtract(remainder, denominator); digit++; }
        quotient += String(digit);
    }
    quotient = trim(quotient);
    if (compare(quotient, String(LIMIT)) > 0) throw new Error("Valor excede a precisão suportada");
    return safe(Number(quotient) + (compare(product(remainder, "2"), denominator) >= 0 ? 1 : 0));
}
function safe(n) {
    if (!isFinite(n) || Math.abs(n) > LIMIT) throw new Error("Valor excede a precisão suportada");
    return n;
}
function parse(text) {
    var s = String(text).trim();
    if (!/^[+-]?(?:\d+|\d{1,3}(?:\.\d{3})+)(?:,\d{1,6})?$/.test(s))
        throw new Error("Use 1.234,56 (até 6 casas decimais)");
    var sign = s[0] === "-" ? -1 : 1;
    s = s.replace(/^[+-]/, "").replace(/\./g, "");
    var parts = s.split(",");
    return safe(sign * (safe(Number(parts[0]) * SCALE) + Number(((parts[1] || "") + "000000").slice(0, 6))));
}
function format(n) {
    var digits = String(Math.abs(n));
    while (digits.length < 7) digits = "0" + digits;
    var whole = digits.slice(0, -6).replace(/\B(?=(\d{3})+(?!\d))/g, ".");
    var fraction = digits.slice(-6).replace(/0+$/, "");
    while (fraction.length < 2) fraction += "0";
    return (n < 0 ? "-" : "") + whole + "," + fraction;
}
function calculate(rows) {
    var total = 0, error = "", results = [];
    for (var i = 0; i < rows.length; i++) {
        var r = rows[i];
        if (r.op === "novo") { total = 0; error = ""; results.push({text: "", error: ""}); continue; }
        if (r.op === "=") { results.push({text: error ? "—" : format(total), error: error}); continue; }
        if (String(r.value).trim() === "") { results.push({text: "", error: ""}); continue; }
        try {
            if (error) throw new Error("Corrija a linha anterior");
            var value = parse(r.value);
            if (r.op === "+") total = safe(total + value);
            else if (r.op === "−") total = safe(total - value);
            else if (r.op === "×") total = Math.sign(total) * Math.sign(value) * roundedRatio(product(String(Math.abs(total)), String(Math.abs(value))), String(SCALE));
            else if (r.op === "÷") {
                if (value === 0) throw new Error("Divisão por zero");
                total = Math.sign(total) * Math.sign(value) * roundedRatio(String(Math.abs(total)) + "000000", String(Math.abs(value)));
            } else throw new Error("Operação inválida");
            results.push({text: format(total), error: ""});
        } catch (e) { error = e.message; results.push({text: "", error: error}); }
    }
    return {rows: results, total: error ? "—" : format(total), error: error};
}
