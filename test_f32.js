// Replicate Lua _f32 exactly and test
function f32(x) {
    let s = x;
    if (typeof x !== 'number') x = 0;
    let sign = 0;
    if (x < 0) { sign = 1; x = -x; }
    if (x === 0) return Buffer.from([0, 0, 0, 0]);
    if (x !== x) return Buffer.from([0, 0, 0xC0, 0x7F]); // NaN
    if (x === 1/0) return Buffer.from([0, 0, 0x80, 0x7F]); // +Inf
    if (x === -1/0) return Buffer.from([0, 0, 0x80, 0xFF]); // -Inf

    let exp = 0;
    while (x >= 2) { x = x / 2; exp = exp + 1; }
    while (x < 1) { x = x * 2; exp = exp + 1; }
    x = x - 1;
    let bits = 0;
    for (let i = 1; i <= 23; i++) {
        x = x * 2;
        if (x >= 1) { bits = bits | (1 << (23 - i)); x = x - 1; }
    }
    if (x >= 0.5) {
        bits = bits + 1;
        if (bits >= 0x800000) { bits = 0; exp = exp + 1; }
    }
    const biased_exp = (127 + exp) & 0xFF;
    const m23 = bits & 0x7FFFFF;
    const u = (sign << 31) | (biased_exp << 23) | m23;
    const buf = Buffer.alloc(4);
    buf.writeUInt32LE(u >>> 0, 0);
    return buf;
}

const tests = [-493.0, -808.0, 108.6, 0.0, 1.0, -1.0, 1.5, -1.5, 100.0, -100.0];
for (const v of tests) {
    const bytes = f32(v);
    const actual = bytes.readFloatLE(0);
    console.log(`f32(${v}) = ${bytes.toString('hex')} (readback: ${actual})`);
}

// Cross-check with native Buffer.writeFloatLE
console.log('\nNative IEEE 754 LE for reference:');
for (const v of tests) {
    const buf = Buffer.alloc(4);
    buf.writeFloatLE(v, 0);
    console.log(`writeFloatLE(${v}) = ${buf.toString('hex')}`);
}