export class SeededRNG {
  constructor(seed) {
    this.state = seed ? BigInt(seed) : 0xdeadbeefn;
  }

  next() {
    let s = this.state;
    s ^= s >> 12n;
    s ^= s << 25n;
    s ^= s >> 27n;
    this.state = (s * 0x2545f4914f6cdd1dn) & ((1n << 64n) - 1n);
    return this.state;
  }

  nextDouble() {
    return Number(this.next() >> 11n) / (1 << 53);
  }

  nextDoubleRange(min, max) {
    return min + this.nextDouble() * (max - min);
  }

  nextInt(min, max) {
    const span = max - min + 1;
    return min + Number(this.next() % BigInt(span));
  }

  pick(arr) {
    if (!arr?.length) return null;
    return arr[this.nextInt(0, arr.length - 1)];
  }
}

export function uuid() {
  return crypto.randomUUID();
}
